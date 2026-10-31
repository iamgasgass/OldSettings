import SwiftUI
import UIKit
import Combine

@main
final class OldSettingsAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        _ = AppearanceSettings.shared
        _ = SettingsKeyboard.shared
        // Start watching Wi-Fi, volume and brightness.
        _ = WiFiStatus.shared
        _ = VolumeObserver.shared
        _ = BrightnessObserver.shared
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = OldSettingsSceneDelegate.self
        return configuration
    }

    /// The iOS 6 Settings app is portrait only.
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

final class OldSettingsSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = OldSettingsHostingController(root: OldSettingsRootView())
        window.backgroundColor = .black
        self.window = window
        window.makeKeyAndVisible()
        AppearanceSettings.shared.apply()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        AppearanceSettings.shared.apply()
    }
}

/// Hosts the SwiftUI app and applies the status bar style requested by the
/// visible chrome (dark text on the light bar, light text on the graphite bars).
final class OldSettingsHostingController: UIHostingController<OldSettingsRootView> {
    private var cancellables = Set<AnyCancellable>()

    init(root: OldSettingsRootView) {
        super.init(rootView: root)
        SettingsStatusBar.shared.$style
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.setNeedsStatusBarAppearanceUpdate()
                }
            }
            .store(in: &cancellables)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        SettingsStatusBar.shared.style
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
