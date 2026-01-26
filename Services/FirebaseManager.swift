import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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
    
    func signUpWithEmail(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
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
