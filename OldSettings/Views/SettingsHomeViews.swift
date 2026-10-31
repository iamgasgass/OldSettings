import SwiftUI
import CoreLocation

// OldOS Settings.swift: `settings_home` and the first-level screens
// (Wi-Fi, Notifications, Location Services, Carrier, Sounds, Brightness).

/// A value row that opens its check-mark list.
func optionRow(_ title: String, key: String, image: String? = nil) -> SettingsRow {
    let option = SettingsOptions.all[key]
    let value = SettingsStore.shared.string(key, default: option?.defaultValue ?? "")
    return SettingsRow(title: title, image: image, content: AnyView(ValueContent(text: value)), destination: SettingsOptions.route(key))
}

func toggleRow(_ title: String, key: String, default value: Bool = true, image: String? = nil) -> SettingsRow {
    SettingsRow(title: title, image: image, content: AnyView(ToggleContent(key: key, defaultValue: value)))
}

func chevronRow(_ title: String, image: String? = nil, destination: String? = nil) -> SettingsRow {
    SettingsRow(title: title, image: image, content: AnyView(ChevronContent()), destination: destination)
}

func valueRow(_ title: String, _ value: String, chevron: Bool = false) -> SettingsRow {
    SettingsRow(title: title, content: AnyView(ValueContent(text: value, chevron: chevron)))
}

// MARK: - Home (`settings_home`)

struct SettingsHomeView: View {
    @ObservedObject private var store = SettingsStore.shared
    @ObservedObject private var wifi = WiFiStatus.shared
    @ObservedObject private var location = LocationStatus.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [
                SettingsRow(title: "Airplane Mode", image: "RowAirplane", content: AnyView(ToggleContent(key: "AirplaneMode", defaultValue: false, orange: true))),
                SettingsRow(title: "Wi-Fi", image: "RowWiFi", content: AnyView(ValueContent(text: store.bool("WiFi", default: true) ? wifi.statusText : "Off")), destination: "Wi-Fi Networks"),
                SettingsRow(title: "Notifications", image: "RowNotifications", content: AnyView(ValueContent(text: store.bool("Notifications", default: true) ? "On" : "Off")), destination: "Notifications"),
                SettingsRow(title: "Location Services", image: "RowLocation", content: AnyView(ValueContent(text: location.isOn ? "On" : "Off")), destination: "Location Services"),
                chevronRow("Carrier", image: "RowCarrier", destination: "Carrier")
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                chevronRow("Sounds", image: "RowSounds", destination: "Sounds"),
                chevronRow("Brightness", image: "RowBrightness", destination: "Brightness"),
                chevronRow("Wallpaper", image: "RowWallpaper", destination: "Wallpaper")
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                chevronRow("General", image: "RowGeneral", destination: "General"),
                chevronRow("Mail, Contacts, Calendars", image: "RowMail", destination: "Mail, Contacts, Calendars"),
                chevronRow("Phone", image: "RowPhone", destination: "Phone"),
                chevronRow("Safari", image: "RowSafari", destination: "Safari"),
                chevronRow("Messages", image: "RowMessages", destination: "Messages"),
                chevronRow("iPod", image: "RowMusic", destination: "iPod"),
                chevronRow("Photos", image: "RowPhotos", destination: "Photos"),
                chevronRow("Notes", image: "RowNotes", destination: "Notes"),
                chevronRow("Store", image: "RowStore", destination: "Store")
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                chevronRow("Nike + iPod", image: "RowNike", destination: "Nike + iPod")
            ])
        }
        .onAppear {
            wifi.refreshSSID()
            location.refresh()
        }
    }
}

// MARK: - Wi-Fi (`wifi_view`)

struct WiFiView: View {
    @ObservedObject private var store = SettingsStore.shared
    @ObservedObject private var wifi = WiFiStatus.shared
    @State private var searching = true

    var body: some View {
        let on = store.bool("WiFi", default: true)
        SettingsPage {
            Spacer().frame(height: 12)
            SettingsSection(rows: [toggleRow("Wi-Fi", key: "WiFi")])
            if on {
                Spacer().frame(height: 7)
                HStack {
                    SettingsHeader(text: "Choose a Network...")
                    if searching {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .padding(.trailing, 24)
                    }
                }
                SettingsSection(style: .blue, rows: networkRows)
                Spacer().frame(height: 12)
                SettingsSection(style: .oversize, rows: [
                    SettingsRow(title: "Ask to Join Networks", content: AnyView(HStack { OldOSToggle(isOn: store.binding("WiFi.AskToJoin", default: true)) }.padding(.leading, 6)))
                ])
                SettingsFooter(text: "Known networks will be joined\n automatically. If no known networks are available, you will be asked before joining \na new network.")
            }
        }
        .onAppear {
            wifi.refreshSSID()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { searching = false }
        }
    }

