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
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if let userId = user?.uid {
                Task {
                    await self?.loadFolders(userId: userId)
                }
            }
        }
    }
    
    func signInAnonymously() async throws {
        try await Auth.auth().signInAnonymously()
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
