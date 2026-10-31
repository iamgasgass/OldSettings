# OldSettings

> A standalone, modern iOS rebuild of the **Settings** app from **The OldOS Project**. It keeps the iOS 6 pinstripes, the blue bar and the ON / OFF switches, and runs full screen on current iPhones and iPads with iOS 16 or later.

[![iOS](https://img.shields.io/badge/iOS-16.0%2B-0A84FF?logo=apple&logoColor=white)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)](#architecture)
[![Build](https://img.shields.io/github/actions/workflow/status/iamgasgass/OldSettings/build.yml?branch=main&label=build)](https://github.com/iamgasgass/OldSettings/actions)
[![License](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey)](#license-and-attribution)

## Features

Every screen of OldOS `Settings.swift` is included, with the same rows, sections, footers and pinstriped grouped tables. Two things changed from OldOS:

- every switch and value is **saved** (OldOS forgot them when leaving a screen);
- the value rows open their **iOS 6 check-mark lists** (OldOS drew an arrow that went nowhere).

Where iOS lets an app read or change the real device, the screen does.

| Screen | What works |
| --- | --- |
| **Airplane Mode** | Orange switch (saved; iOS does not let apps change it) |
| **Wi-Fi** | Real status ("Connected" / "Not Connected"), the current network row with lock / bars / ⓘ, "Other...", *Ask to Join Networks*; turning Wi-Fi off hides the list, as on iOS 6 |
| **Notifications** | Switch, On / Off on the home row |
| **Location Services** | Real status of Location Services; the switch asks for access or opens iOS Settings; Camera switch |
| **Carrier** | Automatic ✓ |
| **Sounds** | Vibrate switches (they vibrate); **Ringer and Alerts slider = the real system volume** (follows the volume buttons); *Ringtone* (25 tones, each plays a preview); *Text Tone* (the real iOS alert tones: Tri-tone, Chime, Glass…); the other sound switches |
| **Brightness** | **Real screen brightness** slider, Auto-Brightness |
| **Wallpaper** | Lock / Home previews → *Wallpaper* (the 27 OldOS wallpapers) or *Camera Roll* → full-screen preview (*Move and Scale* for photos) → **Set Lock Screen / Set Home Screen / Set Both** → "Saving Photo". Apps cannot change the iOS wallpaper, so the picture is also saved to your Camera Roll, ready for Photos › Share › Use as Wallpaper |
| **General › About** | Real songs / videos / photos counts, capacity, available space, **iOS version and build**, model identifier; serial, addresses, IMEI, ICCID stay random as in OldOS but no longer change on every redraw; *Legal*, *Regulatory* |
| **General › Usage** | Battery Percentage; Standby shows the time since the device started |
| **General › Network** | 3G, Cellular Data, Data Roaming (with the iOS 6 footers), VPN, Wi-Fi |
| **General › Bluetooth** | **Real scan**: the Bluetooth devices nearby appear under "Devices" with "Searching..." |
| **General › Auto-Lock** | 1–5 Minutes / Never; *Never* keeps the screen on while OldSettings is open |
| **General › Date & Time** | 24-Hour Time (starts from the device setting), Set Automatically (off shows Time Zone and the date) |
| **General › Keyboard, International, Accessibility** | Keyboard switches; **real language, region, calendar, keyboard count and region format example**; real VoiceOver / Large Text values |
| **Mail, Contacts, Calendars** | Fetch New Data, Show, Preview, Minimum Font Size, Sort / Display Order (lists), Signature (editable), the switches |
| **Phone, Safari, Messages, iPod, Photos, Notes, Store, Nike + iPod** | Every row of OldOS: Search Engine, Accept Cookies, Play Alert Tone, EQ, Start Playing, TV Signal, Play Each Slide For, Notes font, … |

### Appearance and full screen

- **Aspect UI** in Settings › OldSettings: *Sistema*, *Chiaro* or *Scuro*. Scuro uses OldSafari's Private graphite palette.
- **Full screen** like OldSafari: the blue bar extends behind the status bar / Dynamic Island and the pinstripes behind the home indicator.
- The wallpaper preview covers the whole screen.
- Portrait only, as on iOS 6.

### Notes

- **Ringtone previews:** they use the original synthesised tones of OldClock, because the iOS 6 ringtone audio cannot be redistributed.
- **Text tones:** they are the system alert sounds iOS still ships.
- **Wi-Fi name:** iOS gives the network name only to apps with a special entitlement, so an unsigned build shows "Connected".

## Requirements

- iOS / iPadOS 16.0 or later.
- Xcode 16 and [XcodeGen](https://github.com/yonaskolb/XcodeGen) to build.

## Build

```sh
brew install xcodegen
xcodegen generate --spec project.yml
open OldSettings.xcodeproj
```

The GitHub Actions workflow (`.github/workflows/build.yml`) generates the project, builds it without signing and uploads an unsigned IPA (`OldSettings-Unsigned-IPA`).

## Architecture

| File | Role |
| --- | --- |
| `OldSettingsApp.swift` | App / scene delegate, status bar |
| `Views/OldSettingsRootView.swift` | Title bar, sliding screens (OldOS `switch current_nav_view`), wallpaper preview |
| `Views/SettingsChrome.swift` | `title_bar`, back button, pinstripes (`settings_main_list`), headers, footers |
| `Views/SettingsList.swift` | `list_row`, `list_section` (+ `_blue`, `_oversize`, `_content_only`), row contents |
| `Views/OldOSToggle.swift`, `Views/OldOSSlider.swift` | OldOS `toggle` / `toggle_orange`, `CustomSlider` |
| `Views/SettingsHomeViews.swift` | Home, Wi-Fi, Notifications, Location Services, Carrier, Sounds, Brightness |
| `Views/WallpaperViews.swift` | Wallpaper screens, preview, Move and Scale, Set sheet, Saving Photo |
| `Views/GeneralViews.swift` | General and its screens |
| `Views/AppSettingsViews.swift` | Mail / Contacts / Calendars, app pages, check-mark lists, Signature |
| `Models/SettingsOptions.swift` | The value lists (iOS 6 choices) |
| `Store/SettingsStore.swift`, `Store/SettingsNavigator.swift` | Saved values, navigation stack and titles |
| `Store/DeviceServices.swift` | Wi-Fi, volume, brightness, Bluetooth, location, device info, sounds |
| `Store/WallpaperStore.swift` | Wallpapers and the Camera Roll |
| `Store/AppearanceSettings.swift`, `Settings.bundle` | Aspect UI |

There are no third-party dependencies: OldOS PureSwiftUI, LocationProvider and the PhotoCropper were replaced with native code.

## License and attribution

Derived from [The OldOS Project](https://github.com/zzanehip/The-OldOS-Project) by Zane Kleinberg, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See `LICENSE` and `EXTRACTION.json`.
