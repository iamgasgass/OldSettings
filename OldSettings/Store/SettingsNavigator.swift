import SwiftUI

/// OldOS `current_nav_view` / `forward_or_backward`, as a stack so every
/// screen goes back to the one it came from.
final class SettingsNavigator: ObservableObject {
    @Published private(set) var stack: [String] = ["Settings"]
    @Published private(set) var forward = true
    /// The full-screen wallpaper preview (OldOS `show_wallpaper_select`).
    @Published var wallpaperPreview: WallpaperChoice?

    private var pushing = false

    var current: String { stack.last ?? "Settings" }

    /// OldOS waited 0.3 s (the row highlight) before sliding.
    func push(_ route: String) {
        guard !pushing else { return }
        pushing = true
        forward = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.linear(duration: 0.28)) {
                self.stack.append(route)
            }
            self.pushing = false
        }
    }

    func pop() {
        guard stack.count > 1 else { return }
        oldOSHideKeyboard()
        forward = false
        withAnimation(.linear(duration: 0.28)) {
            _ = stack.removeLast()
        }
    }

    func popToRoot() {
        forward = false
        withAnimation(.linear(duration: 0.28)) {
            stack = ["Settings"]
        }
    }

    // MARK: Titles (OldOS `title_bar` titles)

    func title(of route: String) -> String {
        switch route {
        case "Wallpaper_Select": return ""
        case "Wallpaper_Grid": return "Wallpaper"
        case "Wallpaper_Grid_Camera_Roll": return "Camera Roll"
        case "MCC_Action": return SettingsStore.shared.string("Mail.AccountName", default: "Account")
        case "Mail_Signature": return "Signature"
        case "General_Legal": return "Legal"
        case "General_DateTimeZone": return "Time Zone"
        default:
            if route.hasPrefix("General_") {
                let name = route.replacingOccurrences(of: "General_", with: "")
                switch name {
                case "Autolock": return "Auto-Lock"
                case "Date": return "Date & Time"
                default: return name
                }
            }
            if route.hasPrefix("Option:") {
                let key = String(route.dropFirst("Option:".count))
                return SettingsOptions.all[key]?.title ?? ""
            }
            return route
        }
    }

    /// The back button: the title of the previous screen; "Back" when that
    /// has no title (Wallpaper grids), "Mail..." for the long one.
    var backTitle: String? {
        guard stack.count > 1 else { return nil }
        let previous = stack[stack.count - 2]
        let title = self.title(of: previous)
        if title.isEmpty { return current.hasPrefix("Wallpaper_Grid") ? "Back" : "Wallpaper" }
        if previous == "Mail, Contacts, Calendars" { return "Mail..." }
        if title.count > 12 { return "Back" }
        return title
    }
}

/// A wallpaper being previewed: one of the bundled iOS 6 wallpapers or a
/// photo from the Camera Roll.
struct WallpaperChoice: Identifiable, Equatable {
    let id = UUID()
    var bundled: String?
    var image: UIImage?

    static func == (lhs: WallpaperChoice, rhs: WallpaperChoice) -> Bool {
        lhs.id == rhs.id
    }
}
