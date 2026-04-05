import Foundation

struct TokenStorage {
    private static let storageKey = "depositedTokens"
    
    static func save(_ tokens: [DepositedToken]) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    static func load() -> [DepositedToken] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let tokens = try? JSONDecoder().decode([DepositedToken].self, from: data) else {
            return []
        }
        return tokens
    }
    
    static func deposit(_ token: DepositedToken) {
        var tokens = load()
        tokens.append(token)
        save(tokens)
    }
}
