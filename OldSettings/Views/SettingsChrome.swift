import SwiftUI

// OldOS `title_bar`: the blue iOS 6 navigation bar with the embossed title
// sliding left / right, and the pointed back button ("Settings", "General",
// "Wallpaper", "Back", "Mail…"). Extended behind the status bar / Dynamic
// Island like the OldSafari chrome.

struct SettingsTitleBar: View {
    @Environment(\.oldSettingsTheme) private var theme
    @EnvironmentObject private var navigator: SettingsNavigator
    let topInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)
            ZStack {
                HStack {
                    Spacer()
                    Text(navigator.title(of: navigator.current))
                        .font(OldOSFont.bold(22))
                        .foregroundColor(theme.titleBarTitle)
                        .shadow(color: theme.titleBarTitleShadow, radius: 0, x: 0, y: -1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: navigator.backTitle == nil ? 300 : 180)
                        .transition(slide.combined(with: .opacity))
                        .id(navigator.current)
                    Spacer()
                }
                HStack {
                    if let back = navigator.backTitle {
                        SettingsBackButton(title: back) {
                            navigator.pop()
                        }
                        .padding(.leading, 6)
                        .transition(slide.combined(with: .opacity))
                        .id("back-\(navigator.current)")
                    }
                    Spacer()
                }
            }
            .frame(height: 60)
        }
        .background(
            VStack(spacing: 0) {
                Color.clear.frame(height: topInset)
                Color.clear
                    .frame(height: 60)
                    .oldOSInnerShadowBottom(color: theme.barHighlight, radius: 0.025)
            }
            .background(LinearGradient(oldOS: theme.barGradient))
        )
        .oldOSBorder(width: 1, edges: [.bottom], color: theme.barHairline)
    }

    private var slide: AnyTransition {
        let forward = navigator.forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading),
            removal: .move(edge: forward ? .leading : .trailing)
        )
    }
}

/// OldOS `Button2` / `Button_wp4`: the pointed blue back button.
struct SettingsBackButton: View {
    @Environment(\.oldSettingsTheme) private var theme
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            OldSettingsHaptics.tap()
            action()
        } label: {
            Text(title)
                .font(OldOSFont.bold(13))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6)
                .lineLimit(1)
                .fixedSize()
                .offset(y: -1.1)
                .padding(.leading, 15)
                .padding(.trailing, 9)
                .frame(minWidth: 63)
                .frame(height: 33)
                .background(
                    Image("NavBack")
                        .resizable(capInsets: EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 5), resizingMode: .stretch)
                        .saturation(theme.barButtonSaturation)
                        .brightness(theme.barButtonBrightness)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// OldOS `tool_bar_rectangle_button`.
struct SettingsBarButton: View {
    @Environment(\.oldSettingsTheme) private var theme
    let title: String
    var type: OldOSButtonType = .gray
    let action: () -> Void

    var body: some View {
        Button {
            OldSettingsHaptics.tap()
            action()
        } label: {
            Text(title)
                .font(OldOSFont.bold(13.25))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                .lineLimit(1)
                .fixedSize()
                .padding([.leading, .trailing], 11)
                .frame(height: 32)
                .oldOSInnerShadowBackground(RoundedRectangle(cornerRadius: 5.5), oldOSButtonGradient(type), radius: 0.8, offset: CGPoint(x: 0, y: 0.6), intensity: 0.7)
                .shadow(color: Color.white.opacity(theme.isDark ? 0.12 : 0.28), radius: 0, x: 0, y: 0.8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grouped background (`settings_main_list`)

struct SettingsBackground: View {
    @Environment(\.oldSettingsTheme) private var theme

    var body: some View {
        ZStack {
            theme.groupedBackground
            OldOSPinstripeBackground(line: theme.groupedPinstripe)
                .clipped()
        }
    }
}

/// The section title above a card ("Choose a Network...", "Silent"…).
struct SettingsHeader: View {
    @Environment(\.oldSettingsTheme) private var theme
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .foregroundColor(theme.sectionHeader)
                .font(OldOSFont.bold(17))
                .shadow(color: theme.isDark ? Color.black.opacity(0.8) : Color.white.opacity(0.9), radius: 0, x: 0, y: theme.isDark ? -0.9 : 0.9)
                .padding([.leading, .trailing], 24)
            Spacer()
        }
    }
}

/// The centred grey explanation under a card.
struct SettingsFooter: View {
    @Environment(\.oldSettingsTheme) private var theme
    let text: String
    var bold = false
    var size: CGFloat = 15
    var alignment: TextAlignment = .center

    var body: some View {
        Text(text)
            .multilineTextAlignment(alignment)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(theme.sectionHeader)
            .font(bold ? OldOSFont.bold(size) : OldOSFont.regular(size))
            .shadow(color: theme.isDark ? Color.black.opacity(0.8) : Color.white.opacity(0.9), radius: 0, x: 0, y: theme.isDark ? -0.9 : 0.9)
            .padding([.leading, .trailing], 24)
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
    }
}

/// The scrolling page every screen uses (`settings_main_list` + ScrollView).
struct SettingsPage<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            SettingsBackground()
            ScrollView {
                VStack(spacing: 8) {
                    content()
                }
                .padding(.bottom, 15 + OldOSScreen.safeArea.bottom)
            }
        }
    }
}
