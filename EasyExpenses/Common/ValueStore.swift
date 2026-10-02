import Foundation

/// A lightweight key-value storage abstraction.
protocol ValueStore: Sendable {
    // MARK: - String
    func setString(_ value: String?, forKey key: String)
    func getString(forKey key: String, default defaultValue: String?) -> String?

    // MARK: - Bool
    func setBool(_ value: Bool, forKey key: String)
    func getBool(forKey key: String, default defaultValue: Bool) -> Bool

    // MARK: - Array of Codable
    func setArray<T: Codable>(_ value: [T]?, forKey key: String)
    func getArray<T: Codable>(forKey key: String, default defaultValue: [T]) -> [T]
}

/// Default implementation of ValueStore backed by UserDefaults.
// User Defaults is Thread Safe, so we can use @unchecked Sendable
struct DefaultValueStore: ValueStore,  @unchecked Sendable {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Initialize with a specific UserDefaults suite or .standard by default.
     init(suiteName: String? = nil) {
        if let suiteName, let ud = UserDefaults(suiteName: suiteName) {
            self.defaults = ud
        } else {
            self.defaults = .standard
        }
    }

    // MARK: - String
     func setString(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

     func getString(forKey key: String, default defaultValue: String?) -> String? {
        if let v = defaults.string(forKey: key) {
            return v
        }
        return defaultValue
    }

    // MARK: - Bool
     func setBool(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

     func getBool(forKey key: String, default defaultValue: Bool) -> Bool {
        if defaults.object(forKey: key) == nil {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }

    // MARK: - Array of Codable
     func setArray<T: Codable>(_ value: [T]?, forKey key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            // If encoding fails, do not store partial data.
            #if DEBUG
            print("DefaultValueStore.setArray encoding error for key \(key): \(error)")
            #endif
        }
    }

     func getArray<T: Codable>(forKey key: String, default defaultValue: [T]) -> [T] {
        guard let data = defaults.data(forKey: key) else {
            return defaultValue
        }
        do {
            let decoded = try decoder.decode([T].self, from: data)
            return decoded
        } catch {
            #if DEBUG
            print("DefaultValueStore.getArray decoding error for key \(key): \(error)")
            #endif
            return defaultValue
        }
    }
}
