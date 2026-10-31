import SwiftUI
import UIKit

// OldOS Settings.swift: `general_view` and its screens (About, Usage,
// Network, Bluetooth, Auto-Lock, Date & Time, Keyboard, International,
// Accessibility), with the real device values where iOS gives them.

struct GeneralView: View {
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [
                chevronRow("About", destination: "General_About"),
                chevronRow("Usage", destination: "General_Usage")
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                chevronRow("Network", destination: "General_Network"),
                chevronRow("Bluetooth", destination: "General_Bluetooth")
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [chevronRow("Spotlight Search")])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                SettingsRow(title: "Auto-Lock", content: AnyView(ValueContent(text: store.string("General.AutoLock", default: "Never"))), destination: SettingsOptions.route("General.AutoLock"))
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                chevronRow("Date & Time", destination: "General_Date"),
                chevronRow("Keyboard", destination: "General_Keyboard"),
                chevronRow("International", destination: "General_International"),
                chevronRow("Accessibility", destination: "General_Accessibility")
            ])
        }
    }
}

// MARK: - About (`general_about_view`)

struct GeneralAboutView: View {
    @ObservedObject private var media = MediaCounts.shared
    private let store = SettingsStore.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 7)
            SettingsHeader(text: UIDevice.current.name)
            SettingsSection(rows: [
                valueRow("Network", "Not Available"),
                valueRow("Songs", media.songs),
                valueRow("Videos", media.videos),
                valueRow("Photos", media.photos),
                valueRow("Applications", "19"),
                valueRow("Capacity", DeviceInfo.totalSpace),
                valueRow("Available", DeviceInfo.freeSpace),
                valueRow("Version", DeviceInfo.version),
                valueRow("Carrier", "Carrier 10.0"),
                valueRow("Model", DeviceInfo.machine),
                valueRow("Serial Number", store.stable("Serial") { randomString(length: 11) }),
                valueRow("Wi-Fi Address", store.stable("WiFiAddress") { Self.address() }),
                valueRow("Bluetooth", store.stable("BluetoothAddress") { Self.address() }),
                valueRow("IMEI", store.stable("IMEI") { "\(randomNumberString(length: 2)) \(randomNumberString(length: 6)) \(randomNumberString(length: 6)) \(randomNumberString(length: 1))" }),
                valueRow("ICCID", store.stable("ICCID") { randomNumberString(length: 18) }),
                valueRow("Modem Firmware", "04.10.01")
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                chevronRow("Legal", destination: "General_Legal"),
                chevronRow("Regulatory", destination: "General_Regulatory")
            ])
        }
        .onAppear { media.refresh() }
    }

    static func address() -> String {
        (0..<6).map { _ in randomString(length: 2) }.joined(separator: ":")
    }
}

/// Legal / Regulatory (text pages; OldOS rows went nowhere).
struct GeneralTextView: View {
    let text: String

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            SettingsFooter(text: text, size: 14, alignment: .leading)
        }
    }

    static let legal = """
    OldSettings

    The iOS 6 interface, artwork and Settings screens come from The OldOS Project by Zane Kleinberg (@zzanehip), licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0).
    https://github.com/zzanehip/The-OldOS-Project

    iOS and iPhone are trademarks of Apple Inc. OldSettings is not affiliated with Apple.
    """

    static let regulatory = """
    The regulatory information of this device is in the iOS Settings app:
    Settings › General › Legal & Regulatory.
    """
}

// MARK: - Usage (`general_usage_view`)

struct GeneralUsageView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [toggleRow("Battery Percentage", key: "Usage.BatteryPercentage")])
            Spacer().frame(height: 17)
            SettingsHeader(text: "Time since last full charge")
            SettingsSection(rows: [
                valueRow("Usage", "0 Minutes"),
                valueRow("Standby", Self.uptime)
            ])
            Spacer().frame(height: 17)
            SettingsHeader(text: "Call Time")
            SettingsSection(rows: [
                valueRow("Current Period", "0 Minutes"),
                valueRow("Lifetime", "0 Minutes")
            ])
            Spacer().frame(height: 17)
            SettingsHeader(text: "Cellular Network Data")
            SettingsSection(rows: [
                valueRow("Sent", "0 bytes"),
                valueRow("Received", "0 bytes")
            ])
        }
    }

    /// Time since the device started ("2 Days, 4 Hours").
    static var uptime: String {
        let total = Int(ProcessInfo.processInfo.systemUptime)
        let days = total / 86_400
        let hours = (total % 86_400) / 3600
        let minutes = (total % 3600) / 60
        if days > 0 { return "\(days) Day\(days == 1 ? "" : "s"), \(hours) Hour\(hours == 1 ? "" : "s")" }
        if hours > 0 { return "\(hours) Hour\(hours == 1 ? "" : "s"), \(minutes) Minute\(minutes == 1 ? "" : "s")" }
        return "\(minutes) Minute\(minutes == 1 ? "" : "s")"
    }
}

