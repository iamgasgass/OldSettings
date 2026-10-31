import SwiftUI

// OldOS Settings.swift: Mail, Contacts, Calendars (`mcc_view`), Phone,
// Safari, Messages, iPod, Photos, Notes, Store and Nike + iPod, plus the
// check-mark lists their value rows open.

// MARK: - Mail, Contacts, Calendars

struct MailContactsCalendarsView: View {
    @Environment(\.oldSettingsTheme) private var theme
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 7)
            SettingsHeader(text: "Accounts")
            SettingsSection(rows: [chevronRow("Add Account...")])
            Spacer().frame(height: 7)
            SettingsSection(rows: [optionRow("Fetch New Data", key: "Mail.Fetch")])
            Spacer().frame(height: 7)
            SettingsHeader(text: "Mail")
            SettingsSection(rows: [
                optionRow("Show", key: "Mail.Show"),
                optionRow("Preview", key: "Mail.Preview"),
                optionRow("Minimum Font Size", key: "Mail.FontSize"),
                toggleRow("Show To/Cc Label", key: "Mail.ShowToCc", default: false),
                toggleRow("Ask Before Deleting", key: "Mail.AskBeforeDeleting", default: false),
                toggleRow("Load Remote Images", key: "Mail.LoadRemoteImages", default: true),
                toggleRow("Organize by Thread", key: "Mail.OrganizeByThread", default: true)
            ])
            Spacer().frame(height: 7)
            SettingsSection(rows: [
                toggleRow("Always Bcc Myself", key: "Mail.AlwaysBcc", default: false),
                SettingsRow(title: "Signature", content: AnyView(ValueContent(text: store.string("Mail.Signature", default: "Sent from my iPhone"))), destination: "Mail_Signature")
            ])
            Spacer().frame(height: 7)
            SettingsHeader(text: "Contacts")
            SettingsSection(rows: [
                optionRow("Sort Order", key: "Contacts.SortOrder"),
                optionRow("Display Order", key: "Contacts.DisplayOrder")
            ])
            Spacer().frame(height: 7)
            SettingsSection(style: .contentOnly, rows: [
                SettingsRow(title: "", content: AnyView(
                    HStack {
                        Spacer()
                        Text("Import SIM Contacts")
                            .font(OldOSFont.bold(18))
                            .foregroundColor(theme.listRowText)
                        Spacer()
                    }
                ), action: { OldSettingsHaptics.tap() }, id: "sim")
            ])
            Spacer().frame(height: 7)
            SettingsHeader(text: "Calendars")
            SettingsSection(rows: [
                toggleRow("New Invitation Alerts", key: "Calendars.InvitationAlerts", default: true),
                SettingsRow(title: "Time Zone Support", content: AnyView(ValueContent(text: "Off")))
            ])
        }
    }
}

/// "Signature" (a text field, like iOS 6).
struct SignatureView: View {
    @Environment(\.oldSettingsTheme) private var theme
    @ObservedObject private var store = SettingsStore.shared
    @FocusState private var focused: Bool

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            TextEditor(text: Binding(
                get: { store.string("Mail.Signature", default: "Sent from my iPhone") },
                set: { store.setString("Mail.Signature", $0) }
            ))
            .font(OldOSFont.regular(18))
            .foregroundColor(theme.listRowText)
            .scrollContentBackground(.hidden)
            .focused($focused)
            .padding(8)
            .frame(height: 140)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.cardFill))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.cardStroke, lineWidth: 1.25))
            .padding(.horizontal, 12)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true }
        }
    }
}

// MARK: - Phone (`phone_view`)

struct PhoneSettingsView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [SettingsRow(title: "My Number", content: AnyView(ValueContent(text: "Unknown")))])
            Spacer().frame(height: 7)
            SettingsSection(rows: [toggleRow("FaceTime", key: "Phone.FaceTime", default: true)])
            Spacer().frame(height: 7)
            SettingsHeader(text: "Calls")
            SettingsSection(rows: [
                chevronRow("Call Forwarding"),
                toggleRow("Call Waiting", key: "Phone.CallWaiting", default: true),
                optionRow("Show My Caller ID", key: "Phone.ShowCallerID"),
                toggleRow("TTY", key: "Phone.TTY", default: false)
            ])
            Spacer().frame(height: 7)
            SettingsSection(rows: [toggleRow("International Assist", key: "Phone.InternationalAssist", default: true)])
            SettingsFooter(text: "International Assist automatically\n adds the correct prefix to US\n numbers when dialing from abroad.")
            Spacer().frame(height: 7)
            SettingsSection(rows: [chevronRow("SIM PIN")])
        }
    }
}

// MARK: - Safari (`safari_view`)

struct SafariSettingsView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 7)
            SettingsHeader(text: "General")
            SettingsSection(rows: [optionRow("Search Engine", key: "Safari.SearchEngine")])
            Spacer().frame(height: 7)
            SettingsSection(rows: [SettingsRow(title: "AutoFill", content: AnyView(ValueContent(text: "Off")))])
            Spacer().frame(height: 7)
            SettingsHeader(text: "Security")
            SettingsSection(rows: [toggleRow("Fraud Warning", key: "Safari.FraudWarning", default: true)])
            SettingsFooter(text: "Warn when visiting fraudulent websites.")
            Spacer().frame(height: 7)
            SettingsSection(rows: [
                toggleRow("JavaScript", key: "Safari.JavaScript", default: true),
                toggleRow("Block Pop-ups", key: "Safari.BlockPopups", default: true),
                optionRow("Accept Cookies", key: "Safari.Cookies")
            ])
        }
    }
}

