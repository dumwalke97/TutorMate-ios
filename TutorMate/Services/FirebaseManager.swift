import AuthenticationServices
import CryptoKit
import FirebaseAuth
internal import Combine
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn
import UIKit

class FirebaseManager: ObservableObject {
    
    
    static let shared = FirebaseManager()
    
    @Published var currentUser: User?
    @Published var folders: [Folder] = []
    /// True when the signed-in user has an active subscription that this
    /// device's StoreKit can't see: purchased on the website via Stripe
    /// (`subscriptionStatus`, written by the Stripe webhook with admin
    /// credentials) or on another Apple Account (`appleSubscriptionStatus`,
    /// written by the iOS app). Both platforms share logins, so honoring
    /// these here means nobody pays twice.
    @Published var hasRemoteSubscription = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var userDocListener: ListenerRegistration?

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.watchUserDocument(userId: user?.uid)
            if let userId = user?.uid {
                Task {
                    await self?.loadFolders(userId: userId)
                }
            }
        }
    }

    /// Last `appleSubscriptionStatus` seen in users/{uid}. Lets
    /// `updateAppleSubscriptionStatus` skip redundant writes and avoid
    /// creating docs for users who never subscribed.
    private var appleStatusInDoc: String?

    private func watchUserDocument(userId: String?) {
        userDocListener?.remove()
        userDocListener = nil
        hasRemoteSubscription = false
        appleStatusInDoc = nil
        guard let userId else { return }
        userDocListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                let data = snapshot?.data()
                let status = data?["subscriptionStatus"] as? String
                let appleStatus = data?["appleSubscriptionStatus"] as? String
                self.hasRemoteSubscription = (status == "active" || appleStatus == "active")

                let changed = appleStatus != self.appleStatusInDoc
                self.appleStatusInDoc = appleStatus
                // Doc and this device disagree about the Apple subscription
                // (login on a new device, or a lapse recorded elsewhere):
                // re-verify entitlements, which rewrites the field from
                // fresh StoreKit truth via updateAppleSubscriptionStatus.
                if changed, (appleStatus == "active") != StoreManager.shared.isSubscribed {
                    Task { await StoreManager.shared.refreshSubscriptionStatus() }
                }
            }
    }

    /// Mirrors the on-device StoreKit entitlement to users/{uid} so the web
    /// app honors an Apple subscription under the same login. Writes only
    /// `appleSubscriptionStatus` — never `subscriptionStatus`, which belongs
    /// to the Stripe webhook — so the two purchase paths can't clobber each
    /// other. `canDowngrade` is true only when this Apple Account actually
    /// held the subscription at some point, so a second device signed into
    /// the same TutorMate account (but a different Apple Account) can never
    /// wipe a live subscription.
    func updateAppleSubscriptionStatus(isActive: Bool, canDowngrade: Bool) async {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else { return }
        let desired: String
        if isActive {
            desired = "active"
        } else if canDowngrade && appleStatusInDoc == "active" {
            desired = "expired"
        } else {
            return
        }
        guard desired != appleStatusInDoc else { return }
        _ = try? await db.collection("users").document(user.uid)
            .setData(["appleSubscriptionStatus": desired], merge: true)
    }

    /// One-shot fetch used where a decision can't wait for the listener
    /// (e.g. right after login on the paywall, before charging via Apple).
    func refreshRemoteSubscription() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        let snapshot = try? await db.collection("users").document(userId).getDocument()
        let data = snapshot?.data()
        let active = (data?["subscriptionStatus"] as? String) == "active"
            || (data?["appleSubscriptionStatus"] as? String) == "active"
        await MainActor.run { hasRemoteSubscription = active }
        return active
    }
    
    func signInAnonymously() async throws {
        try await Auth.auth().signInAnonymously()
    }

    /// Every session gets a Firebase user (anonymous if the person hasn't
    /// signed up) so backend requests always carry a verifiable ID token.
    func ensureSignedIn() async {
        if Auth.auth().currentUser == nil {
            try? await Auth.auth().signInAnonymously()
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    /// Creates an account and sends a verification email. Firebase rejects
    /// duplicate emails automatically with `AuthErrorCode.emailAlreadyInUse`.
    func signUpWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        try await result.user.sendEmailVerification()
    }

    /// Re-sends the verification email to the currently signed-in user.
    func resendVerificationEmail() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }

    var isEmailVerified: Bool {
        guard let user = Auth.auth().currentUser else { return false }
        // Google accounts are pre-verified; email/password accounts need to confirm.
        return user.isEmailVerified || user.providerData.contains { $0.providerID != "password" }
    }

    /// True when the signed-in user has an email/password credential (so they
    /// can change email / reset password). Google-only users cannot.
    var isPasswordUser: Bool {
        Auth.auth().currentUser?.providerData.contains { $0.providerID == "password" } ?? false
    }

    /// Sends a password reset link to the given email (used from the login screen).
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    /// Starts an email change for the signed-in user. Firebase sends a
    /// confirmation link to the NEW address; the email only updates once the
    /// user clicks it.
    func updateEmail(to newEmail: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
    }

    /// Maps Firebase auth errors to friendly, user-facing messages.
    static func friendlyAuthError(_ error: Error) -> String {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .emailAlreadyInUse:
            return "An account with this email already exists. Try logging in instead."
        case .invalidEmail:
            return "That doesn't look like a valid email address."
        case .weakPassword:
            return "Please choose a password with at least 6 characters."
        case .wrongPassword, .invalidCredential:
            return "Incorrect email or password. Please try again."
        case .userNotFound:
            return "No account found with that email. Try signing up."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .requiresRecentLogin:
            return "For security, please sign out and sign back in, then try again."
        default:
            return error.localizedDescription
        }
    }
    
    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
        // Fall back to an anonymous session so API calls keep working.
        Task { await ensureSignedIn() }
    }

    @MainActor
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(
                domain: "TutorMate",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID."]
            )
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presenter = Self.topViewController() else {
            throw NSError(
                domain: "TutorMate",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Unable to present Google Sign-In."]
            )
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(
                domain: "TutorMate",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Google Sign-In did not return an ID token."]
            )
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Grandfathered Accounts

    /// Firebase UIDs with lifetime premium access, mirroring the accounts
    /// grandfathered on the web app. UIDs are opaque identifiers, so no
    /// personal information ships in the binary. Adding accounts requires
    /// an app update; move this to a client-read-only Firestore collection
    /// if the list ever needs to grow dynamically.
    private static let grandfatheredUIDs: Set<String> = [
        "I43M0gg1KdP78yrRFYnd1rwGcZf2",
        "JjAYvBDhVESEvdZwSmIFuQ64jww2",
        "knSCADcrl8SGCWBLB7OLAGfyyO32",
        "oaQ8et7ELHgpiPayiP3y41OsePr1",
        "4Rw9LRuV6NPriwoUMUB852IhmT03",
        "RGHeg0WvApSyRwtZsp1UkDNuUTz1",
        "2ExBlXLnl2VP0IFY5G4IXZGMACy1",
        "B5N6c9j5C1RK62iTdjSdc5eU8xz2",
        "S6Lf3Duy8rf5HRgVcGnTEG3L2fk1",
        "XMdyskpAa6aFiwnmi98IN4ilq243",
        "LsNDAOm4vdcqsooqzb8BT4US0uz1",
        "uvniRVDIlfRjTEguEP89Uu1osIH2",
        "06Xn8LkbQVYAJuyjQocrrE1ibD03",
        "OEOnj7oDbXdeDGGQaMtjrcePrR73",
        "dhdE51cqlhWIZXfvwIfpbDJRCJE3",
        "q5L6JUFOqWSKSmazkP0I928BNkk1",
        "FLFGMwQ1t5ZhP8nZnJGf8vylyG42",
        "z1AwAdMQLYXC6jryQEg9NHaV8Qv2",
        "CScvhIplvbOY1x1wvY5kL296V3C2",
        "W5w8Zas5Z3WVDumlkXAhp6beHJZ2",
        "nUDE3qid4IXh6mcl2uIl7cOCfsi2",
        "pEUkmcvLund8RhCTvRzSrlTdAxn2"
    ]

    /// True when the signed-in (non-anonymous) user has lifetime access.
    var isGrandfathered: Bool {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else { return false }
        return Self.grandfatheredUIDs.contains(user.uid)
    }

    // MARK: - Sign in with Apple

    /// Requires the Sign in with Apple capability, which personal (free)
    /// development teams can't use. Flip to true after enrolling in the
    /// Apple Developer Program, adding the capability to the TutorMate
    /// target, and enabling the Apple provider in Firebase Authentication.
    static let appleSignInEnabled = false

    /// Raw nonce for the in-flight Apple sign-in request; Firebase compares
    /// it against the hashed nonce inside Apple's identity token to block
    /// replayed credentials.
    private var currentAppleNonce: String?

    /// Configures an Apple ID request with the scopes and hashed nonce.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Completes Firebase sign-in from a successful Apple authorization.
    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentAppleNonce else {
            throw NSError(
                domain: "TutorMate",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Apple Sign-In did not return valid credentials."]
            )
        }
        currentAppleNonce = nil

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        try await Auth.auth().signIn(with: credential)
    }

    private static func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "Unable to generate a secure nonce.")
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    // MARK: - Account Deletion

    /// Permanently deletes the signed-in user's data and account, in this
    /// order: folder items -> folders -> user document -> uploaded images ->
    /// Auth user. The Auth user goes last because the security rules need a
    /// signed-in user to authorize the data deletions. Throws
    /// `requiresRecentLogin` if the session is too old to delete the account.
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid

        let userDoc = db.collection("users").document(userId)
        let folderDocs = try await userDoc.collection("folders").getDocuments()
        for folderDoc in folderDocs.documents {
            let itemDocs = try await folderDoc.reference.collection("items").getDocuments()
            for itemDoc in itemDocs.documents {
                try await itemDoc.reference.delete()
            }
            try await folderDoc.reference.delete()
        }
        try await userDoc.delete()

        let uploadsRef = storage.reference().child("users/\(userId)/uploads")
        if let listing = try? await uploadsRef.listAll() {
            for item in listing.items {
                try? await item.delete()
            }
        }

        try await user.delete()

        GIDSignIn.sharedInstance.signOut()
        folders = []
        await ensureSignedIn()
    }

    @MainActor
    static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    func loadFolders(userId: String) async {
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("folders")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            folders = snapshot.documents.compactMap { doc in
                guard let name = doc.data()["name"] as? String,
                      let timestamp = doc.data()["createdAt"] as? Timestamp else {
                    return nil
                }
                return Folder(id: doc.documentID, name: name, createdAt: timestamp.dateValue())
            }
        } catch {
            print("Error loading folders: \(error)")
        }
    }
    
    func createFolder(userId: String, name: String) async throws {
        let _ = try await db.collection("users")
            .document(userId)
            .collection("folders")
            .addDocument(data: [
                "name": name,
                "createdAt": FieldValue.serverTimestamp()
            ])
        
        await loadFolders(userId: userId)
    }
    
    func getFolderItems(userId: String, folderId: String) async throws -> [FolderItem] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("folders")
            .document(folderId)
            .collection("items")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            guard let mimeType = doc.data()["mimeType"] as? String,
                  let url = doc.data()["url"] as? String,
                  let timestamp = doc.data()["createdAt"] as? Timestamp else {
                return nil
            }
            return FolderItem(
                id: doc.documentID,
                mimeType: mimeType,
                url: url,
                createdAt: timestamp.dateValue()
            )
        }
    }
    
    func uploadImage(userId: String, folderId: String, imageData: Data, mimeType: String) async throws {
        let imageId = UUID().uuidString
        let storagePath = "users/\(userId)/uploads/\(imageId).jpg"
        let storageRef = storage.reference().child(storagePath)
        
        let _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        
        try await db.collection("users")
            .document(userId)
            .collection("folders")
            .document(folderId)
            .collection("items")
            .addDocument(data: [
                "mimeType": mimeType,
                "url": downloadURL.absoluteString,
                "createdAt": FieldValue.serverTimestamp()
            ])
    }
    
    func deleteItem(userId: String, folderId: String, itemId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("folders")
            .document(folderId)
            .collection("items")
            .document(itemId)
            .delete()
    }
}
