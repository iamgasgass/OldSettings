import SwiftUI
import Combine

/// Every switch and choice of the Settings screens, saved. OldOS kept them
/// in `@State` and lost them when leaving the screen.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private static let boolsKey = "OldSettings.Bools"
    private static let stringsKey = "OldSettings.Strings"

    @Published private var bools: [String: Bool]
    @Published private var strings: [String: String]

    private init() {
        let defaults = UserDefaults.standard
        bools = (defaults.dictionary(forKey: Self.boolsKey) as? [String: Bool]) ?? [:]
        strings = (defaults.dictionary(forKey: Self.stringsKey) as? [String: String]) ?? [:]
    }

    func bool(_ key: String, default value: Bool) -> Bool {
        bools[key] ?? value
    }

    func setBool(_ key: String, _ value: Bool) {
        bools[key] = value
        UserDefaults.standard.set(bools, forKey: Self.boolsKey)
    }

    func string(_ key: String, default value: String) -> String {
        strings[key] ?? value
    }

    func setString(_ key: String, _ value: String) {
        strings[key] = value
        UserDefaults.standard.set(strings, forKey: Self.stringsKey)
    }

    func binding(_ key: String, default value: Bool) -> Binding<Bool> {
        Binding(
            get: { self.bool(key, default: value) },
            set: { self.setBool(key, $0) }
        )
    }

    /// A value generated once and kept (serial number, addresses…: OldOS
    /// drew new random ones on every redraw).
    func stable(_ key: String, make: () -> String) -> String {
        let defaults = UserDefaults.standard
        let fullKey = "OldSettings.Stable.\(key)"
        if let value = defaults.string(forKey: fullKey) { return value }
        let value = make()
        defaults.set(value, forKey: fullKey)
        return value
    }
}