// MARK: - Network (`general_network_view`)

struct GeneralNetworkView: View {
    @ObservedObject private var store = SettingsStore.shared
    @ObservedObject private var wifi = WiFiStatus.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [toggleRow("Enable 3G", key: "Network.3G")])
            SettingsFooter(text: "Using 3G loads data faster, but may\n decrease battery life.")
            Spacer().frame(height: 7)
            SettingsSection(rows: [toggleRow("Cellular Data", key: "Network.CellularData")])
            Spacer().frame(height: 12)
            SettingsSection(rows: [chevronRow("Cellular Data Network")])
            Spacer().frame(height: 12)
            SettingsSection(rows: [toggleRow("Data Roaming", key: "Network.Roaming", default: false)])
            SettingsFooter(text: "Turn data roaming off when abroad\n to avoid substantial roaming charges\n when using email, web browsing, and\n other data services.")
            Spacer().frame(height: 12)
            SettingsSection(rows: [
                SettingsRow(title: "VPN", content: AnyView(ValueContent(text: "Not Connected")))
            ])
            Spacer().frame(height: 12)
            SettingsSection(rows: [
                SettingsRow(title: "Wi-Fi", content: AnyView(ValueContent(text: store.bool("WiFi", default: true) ? wifi.statusText : "Off")), destination: "Wi-Fi Networks")
            ])
        }
    }
}

// MARK: - Bluetooth (`general_bluetooth_view`)

struct GeneralBluetoothView: View {
    @ObservedObject private var scanner = BluetoothScanner.shared
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        let on = store.bool("Bluetooth", default: true)
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [
                SettingsRow(title: "Bluetooth", content: AnyView(ToggleContent(key: "Bluetooth") { value in
                    if value { scanner.start() } else { scanner.stop() }
                }))
            ])
            if on {
                Spacer().frame(height: 12)
                SettingsHeader(text: "Devices")
                SettingsSection(rows: deviceRows)
                if scanner.unauthorized {
                    SettingsFooter(text: "Allow OldSettings to use Bluetooth in\n Settings › Privacy & Security › Bluetooth.")
                } else if !scanner.poweredOn {
                    SettingsFooter(text: "Bluetooth is turned off in Control Center.")
                }
            }
        }
        .onAppear { if on { scanner.start() } }
        .onDisappear { scanner.stop() }
    }

    private var deviceRows: [SettingsRow] {
        var rows = scanner.devices.map { device in
            SettingsRow(title: device.name, content: AnyView(ValueContent(text: "Not Paired", chevron: false)), id: device.id.uuidString)
        }
        rows.append(SettingsRow(title: "Searching...", content: AnyView(
            HStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .padding(.trailing, 12)
            }
        ), id: "searching"))
        return rows
    }
}

// MARK: - Date & Time (`general_date_view`)

struct GeneralDateView: View {
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        let automatic = store.bool("Date.SetAutomatically", default: true)
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [toggleRow("24-Hour Time", key: "Date.24Hour", default: Self.systemUses24Hour)])
            Spacer().frame(height: 12)
            SettingsSection(rows: [toggleRow("Set Automatically", key: "Date.SetAutomatically")]
                + (automatic ? [] : [
                    SettingsRow(title: "Time Zone", content: AnyView(ValueContent(text: Self.timeZoneCity))),
                    SettingsRow(title: "Set Date & Time", content: AnyView(ValueContent(text: Self.now(store.bool("Date.24Hour", default: Self.systemUses24Hour)))))
                ]))
        }
    }

    static var systemUses24Hour: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
        return !format.contains("a")
    }

    static var timeZoneCity: String {
        (TimeZone.current.identifier.split(separator: "/").last.map(String.init) ?? TimeZone.current.identifier)
            .replacingOccurrences(of: "_", with: " ")
    }

    static func now(_ twentyFour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = twentyFour ? "MMM d, HH:mm" : "MMM d, h:mm a"
        return formatter.string(from: Date())
    }
}

