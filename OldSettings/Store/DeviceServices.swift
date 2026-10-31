import SwiftUI
import Combine
import Network
import NetworkExtension
import AVFoundation
import MediaPlayer
import CoreBluetooth
import CoreLocation
import Photos
import AudioToolbox

// The real device behind the iOS 6 screens: what an app on a recent iOS can
// read or change (volume, brightness, Wi-Fi status, Bluetooth devices
// nearby, location access, storage, the iOS version…).

// MARK: - Wi-Fi (OldOS `getWiFiSsid`)

final class WiFiStatus: ObservableObject {
    static let shared = WiFiStatus()

    @Published private(set) var connected = false
    /// The network name, when iOS gives it to the app.
    @Published private(set) var ssid: String?

    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let wifi = path.status == .satisfied && path.usesInterfaceType(.wifi)
            DispatchQueue.main.async {
                self?.connected = wifi
                self?.refreshSSID()
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.iamgasgass.oldsettings.wifi"))
    }

    func refreshSSID() {
        guard connected else {
            ssid = nil
            return
        }
        NEHotspotNetwork.fetchCurrent { [weak self] network in
            DispatchQueue.main.async {
                self?.ssid = network?.ssid
            }
        }
    }

    /// `wifi_content`: the network name, "Connected" or "Not Connected".
    var statusText: String {
        if let ssid, !ssid.isEmpty { return ssid }
        return connected ? "Connected" : "Not Connected"
    }
}

// MARK: - Volume (OldOS `VolumeObserver` + `MPVolumeView.setVolume`)

final class VolumeObserver: ObservableObject {
    static let shared = VolumeObserver()

    @Published var volume: Double = Double(AVAudioSession.sharedInstance().outputVolume) * 100

    private var observation: NSKeyValueObservation?
    /// An off-screen `MPVolumeView` whose slider changes the system volume.
    let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 10, height: 10))

    private init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        volume = Double(session.outputVolume) * 100
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, _ in
            DispatchQueue.main.async {
                self?.volume = Double(session.outputVolume) * 100
            }
        }
    }

    func setVolume(_ value: Double) {
        let slider = volumeView.subviews.compactMap { $0 as? UISlider }.first
        DispatchQueue.main.async {
            slider?.value = Float(value / 100)
        }
    }
}

/// Puts the `MPVolumeView` in the window (needed for it to work, and it
/// hides the system volume HUD while the slider is used).
struct VolumeViewHost: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.isUserInteractionEnabled = false
        container.alpha = 0.01
        container.addSubview(VolumeObserver.shared.volumeView)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Brightness (OldOS `BrightnessObserver`)

final class BrightnessObserver: ObservableObject {
    static let shared = BrightnessObserver()

    @Published var brightness: Double = Double(UIScreen.main.brightness) * 100
    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(forName: UIScreen.brightnessDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.brightness = Double(UIScreen.main.brightness) * 100
        }
    }

    func setBrightness(_ value: Double) {
        UIScreen.main.brightness = CGFloat(value / 100)
    }
}

// MARK: - Bluetooth (General › Bluetooth: "Searching...")

final class BluetoothScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    static let shared = BluetoothScanner()

    struct Device: Identifiable, Equatable {
        let id: UUID
        var name: String
    }

    @Published private(set) var poweredOn = false
    @Published private(set) var unauthorized = false
    @Published private(set) var devices: [Device] = []

    private var central: CBCentralManager?
    private var wantsScan = false

    func start() {
        wantsScan = true
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main)
        } else if central?.state == .poweredOn {
            central?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }

    func stop() {
        wantsScan = false
        central?.stopScan()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        poweredOn = central.state == .poweredOn
        unauthorized = central.state == .unauthorized
        if poweredOn, wantsScan {
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else if !poweredOn {
            devices = []
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        guard let name, !name.isEmpty else { return }
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[index].name = name
        } else {
            devices.append(Device(id: peripheral.identifier, name: name))
            devices.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}

// MARK: - Location Services

final class LocationStatus: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationStatus()

    @Published private(set) var servicesEnabled = true
    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override private init() {
        super.init()
        manager.delegate = self
        authorization = manager.authorizationStatus
        refresh()
    }

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let enabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async { self.servicesEnabled = enabled }
        }
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        refresh()
    }

    /// `location_content`: "On" / "Off".
    var isOn: Bool {
        servicesEnabled && authorization != .denied && authorization != .restricted
    }
}

// MARK: - Device info (General › About)

enum DeviceInfo {
    /// "iPhone15,2".
    static var machine: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: max(size, 1))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let value = String(cString: machine)
        return value.isEmpty ? UIDevice.current.model : value
    }

    /// The build ("22A3354").
    static var build: String {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var build = [CChar](repeating: 0, count: max(size, 1))
        sysctlbyname("kern.osversion", &build, &size, nil, 0)
        return String(cString: build)
    }

    /// iOS 6 style "18.1 (22B83)".
    static var version: String {
        let build = self.build
        return build.isEmpty ? UIDevice.current.systemVersion : "\(UIDevice.current.systemVersion) (\(build))"
    }

    static var totalSpace: String {
        ByteCountFormatter.string(fromByteCount: space(.systemSize), countStyle: .file)
    }

    static var freeSpace: String {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let important = values.volumeAvailableCapacityForImportantUsage {
            return ByteCountFormatter.string(fromByteCount: important, countStyle: .file)
        }
        return ByteCountFormatter.string(fromByteCount: space(.systemFreeSize), countStyle: .file)
    }

    private static func space(_ key: FileAttributeKey) -> Int64 {
        let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        return (attributes?[key] as? NSNumber)?.int64Value ?? 0
    }
}

/// Songs / Videos / Photos counts of About (OldOS showed "0").
final class MediaCounts: ObservableObject {
    static let shared = MediaCounts()

    @Published private(set) var songs: String = "0"
    @Published private(set) var videos: String = "0"
    @Published private(set) var photos: String = "0"

    func refresh() {
        MPMediaLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            let songs = MPMediaQuery.songs().items?.count ?? 0
            let videoQuery = MPMediaQuery()
            videoQuery.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.anyVideo.rawValue, forProperty: MPMediaItemPropertyMediaType, comparisonType: .contains))
            let videos = videoQuery.items?.count ?? 0
            DispatchQueue.main.async {
                self.songs = "\(songs)"
                self.videos = "\(videos)"
            }
        }
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else { return }
            let photos = PHAsset.fetchAssets(with: .image, options: nil).count
            let videos = PHAsset.fetchAssets(with: .video, options: nil).count
            DispatchQueue.main.async {
                self.photos = "\(photos)"
                if self.videos == "0" { self.videos = "\(videos)" }
            }
        }
    }
}

// MARK: - Sounds

enum SettingsSounds {
    /// Ringtone preview (the OldClock synthesised tones).
    private static var player: AVAudioPlayer?

    static func playRingtone(_ name: String) {
        let file = name.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        guard let url = Bundle.main.url(forResource: file, withExtension: "caf") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        player?.stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    static func playTextTone(_ name: String) {
        guard let id = SettingsOptions.textTones.first(where: { $0.0 == name })?.1, id != 0 else { return }
        AudioServicesPlaySystemSound(SystemSoundID(id))
    }

    static func stop() {
        player?.stop()
        player = nil
    }

    static func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

// MARK: - Random identifiers (OldOS `randomString` / `randomNumberString`)

func randomString(length: Int) -> String {
    let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
}

func randomNumberString(length: Int) -> String {
    let letters = "0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
}
