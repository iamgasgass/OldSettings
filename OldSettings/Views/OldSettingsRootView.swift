import SwiftUI

/// OldOS `Settings`: the blue title bar over the pinstriped screens that
/// slide left / right, and the full-screen wallpaper preview sliding up.
/// The bar extends behind the status bar / Dynamic Island, the screens
/// behind the home indicator, exactly like OldSafari. The skin follows
/// Settings › OldSettings › Aspect UI (Sistema / Chiaro / Scuro).
struct OldSettingsRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var navigator = SettingsNavigator()
    @StateObject private var safeArea = OldOSSafeArea()

    var body: some View {
        GeometryReader { geometry in
            let topInset = max(geometry.safeAreaInsets.top, safeArea.insets.top)
            let bottomInset = max(geometry.safeAreaInsets.bottom, safeArea.insets.bottom)

            ZStack {
                theme.groupedBackground

                VStack(spacing: 0) {
                    SettingsTitleBar(topInset: topInset)
                        .zIndex(2)

                    ZStack {
                        screen(navigator.current)
                            .padding(.bottom, 0)
                            .id(navigator.current)
                            .transition(slide)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }

                if let preview = navigator.wallpaperPreview {
                    WallpaperPreviewView(choice: preview, topInset: topInset, bottomInset: bottomInset)
                        .id(preview.id)
                        .transition(.move(edge: .bottom))
                        .zIndex(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear { safeArea.refresh() }
        }
        .ignoresSafeArea()
        .environment(\.oldSettingsTheme, theme)
        .environmentObject(navigator)
        .onAppear {
            AppearanceSettings.shared.apply()
            UIApplication.shared.isIdleTimerDisabled = SettingsStore.shared.string("General.AutoLock", default: "Never") == "Never"
            updateStatusBar()
        }
        .onChange(of: colorScheme) { _ in updateStatusBar() }
        .onChange(of: navigator.wallpaperPreview) { _ in updateStatusBar() }
    }

    private var theme: OldSettingsTheme {
        OldSettingsTheme.theme(isDark: colorScheme == .dark)
    }

    private var slide: AnyTransition {
        let forward = navigator.forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading),
            removal: .move(edge: forward ? .leading : .trailing)
        )
    }

    private func updateStatusBar() {
        SettingsStatusBar.shared.update(lightChrome: colorScheme != .dark && navigator.wallpaperPreview == nil)
    }

    // MARK: Screens (OldOS `switch current_nav_view`)

    @ViewBuilder
    private func screen(_ route: String) -> some View {
        switch route {
        case "Settings": SettingsHomeView()
        case "Wi-Fi Networks": WiFiView()
        case "Notifications": NotificationsView()
        case "Location Services": LocationServicesView()
        case "Carrier": CarrierView()
        case "Sounds": SoundsView()
        case "Brightness": BrightnessView()
        case "Wallpaper": WallpaperView()
        case "Wallpaper_Select": WallpaperSelectView()
        case "Wallpaper_Grid": WallpaperGridView()
        case "Wallpaper_Grid_Camera_Roll": CameraRollGridView()
        case "General": GeneralView()
        case "General_About": GeneralAboutView()
        case "General_Legal": GeneralTextView(text: GeneralTextView.legal)
        case "General_Regulatory": GeneralTextView(text: GeneralTextView.regulatory)
        case "General_Usage": GeneralUsageView()
        case "General_Network": GeneralNetworkView()
        case "General_Bluetooth": GeneralBluetoothView()
        case "General_Date": GeneralDateView()
        case "General_Keyboard": GeneralKeyboardView()
        case "General_International": GeneralInternationalView()
        case "General_Accessibility": GeneralAccessibilityView()
        case "Mail, Contacts, Calendars": MailContactsCalendarsView()
        case "Mail_Signature": SignatureView()
        case "Phone": PhoneSettingsView()
        case "Safari": SafariSettingsView()
        case "Messages": MessagesSettingsView()
        case "iPod": IPodSettingsView()
        case "Photos": PhotosSettingsView()
        case "Notes": NotesSettingsView()
        case "Store": StoreSettingsView()
        case "Nike + iPod": NikeSettingsView()
        default:
            if route.hasPrefix("Option:"), let option = SettingsOptions.all[String(route.dropFirst("Option:".count))] {
                OptionListView(option: option)
            } else {
                SettingsHomeView()
            }
        }
    }
}
