import Foundation
import FirebaseAuth

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://tutormate.ai/.netlify/functions"

    /// Builds a POST request carrying the caller's Firebase ID token so the
    /// backend can reject requests that don't come from a signed-in app user.
    private func authorizedRequest(url: URL, payload: [String: Any]) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if Auth.auth().currentUser == nil {
            try? await Auth.auth().signInAnonymously()
        }
        if let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        return request
    }

    func generateQuiz(payload: [String: Any]) async throws -> QuizResponse {
        guard let url = URL(string: "\(baseURL)/generate") else {
            throw NetworkError.invalidURL
        }

        let request = try await authorizedRequest(url: url, payload: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.badResponse
        }
        
        // Parse Gemini API response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw NetworkError.emptyResponse
        }
        
        // Extract JSON from markdown if needed
        let jsonString = extractJSON(from: content)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NetworkError.invalidJSON
        }
        
        return try JSONDecoder().decode(QuizResponse.self, from: jsonData)
    }
    
    func checkAssignment(payload: [String: Any]) async throws -> String {
        guard let url = URL(string: "\(baseURL)/generate") else {
            throw NetworkError.invalidURL
        }

        let request = try await authorizedRequest(url: url, payload: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.badResponse
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw NetworkError.emptyResponse
        }
        
        return content
    }
    
    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks
        if let range = text.range(of: "```json\\s*([\\s\\S]*?)\\s*```", options: .regularExpression) {
            let jsonText = text[range]
            return String(jsonText).replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to find JSON object
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        
        return text
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

enum NetworkError: Error {
    case invalidURL
    case badResponse
    case emptyResponse
    case invalidJSON
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .badResponse: return "Server error occurred"
        case .emptyResponse: return "Empty response from server"
        case .invalidJSON: return "Could not parse response"
        }
    }
}
