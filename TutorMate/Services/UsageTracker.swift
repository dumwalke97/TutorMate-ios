import Foundation
import Security
internal import Combine

/// Tracks lifetime free generations (quizzes + assignment checks).
/// The count is stored in the Keychain so it survives app deletion
/// and reinstall, unlike UserDefaults.
final class UsageTracker: ObservableObject {

    static let shared = UsageTracker()
    static let freeUseLimit = 10

    @Published private(set) var usedCount: Int

    private static let service = "com.tutormate.usage"
    private static let account = "freeGenerationCount"

    private init() {
        usedCount = Self.readCount()
    }

    var remainingFreeUses: Int {
        max(0, Self.freeUseLimit - usedCount)
    }

    var hasFreeUsesRemaining: Bool {
        usedCount < Self.freeUseLimit
    }

    func recordUse() {
        usedCount += 1
        Self.writeCount(usedCount)
    }

    // MARK: - Keychain

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func readCount() -> Int {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8),
              let value = Int(string) else {
            return 0
        }
        return value
    }

    private static func writeCount(_ count: Int) {
        let data = Data(String(count).utf8)
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            // Device-only so the count is not restored onto other devices
            // from an iCloud/encrypted backup.
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
}
