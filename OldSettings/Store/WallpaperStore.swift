import SwiftUI
import Photos

/// The Lock Screen / Home Screen wallpapers (OldOS `Lock_Wallpaper`,
/// `Home_Wallpaper`, `Camera_Wallpaper_*`). An app cannot change the iOS
/// wallpaper, so "Set" also saves the picture to the Camera Roll, ready for
/// Photos › Share › Use as Wallpaper.
final class WallpaperStore: ObservableObject {
    static let shared = WallpaperStore()

    enum Target {
        case lock, home
    }

    @Published private(set) var lock: UIImage
    @Published private(set) var home: UIImage

    private init() {
        lock = Self.load(.lock) ?? UIImage(named: "Wallpaper1") ?? UIImage()
        home = Self.load(.home) ?? UIImage(named: "Wallpaper1") ?? UIImage()
    }

    private static func defaultsKey(_ target: Target) -> String {
        target == .lock ? "Lock_Wallpaper" : "Home_Wallpaper"
    }

    private static func fileURL(_ target: Target) -> URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(target == .lock ? "LockWallpaper.jpg" : "HomeWallpaper.jpg")
    }

    private static func load(_ target: Target) -> UIImage? {
        let defaults = UserDefaults.standard
        if let name = defaults.string(forKey: defaultsKey(target)), let image = UIImage(named: name) {
            return image
        }
        if let data = try? Data(contentsOf: fileURL(target)) {
            return UIImage(data: data)
        }
        return nil
    }

    /// Sets the wallpaper (a bundled name, or a cropped photo) and saves it to
    /// the Camera Roll. `completion(true)` once saved.
    func set(_ choice: WallpaperChoice, image: UIImage, targets: [Target], completion: @escaping (Bool) -> Void) {
        let defaults = UserDefaults.standard
        for target in targets {
            if let name = choice.bundled {
                defaults.set(name, forKey: Self.defaultsKey(target))
            } else {
                defaults.removeObject(forKey: Self.defaultsKey(target))
                try? image.jpegData(compressionQuality: 0.92)?.write(to: Self.fileURL(target))
            }
            switch target {
            case .lock: lock = image
            case .home: home = image
            }
        }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, _ in
                DispatchQueue.main.async { completion(success) }
            })
        }
    }
}

/// The Camera Roll for the wallpaper grid (OldOS `SettingsPhotosObserver`).
final class SettingsPhotosObserver: ObservableObject {
    static let shared = SettingsPhotosObserver()

    @Published private(set) var assets: PHFetchResult<PHAsset> = PHFetchResult()
    @Published private(set) var lastPhoto: UIImage?
    @Published private(set) var authorized = false

    let imageManager = PHCachingImageManager()

    func fetch() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.authorized = status == .authorized || status == .limited
                guard self.authorized else { return }
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                self.assets = PHAsset.fetchAssets(with: options)
                if let last = self.assets.lastObject {
                    self.thumbnail(for: last, side: 120) { self.lastPhoto = $0 }
                }
            }
        }
    }

    func thumbnail(for asset: PHAsset, side: CGFloat, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        let scale = UIScreen.main.scale
        imageManager.requestImage(for: asset, targetSize: CGSize(width: side * scale, height: side * scale), contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }

    /// OldOS `getMainImage`: the full photo, for Move and Scale.
    func fullImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        let screen = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let target = CGSize(width: screen.width * scale * 2, height: screen.height * scale * 2)
        imageManager.requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: options) { image, info in
            let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if !degraded { DispatchQueue.main.async { completion(image) } }
        }
    }
}
