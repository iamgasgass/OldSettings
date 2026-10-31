import SwiftUI
import UIKit
import Combine

/// "Aspect UI" (Settings › OldSettings, from `Settings.bundle`).
enum SettingsAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Chiaro"
        case .dark: return "Scuro"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Preferences shown in the iOS Settings app (Settings › OldSettings): Aspect UI.
final class AppearanceSettings: ObservableObject {
    static let shared = AppearanceSettings()

    enum Key {
        static let appearance = "OldSettings.Appearance"
    }

    @Published private(set) var appearance: SettingsAppearance = .system

    private var observer: NSObjectProtocol?

    private init() {
        UserDefaults.standard.register(defaults: [
            Key.appearance: SettingsAppearance.system.rawValue
        ])
        read()
        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.read()
            self?.apply()
        }
    }

    private func read() {
        let defaults = UserDefaults.standard
        let newAppearance = SettingsAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
        if newAppearance != appearance { appearance = newAppearance }
    }

    func setAppearance(_ value: SettingsAppearance) {
        UserDefaults.standard.set(value.rawValue, forKey: Key.appearance)
        read()
        apply()
    }

    /// Forces the chosen appearance on every window, so the SwiftUI colour
    /// scheme *and* the system chrome (keyboard, alerts, share sheet, status
    /// bar) switch together. "Sistema" hands control back to iOS.
    func apply() {
        let style = appearance.interfaceStyle
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        for window in windows where window.overrideUserInterfaceStyle != style {
            window.overrideUserInterfaceStyle = style
        }
    }
}

/// Status bar style requested by the visible chrome: dark text on the light
/// blue bar, light text on the graphite bar.
final class SettingsStatusBar: ObservableObject {
    static let shared = SettingsStatusBar()

    @Published var style: UIStatusBarStyle = .darkContent

    private init() {}

    func update(lightChrome: Bool) {
        let newStyle: UIStatusBarStyle = lightChrome ? .darkContent : .lightContent
        if newStyle != style { style = newStyle }
    }
}

/// Keyboard height (the app draws edge to edge and ignores the keyboard
/// safe area): text fields scroll above it.
final class SettingsKeyboard: ObservableObject {
    static let shared = SettingsKeyboard()

    @Published private(set) var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let center = NotificationCenter.default
        center.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: center.publisher(for: UIResponder.keyboardWillHideNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let self else { return }
                if note.name == UIResponder.keyboardWillHideNotification {
                    self.height = 0
                    return
                }
                let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
                let screen = OldOSScreen.keyWindow?.bounds.height ?? UIScreen.main.bounds.height
                self.height = max(0, screen - frame.minY)
            }
            .store(in: &cancellables)
    }
}
