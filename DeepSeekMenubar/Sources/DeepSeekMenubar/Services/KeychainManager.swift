import Foundation
import Security

enum KeychainManager {
    static let service = "com.deepseek.menubar"

    static let apiKeyAccount = "api-key"
    static let platformTokenAccount = "platform-token"

    static func save(key: String, account: String = apiKeyAccount) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    static func load(account: String = apiKeyAccount) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        return key
    }

    static func delete(account: String = apiKeyAccount) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: LocalizedError {
    case invalidData
    case saveFailed(status: OSStatus)
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidData: return "Failed to encode data"
        case .saveFailed(let status): return "Keychain save failed (OSStatus: \(status))"
        case .notFound: return "No item found in Keychain"
        }
    }
}