// MARK: - Messages (`messages_view`)

struct MessagesSettingsView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [toggleRow("Show Preview", key: "Messages.ShowPreview", default: true)])
            Spacer().frame(height: 7)
            SettingsSection(rows: [optionRow("Play Alert Tone", key: "Messages.AlertTone")])
            Spacer().frame(height: 7)
            SettingsSection(rows: [
                toggleRow("MMS Messaging", key: "Messages.MMS", default: true),
                toggleRow("Group Messaging", key: "Messages.Group", default: false),
                toggleRow("Show Subject Field", key: "Messages.SubjectField", default: false)
            ])
            Spacer().frame(height: 7)
            SettingsSection(rows: [toggleRow("Character Count", key: "Messages.CharacterCount", default: false)])
        }
    }
}

// MARK: - iPod (`ipod_view`)

struct IPodSettingsView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 7)
            SettingsHeader(text: "Music")
            SettingsSection(rows: [
                toggleRow("Shake to Shuffle", key: "iPod.ShakeToShuffle", default: false),
                toggleRow("Sound Check", key: "iPod.SoundCheck", default: false),
                optionRow("EQ", key: "iPod.EQ"),
                optionRow("Volume Limit", key: "iPod.VolumeLimit"),
                toggleRow("Lyrics & Podcast Info", key: "iPod.Lyrics", default: true)
            ])
            Spacer().frame(height: 7)
            SettingsHeader(text: "Video")
            SettingsSection(rows: [
                optionRow("Start Playing", key: "iPod.StartPlaying"),
                toggleRow("Closed Captioning", key: "iPod.ClosedCaptioning", default: false)
            ])
            Spacer().frame(height: 7)
            SettingsHeader(text: "TV Out")
            SettingsSection(rows: [
                toggleRow("Widescreen", key: "iPod.Widescreen", default: false),
                optionRow("TV Signal", key: "iPod.TVSignal")
            ])
        }
    }
}

// MARK: - Photos (`photos_view`)

struct PhotosSettingsView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 7)
            SettingsHeader(text: "Slideshow")
            SettingsSection(rows: [
                optionRow("Play Each Slide For", key: "Photos.SlideDuration"),
                toggleRow("Repeat", key: "Photos.Repeat", default: false),
                toggleRow("Shuffle", key: "Photos.Shuffle", default: false)
            ])
            Spacer().frame(height: 7)
            SettingsHeader(text: "HDR (High Dynamic Range)")
            SettingsFooter(text: "HDR blends the best parts of three\nseparate exposures into a single photo.", alignment: .leading)
            Spacer().frame(height: 7)
            SettingsSection(rows: [toggleRow("Keep Normal Photo", key: "Photos.KeepNormal", default: true)])
            SettingsFooter(text: "Save the normal exposed photo in\n addition to the HDR version.")
        }
    }
}

// MARK: - Notes (`notes_view`)

struct NotesSettingsView: View {
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        let selected = store.string("Notes.Font", default: "Noteworthy")
        SettingsPage {
            Spacer().frame(height: 7)
            SettingsHeader(text: "Font")
            SettingsSection(style: .blue, rows: ["Noteworthy", "Helvetica", "Marker Felt"].map { font in
                SettingsRow(title: font, content: AnyView(CheckContent(checked: selected == font)), selected: selected == font, action: {
                    OldSettingsHaptics.tap()
                    store.setString("Notes.Font", font)
                })
            })
        }
    }
}

// MARK: - Store (`store_view`)

struct StoreSettingsView: View {
    @Environment(\.oldSettingsTheme) private var theme

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(style: .contentOnly, rows: [
                SettingsRow(title: "", content: AnyView(
                    HStack {
                        Spacer()
                        Text("Sign In")
                            .font(OldOSFont.bold(18))
                            .foregroundColor(theme.listRowText)
                        Spacer()
                    }
                ), action: {
                    // The App Store account lives in the iOS Settings app.
                    if let url = URL(string: "itms-apps://apps.apple.com") {
                        UIApplication.shared.open(url)
                    }
                }, id: "sign-in")
            ])
        }
    }
}

// MARK: - Nike + iPod (`nike_view`)

struct NikeSettingsView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [toggleRow("Nike + iPod", key: "Nike", default: false)])
        }
    }
}

// MARK: - Check-mark list (iOS 6 value screens)

struct OptionListView: View {
    @ObservedObject private var store = SettingsStore.shared
    let option: SettingsOption

    var body: some View {
        let selected = store.string(option.key, default: option.defaultValue)
        SettingsPage {
            Spacer().frame(height: option.header == nil ? 15 : 7)
            if let header = option.header {
                SettingsHeader(text: header)
            }
            SettingsSection(style: .blue, rows: option.choices.map { choice in
                SettingsRow(title: choice, content: AnyView(CheckContent(checked: selected == choice)), selected: selected == choice, action: {
                    OldSettingsHaptics.tap()
                    store.setString(option.key, choice)
                    switch option.preview {
                    case .ringtone: SettingsSounds.playRingtone(choice)
                    case .textTone: SettingsSounds.playTextTone(choice)
                    case .none: break
                    }
                    if option.key == "General.AutoLock" {
                        UIApplication.shared.isIdleTimerDisabled = choice == "Never"
                    }
                }, id: choice)
            })
            if let footer = option.footer {
                SettingsFooter(text: footer)
            }
        }
        .onDisappear { SettingsSounds.stop() }
    }
}
