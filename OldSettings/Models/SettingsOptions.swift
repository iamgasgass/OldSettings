import Foundation

/// A value row that opens a check-mark list (iOS 6). OldOS drew these rows
/// with a value and an arrow that went nowhere; each now opens its list.
struct SettingsOption {
    let key: String
    let title: String
    let choices: [String]
    let defaultValue: String
    var header: String? = nil
    var footer: String? = nil
    /// Played when a choice is tapped.
    var preview: SettingsSoundPreview = .none
}

enum SettingsSoundPreview {
    case none
    case ringtone
    case textTone
}

enum SettingsOptions {
    static let ringtones = [
        "Marimba", "Alarm", "Ascending", "Bark", "Bell Tower", "Blues", "Boing",
        "Crickets", "Digital", "Doorbell", "Duck", "Harp", "Motorcycle",
        "Old Car Horn", "Old Phone", "Piano Riff", "Pinball", "Robot",
        "Sci-Fi", "Sonar", "Strum", "Timba", "Time Passing", "Trill", "Xylophone"
    ]

    /// iOS 6 alert tones, with the system sound that plays each one.
    static let textTones: [(String, UInt32)] = [
        ("None", 0), ("Tri-tone", 1007), ("Chime", 1008), ("Glass", 1009),
        ("Horn", 1010), ("Bell", 1013), ("Electronic", 1014),
        ("Anticipate", 1020), ("Bloom", 1021), ("Calypso", 1022),
        ("Choo Choo", 1023), ("Descent", 1024), ("Fanfare", 1025),
        ("Ladder", 1026), ("Minuet", 1027), ("News Flash", 1028),
        ("Noir", 1029), ("Sherwood Forest", 1030), ("Spell", 1031),
        ("Suspense", 1032), ("Telegraph", 1033), ("Tiptoes", 1034),
        ("Typewriters", 1035), ("Update", 1036)
    ]

    static let all: [String: SettingsOption] = {
        let list: [SettingsOption] = [
            // Sounds
            SettingsOption(key: "Sounds.Ringtone", title: "Ringtone", choices: ringtones, defaultValue: "Marimba", header: "Ringtones", preview: .ringtone),
            SettingsOption(key: "Sounds.TextTone", title: "Text Tone", choices: textTones.map(\.0), defaultValue: "Tri-tone", header: "Alert Tones", preview: .textTone),
            // General › Auto-Lock
            SettingsOption(key: "General.AutoLock", title: "Auto-Lock", choices: ["1 Minute", "2 Minutes", "3 Minutes", "4 Minutes", "5 Minutes", "Never"], defaultValue: "Never"),
            // Mail, Contacts, Calendars
            SettingsOption(key: "Mail.Fetch", title: "Fetch New Data", choices: ["Push", "Every 15 Minutes", "Every 30 Minutes", "Hourly", "Manually"], defaultValue: "Push"),
            SettingsOption(key: "Mail.Show", title: "Show", choices: ["25 Recent Messages", "50 Recent Messages", "75 Recent Messages", "100 Recent Messages", "200 Recent Messages"], defaultValue: "50 Recent Messages"),
            SettingsOption(key: "Mail.Preview", title: "Preview", choices: ["None", "1 Line", "2 Lines", "3 Lines", "4 Lines", "5 Lines"], defaultValue: "2 Lines"),
            SettingsOption(key: "Mail.FontSize", title: "Minimum Font Size", choices: ["Small", "Medium", "Large", "Extra Large", "Giant"], defaultValue: "Medium"),
            SettingsOption(key: "Contacts.SortOrder", title: "Sort Order", choices: ["First, Last", "Last, First"], defaultValue: "Last, First"),
            SettingsOption(key: "Contacts.DisplayOrder", title: "Display Order", choices: ["First, Last", "Last, First"], defaultValue: "First, Last"),
            // Safari
            SettingsOption(key: "Safari.SearchEngine", title: "Search Engine", choices: ["Google", "Yahoo!", "Bing"], defaultValue: "Google"),
            SettingsOption(key: "Safari.Cookies", title: "Accept Cookies", choices: ["Never", "From visited", "Always"], defaultValue: "From visited"),
            // Messages
            SettingsOption(key: "Messages.AlertTone", title: "Play Alert Tone", choices: ["Never", "Once", "Twice", "3 Times", "5 Times", "10 Times"], defaultValue: "Twice"),
            // iPod
            SettingsOption(key: "iPod.EQ", title: "EQ", choices: ["Off", "Acoustic", "Bass Booster", "Bass Reducer", "Classical", "Dance", "Deep", "Electronic", "Flat", "Hip Hop", "Jazz", "Late Night", "Latin", "Loudness", "Lounge", "Piano", "Pop", "R&B", "Rock", "Small Speakers", "Spoken Word", "Treble Booster", "Treble Reducer", "Vocal Booster"], defaultValue: "Off"),
            SettingsOption(key: "iPod.VolumeLimit", title: "Volume Limit", choices: ["Off", "On"], defaultValue: "Off"),
            SettingsOption(key: "iPod.StartPlaying", title: "Start Playing", choices: ["Where Left Off", "From Beginning"], defaultValue: "Where Left Off"),
            SettingsOption(key: "iPod.TVSignal", title: "TV Signal", choices: ["NTSC", "PAL"], defaultValue: "NTSC"),
            // Photos
            SettingsOption(key: "Photos.SlideDuration", title: "Play Each Slide For", choices: ["2 Seconds", "3 Seconds", "5 Seconds", "10 Seconds", "20 Seconds"], defaultValue: "3 Seconds"),
            // Notes
            SettingsOption(key: "Notes.Font", title: "Notes", choices: ["Noteworthy", "Helvetica", "Marker Felt"], defaultValue: "Noteworthy", header: "Font"),
            // Phone
            SettingsOption(key: "Phone.ShowCallerID", title: "Show My Caller ID", choices: ["On", "Off"], defaultValue: "On")
        ]
        return Dictionary(uniqueKeysWithValues: list.map { ($0.key, $0) })
    }()

    static func route(_ key: String) -> String { "Option:\(key)" }
}
