import Foundation
import FirebaseFirestore

struct QuizQuestion: Codable, Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let answer: String
    
    enum CodingKeys: String, CodingKey {
        case question, options, answer
    }
}

struct QuizResponse: Codable {
    let questions: [QuizQuestion]
}

struct UserAnswer {
    let questionIndex: Int
    let answer: String
}

struct Folder: Identifiable {
    let id: String
    let name: String
    let createdAt: Date
}

struct FolderItem: Identifiable {
    let id: String
    let mimeType: String
    let url: String
    let createdAt: Date
}

struct ImageData {
    let id: String
    let thumbnailImage: UIImage
    let apiData: APIImageData
}

struct APIImageData {
    let mimeType: String
    let data: String?
    let text: String?
}

enum AppState {
    case upload
    case loading
    case quiz
    case results
    case review
    case folders
    case folderContents
    case assignmentResults
}