// MARK: - Keyboard (`general_keyboard_view`)

struct GeneralKeyboardView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [
                toggleRow("Auto-Capitalization", key: "Keyboard.AutoCapitalization"),
                toggleRow("Auto-Correction", key: "Keyboard.AutoCorrection"),
                toggleRow("Check Spelling", key: "Keyboard.CheckSpelling"),
                toggleRow("Enable Caps Lock", key: "Keyboard.CapsLock"),
                toggleRow("\".\" Shortcut", key: "Keyboard.PeriodShortcut")
            ])
            SettingsFooter(text: "Double tapping the space bar will\n insert a period followed by a space.")
        }
    }
}

// MARK: - International (`general_international_view`)

struct GeneralInternationalView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [
                SettingsRow(title: "Language", content: AnyView(ValueContent(text: Self.language))),
                SettingsRow(title: "Voice Control", content: AnyView(ValueContent(text: Self.language))),
                SettingsRow(title: "Keyboards", content: AnyView(ValueContent(text: "\(max(UITextInputMode.activeInputModes.count, 1))")))
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                SettingsRow(title: "Region Format", content: AnyView(ValueContent(text: Self.region))),
                SettingsRow(title: "Calendar", content: AnyView(ValueContent(text: Self.calendar)))
            ])
            Spacer().frame(height: 17)
            SettingsFooter(text: "Region Format Example", bold: true, size: 18)
            Spacer().frame(height: 2)
            SettingsFooter(text: Self.example, size: 18)
        }
    }

    static var language: String {
        let code = Locale.preferredLanguages.first ?? "en"
        return Locale(identifier: "en_US").localizedString(forIdentifier: code)?.components(separatedBy: " (").first ?? "English"
    }

    static var region: String {
        let code = Locale.current.regionCode ?? "US"
        return Locale(identifier: "en_US").localizedString(forRegionCode: code) ?? code
    }

    static var calendar: String {
        let identifier = Calendar.current.identifier
        return Locale(identifier: "en_US").localizedString(for: identifier)?.replacingOccurrences(of: " Calendar", with: "") ?? "Gregorian"
    }

    /// "Tuesday, January 5, 2021 / 12:34 AM / (408) 555-1212" in the region format.
    static var example: String {
        let date = DateFormatter()
        date.dateStyle = .full
        date.timeStyle = .none
        let time = DateFormatter()
        time.dateStyle = .none
        time.timeStyle = .short
        return "\(date.string(from: Date()))\n \(time.string(from: Date()))\n (408) 555-1212"
    }
}

// MARK: - Accessibility (`general_accessibility_view`)

struct GeneralAccessibilityView: View {
    var body: some View {
        SettingsPage {
            Spacer().frame(height: 15)
            SettingsSection(rows: [
                SettingsRow(title: "VoiceOver", content: AnyView(ValueContent(text: UIAccessibility.isVoiceOverRunning ? "On" : "Off"))),
                SettingsRow(title: "Zoom", content: AnyView(ValueContent(text: "Off"))),
                SettingsRow(title: "Large Text", content: AnyView(ValueContent(text: Self.largeText))),
                toggleRow("White on Black", key: "Accessibility.WhiteOnBlack", default: UIAccessibility.isInvertColorsEnabled)
            ])
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                toggleRow("Mono Audio", key: "Accessibility.MonoAudio", default: UIAccessibility.isMonoAudioEnabled),
                toggleRow("Speak Auto-text", key: "Accessibility.SpeakAutoText", default: false)
            ])
            SettingsFooter(text: "Automatically speak auto-corrections\n and auto-capitalizations.")
            Spacer().frame(height: 17)
            SettingsSection(rows: [
                SettingsRow(title: "Triple-click Home", content: AnyView(ValueContent(text: "Off")))
            ])
        }
    }

    /// iOS 6 showed the size ("Off", "20pt", "24pt"…).
    static var largeText: String {
        switch UIApplication.shared.preferredContentSizeCategory {
        case .extraSmall, .small, .medium, .large: return "Off"
        case .extraLarge: return "20pt"
        case .extraExtraLarge: return "24pt"
        case .extraExtraExtraLarge: return "32pt"
        default: return "40pt"
        }
    }
}