    private var networkRows: [SettingsRow] {
        var rows: [SettingsRow] = []
        if wifi.connected {
            rows.append(SettingsRow(
                title: wifi.ssid ?? "Current Network",
                image: "CheckMark",
                content: AnyView(HStack {
                    Spacer()
                    Image("WiFiLock").padding(.leading, 2)
                    Image("WiFiBars").padding(.trailing, 1)
                    Image("DetailDisclosure").resizable().frame(width: 29, height: 31).padding(.trailing, 12)
                }),
                selected: true
            ))
        }
        rows.append(SettingsRow(title: "Other...", content: AnyView(ChevronContent())))
        return rows
    }
}

// MARK: - Notifications (`notifications_view`)

struct NotificationsView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            SettingsSection(rows: [toggleRow("Notifications", key: "Notifications")])
            SettingsFooter(text: "Turn off Notifications to disable Sounds,\n Alerts and Home Screen Badges for the\n applications below.")
        }
    }
}

// MARK: - Location Services (`location_services_view`)

struct LocationServicesView: View {
    @ObservedObject private var location = LocationStatus.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            SettingsSection(rows: [
                SettingsRow(title: "Location Services", content: AnyView(BindingToggleContent(isOn: Binding(
                    get: { location.isOn },
                    set: { _ in
                        // Location Services is a system switch: ask for
                        // access, or open the app's page in iOS Settings.
                        if location.authorization == .notDetermined {
                            location.request()
                        } else if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                ))))
            ])
            SettingsFooter(text: "Allow the apps below to determine your\n approximate location.")
            Spacer().frame(height: 7)
            SettingsSection(rows: [toggleRow("Camera", key: "Location.Camera", image: "RowCamera")])
        }
        .onAppear { location.refresh() }
    }
}

// MARK: - Carrier (`carrier_view`)

struct CarrierView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            SettingsHeader(text: "Carriers")
            SettingsSection(style: .blue, rows: [
                SettingsRow(title: "Automatic", content: AnyView(CheckContent(checked: true)), selected: true)
            ])
        }
    }
}

// MARK: - Sounds (`sounds_view`)

struct SoundsView: View {
    @ObservedObject private var store = SettingsStore.shared
    @ObservedObject private var volume = VolumeObserver.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            SettingsHeader(text: "Silent")
            SettingsSection(rows: [vibrateRow("Vibrate", key: "Sounds.VibrateSilent")])
            Spacer().frame(height: 12)
            SettingsHeader(text: "Ringer and Alerts")
            SettingsSection(style: .contentOnly, rows: [
                SettingsRow(title: "", content: AnyView(
                    HStack {
                        Image("SpeakerMute").padding([.top, .bottom, .leading])
                        OldOSSlider(value: $volume.volume) { value in
                            volume.setVolume(value)
                        }
                        .padding([.leading, .trailing], 2)
                        Image("SpeakerMax").padding([.top, .bottom, .trailing])
                    }
                ), id: "volume-slider"),
                toggleRow("Change with Buttons", key: "Sounds.ChangeWithButtons")
            ])
            SettingsFooter(text: "The volume of the ringer and alerts can\n be adjusted using the volume buttons.")
            Spacer().frame(height: 7)
            SettingsSection(rows: [
                vibrateRow("Vibrate", key: "Sounds.VibrateRing"),
                optionRow("Ringtone", key: "Sounds.Ringtone"),
                optionRow("Text Tone", key: "Sounds.TextTone"),
                toggleRow("New Voicemail", key: "Sounds.NewVoicemail"),
                toggleRow("New Mail", key: "Sounds.NewMail"),
                toggleRow("Sent Mail", key: "Sounds.SentMail"),
                toggleRow("Calendar Alerts", key: "Sounds.CalendarAlerts"),
                toggleRow("Lock Sounds", key: "Sounds.LockSounds"),
                toggleRow("Keyboard Clicks", key: "Sounds.KeyboardClicks")
            ])
        }
        .background(VolumeViewHost().frame(width: 1, height: 1))
    }

    /// Turning Vibrate on vibrates, as on iOS 6.
    private func vibrateRow(_ title: String, key: String) -> SettingsRow {
        SettingsRow(title: title, content: AnyView(ToggleContent(key: key, defaultValue: true) { on in
            if on { SettingsSounds.vibrate() }
        }), id: key)
    }
}

// MARK: - Brightness (`brightness_view`)

struct BrightnessView: View {
    @ObservedObject private var brightness = BrightnessObserver.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            SettingsSection(style: .contentOnly, rows: [
                SettingsRow(title: "", content: AnyView(
                    HStack {
                        Image("LessBright").padding([.top, .bottom, .leading])
                        OldOSSlider(value: $brightness.brightness) { value in
                            brightness.setBrightness(value)
                        }
                        .padding([.leading, .trailing], 2)
                        Image("MoreBright").padding([.top, .bottom, .trailing])
                    }
                ), id: "brightness-slider"),
                toggleRow("Auto-Brightness", key: "Brightness.Auto")
            ])
        }
    }
}
