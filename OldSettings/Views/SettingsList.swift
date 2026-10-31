import SwiftUI

/// OldOS `list_row`: a title, an optional 30 × 30 icon, the content on the
/// right (value, switch, arrow…) and the screen it opens. `action` is for
/// rows that do something in place (pick an option, play a sound).
struct SettingsRow: Identifiable {
    let id: String
    var title: String
    var image: String?
    var content: AnyView
    var destination: String?
    var selected: Bool?
    var action: (() -> Void)?

    init(title: String, image: String? = nil, content: AnyView = AnyView(EmptyView()), destination: String? = nil, selected: Bool? = nil, action: (() -> Void)? = nil, id: String? = nil) {
        self.id = id ?? "\(title)|\(destination ?? "")|\(image ?? "")"
        self.title = title
        self.image = image
        self.content = content
        self.destination = destination
        self.selected = selected
        self.action = action
    }
}

/// OldOS `list_section`, `list_section_blue`, `list_section_oversize` and
/// `list_section_content_only`: the white rounded card with 50 pt rows and
/// the 1.25 pt grey separators.
struct SettingsSection: View {
    enum Style {
        /// `list_section`: black bold titles.
        case standard
        /// `list_section_blue`: check-mark lists, the selected row in blue.
        case blue
        /// `list_section_oversize`: the title is not pushed left (long titles).
        case oversize
        /// `list_section_content_only`: rows without a title show only the content.
        case contentOnly
    }

    @Environment(\.oldSettingsTheme) private var theme
    @EnvironmentObject private var navigator: SettingsNavigator
    var style: Style = .standard
    let rows: [SettingsRow]
    var rowHeight: CGFloat = 50

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                let isLast = index == rows.count - 1
                if row.destination != nil || row.action != nil {
                    Button {
                        if let action = row.action {
                            action()
                        } else if let destination = row.destination {
                            navigator.push(destination)
                        }
                    } label: {
                        rowBody(row, isLast: isLast)
                    }
                    .buttonStyle(SettingsRowButtonStyle())
                } else {
                    rowBody(row, isLast: isLast)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.cardFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.cardStroke, lineWidth: 1.25)
        )
        .padding([.leading, .trailing], 12)
    }

    private func rowBody(_ row: SettingsRow, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            rowContent(row, isLast: isLast)
        }
    }

    @ViewBuilder
    private func rowContent(_ row: SettingsRow, isLast: Bool) -> some View {
        HStack {
            switch style {
            case .blue:
                if let image = row.image, !image.isEmpty {
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(row.selected == true ? theme.cardFieldText : theme.listRowText)
                        .padding(.leading, 12)
                }
                Text(row.title)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(row.selected == true ? theme.cardFieldText : theme.listRowText)
                    .lineLimit(1)
                    .padding(.leading, row.image?.isEmpty == false ? 0 : 12)
                Spacer()
                row.content
            case .standard, .oversize, .contentOnly:
                if let image = row.image {
                    Image(image)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding(.leading, 12)
                }
                if style != .contentOnly || !row.title.isEmpty {
                    Text(row.title)
                        .font(OldOSFont.bold(18))
                        .foregroundColor(theme.listRowText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.leading, row.image != nil || style == .oversize ? (style == .oversize && row.image == nil ? 12 : 0) : 12)
                    if style != .oversize {
                        Spacer()
                    }
                }
                row.content
            }
        }
        .frame(height: rowHeight - (isLast ? 0 : 1.25))
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        if !isLast {
            Rectangle().fill(theme.cardStroke).frame(height: 1.25)
        }
    }
}

/// iOS 6 blue table selection.
struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(oldOS: [
                    OldOSStop(.oldOS(5, 140, 245), 0),
                    OldOSStop(.oldOS(1, 93, 230), 1)
                ])
                .opacity(configuration.isPressed ? 1 : 0)
            )
    }
}

// MARK: - Row contents (OldOS `*_content` views)

/// `generic_content` / `general_content`: the grey arrow.
struct ChevronContent: View {
    var body: some View {
        HStack {
            Spacer()
            Image("TableNext").padding(.trailing, 12)
        }
    }
}

/// `mcc_content` / `notification_content`: the blue value and the arrow.
struct ValueContent: View {
    @Environment(\.oldSettingsTheme) private var theme
    let text: String
    var chevron = true

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Text(text)
                .font(OldOSFont.regular(18))
                .foregroundColor(theme.cardFieldText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.trailing, chevron ? 0 : 12)
            if chevron {
                Image("TableNext").padding(.trailing, 12)
            }
        }
    }
}

/// The blue check mark of `list_section_blue` (`TWPickerTableCellChecked`).
struct CheckContent: View {
    @Environment(\.oldSettingsTheme) private var theme
    let checked: Bool

    var body: some View {
        HStack {
            Spacer()
            if checked {
                Image("CheckMark")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 15, height: 15)
                    .foregroundColor(theme.cardFieldText)
                    .padding(.trailing, 12)
            }
        }
    }
}

/// `toggle()` bound to a saved value (`usage_battery_content`,
/// `mcc_content_toggle`, …).
struct ToggleContent: View {
    @ObservedObject private var store = SettingsStore.shared
    let key: String
    var defaultValue = true
    var orange = false
    var onChange: ((Bool) -> Void)? = nil

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            OldOSToggle(isOn: store.binding(key, default: defaultValue), tint: orange ? .orange : .blue, onChange: onChange)
                .padding(.trailing, 12)
        }
    }
}

/// A switch driven by any binding (real device state).
struct BindingToggleContent: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            OldOSToggle(isOn: $isOn).padding(.trailing, 12)
        }
    }
}
