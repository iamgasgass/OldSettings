import SwiftUI
import Photos

// OldOS Settings.swift wallpaper screens: `wallpaper_view`,
// `wallpaper_select_view`, `wallpaper_grid_view`(`_camera_roll`),
// `wallpaper_set_view`(`_camera_roll`), `wallpaper_header`, `wallpaper_footer`,
// `wallpaper_select_final` and the "Saving Photo" HUD, plus the
// `ImageMoveAndScale` cropper.

// MARK: - Wallpaper (`wallpaper_view`)

struct WallpaperView: View {
    @Environment(\.oldSettingsTheme) private var theme
    @EnvironmentObject private var navigator: SettingsNavigator
    @ObservedObject private var wallpapers = WallpaperStore.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            Button {
                navigator.push("Wallpaper_Select")
            } label: {
                ZStack {
                    HStack {
                        thumbnail(wallpapers.lock, overlay: "LockScreenOverlay")
                            .padding(.leading, 32)
                        Spacer()
                        thumbnail(wallpapers.home, overlay: "HomeScreenOverlay")
                            .padding(.trailing, 32)
                    }
                    HStack {
                        Spacer()
                        Image("TableNext").padding(.trailing, 12)
                    }
                }
                .padding([.top, .bottom], 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(SettingsRowButtonStyle())
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.cardFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.cardStroke, lineWidth: 1.25))
            .padding([.leading, .trailing], 12)
        }
        .onAppear { SettingsPhotosObserver.shared.fetch() }
    }

    private func thumbnail(_ image: UIImage, overlay: String) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 113, height: 164)
                .clipped()
            Image(overlay)
        }
    }
}

// MARK: - Choose (`wallpaper_select_view`)

struct WallpaperSelectView: View {
    @Environment(\.oldSettingsTheme) private var theme
    @EnvironmentObject private var navigator: SettingsNavigator
    @ObservedObject private var photos = SettingsPhotosObserver.shared

    var body: some View {
        SettingsPage {
            Spacer().frame(height: 12)
            card(title: "Wallpaper", image: UIImage(named: "Wallpaper21")) {
                navigator.push("Wallpaper_Grid")
            }
            Spacer().frame(height: 17)
            card(title: "Camera Roll", image: photos.lastPhoto) {
                navigator.push("Wallpaper_Grid_Camera_Roll")
            }
        }
        .onAppear { photos.fetch() }
    }

    private func card(title: String, image: UIImage?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Group {
                    if let image {
                        Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                    } else {
                        theme.groupedBackground
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(OldOSRoundedCorners(tl: 10, tr: 0, bl: 10, br: 0))
                .scaleEffect(0.985)
                Text(title)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(theme.listRowText)
                Spacer()
                Image("TableNext").padding(.trailing, 12)
            }
            .frame(height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.cardFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.cardStroke, lineWidth: 1.25))
        .padding([.leading, .trailing], 12)
    }
}

// MARK: - Grids

/// `wallpaper_grid_view`: the 27 iOS 6 wallpapers.
struct WallpaperGridView: View {
    @Environment(\.oldSettingsTheme) private var theme
    @EnvironmentObject private var navigator: SettingsNavigator

    private let columns = Array(repeating: GridItem(.flexible(minimum: 60), spacing: 5), count: 4)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(1...27, id: \.self) { number in
                    Button {
                        withAnimation {
                            navigator.wallpaperPreview = WallpaperChoice(bundled: "Wallpaper\(number)")
                        }
                    } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image("Wallpaper\(number)")
                                    .resizable()
                                    .scaledToFill()
                            )
                            .clipped()
                            .overlay(Rectangle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .background(theme.listBackground)
    }
}

/// `wallpaper_grid_view_camera_roll`: the photos, newest at the bottom,
/// with "N Photos".
struct CameraRollGridView: View {
    @Environment(\.oldSettingsTheme) private var theme
    @EnvironmentObject private var navigator: SettingsNavigator
    @ObservedObject private var photos = SettingsPhotosObserver.shared

    private let columns = Array(repeating: GridItem(.flexible(minimum: 60), spacing: 5), count: 4)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(0..<photos.assets.count, id: \.self) { index in
                        let asset = photos.assets.object(at: index)
                        Button {
                            photos.fullImage(for: asset) { image in
                                guard let image else { return }
                                withAnimation {
                                    navigator.wallpaperPreview = WallpaperChoice(image: image)
                                }
                            }
                        } label: {
                            AssetThumbnail(asset: asset)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                HStack {
                    Spacer()
                    Text(photos.authorized ? "\(photos.assets.count) Photos" : "No Access to Photos")
                        .font(OldOSFont.regular(20))
                        .foregroundColor(.oldOSLightGray)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.bottom, 12)
                .id("bottom_info")
            }
            .onAppear {
                photos.fetch()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { proxy.scrollTo("bottom_info", anchor: .bottom) }
            }
            .onChange(of: photos.assets.count) { _ in proxy.scrollTo("bottom_info", anchor: .bottom) }
        }
        .background(theme.listBackground)
    }
}

/// One Camera Roll thumbnail (OldOS `PhotoLibraryImageView`).
struct AssetThumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
            )
            .clipped()
            .overlay(Rectangle().stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
            .onAppear {
                SettingsPhotosObserver.shared.thumbnail(for: asset, side: 90) { image = $0 }
            }
    }
}

// MARK: - Preview (`wallpaper_set_view` / `_camera_roll`)

struct WallpaperPreviewView: View {
    @EnvironmentObject private var navigator: SettingsNavigator
    let choice: WallpaperChoice
    let topInset: CGFloat
    let bottomInset: CGFloat

    @State private var showSelectFinal = false
    @State private var showOverlay = false
    @State private var showCheck = false
    @State private var zoom: CGFloat = 1
    @State private var pinch: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var dragStart: CGSize = .zero

    private var image: UIImage {
        if let name = choice.bundled { return UIImage(named: name) ?? UIImage() }
        return choice.image ?? UIImage()
    }

    private var movable: Bool { choice.bundled == nil }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Color.black

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: displaySize(in: size).width, height: displaySize(in: size).height)
                    .offset(offset)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .gesture(moveAndScale(in: size))
                    .onTapGesture(count: 2) {
                        guard movable else { return }
                        withAnimation(.easeInOut) {
                            zoom = 1
                            offset = .zero
                            dragStart = .zero
                        }
                    }

                // The dark fade behind the footer.
                VStack {
                    Spacer()
                    LinearGradient(oldOS: choice.bundled == "Wallpaper1"
                        ? [Color.oldOS(158, 158, 158).opacity(0), Color.oldOS(34, 34, 34)]
                        : [Color.oldOS(34, 34, 34).opacity(0), Color.oldOS(24, 24, 24).opacity(0.85)])
                        .frame(height: size.height / 4.25)
                }
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    WallpaperHeader(title: movable ? "Move and Scale" : "Wallpaper Preview", topInset: topInset)
                    Spacer()
                    WallpaperFooter(bottomInset: bottomInset, onCancel: {
                        withAnimation { navigator.wallpaperPreview = nil }
                    }, onSet: {
                        withAnimation(.linear(duration: 0.4)) { showSelectFinal = true }
                    })
                }

                if showSelectFinal {
                    VStack(spacing: 0) {
                        Spacer()
                        WallpaperSelectFinal(bottomInset: bottomInset, onSet: { targets in
                            set(targets, size: size)
                        }, onCancel: {
                            withAnimation(.linear(duration: 0.4)) { showSelectFinal = false }
                        })
                        .frame(height: max(size.height / 2, 300))
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }

                if showOverlay {
                    SavingPhotoHUD(done: showCheck)
                        .zIndex(2)
                }
            }
            .disabled(showOverlay)
        }
        .ignoresSafeArea()
    }

    // MARK: Move and scale (`ImageMoveAndScale`)

    private func fillScale(in size: CGSize) -> CGFloat {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return 1 }
        return max(size.width / imageSize.width, size.height / imageSize.height)
    }

    private func displaySize(in size: CGSize) -> CGSize {
        let scale = fillScale(in: size) * zoom * pinch
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    private func clamped(_ proposed: CGSize, in size: CGSize) -> CGSize {
        let display = displaySize(in: size)
        let maxX = max((display.width - size.width) / 2, 0)
        let maxY = max((display.height - size.height) / 2, 0)
        return CGSize(width: min(max(proposed.width, -maxX), maxX), height: min(max(proposed.height, -maxY), maxY))
    }

    private func moveAndScale(in size: CGSize) -> some Gesture {
        let drag = DragGesture()
            .onChanged { value in
                guard movable else { return }
                offset = clamped(CGSize(width: dragStart.width + value.translation.width, height: dragStart.height + value.translation.height), in: size)
            }
            .onEnded { _ in
                dragStart = offset
            }
        let magnify = MagnificationGesture()
            .onChanged { amount in
                guard movable else { return }
                pinch = amount
            }
            .onEnded { amount in
                guard movable else { return }
                zoom = min(max(zoom * amount, 1), 4)
                pinch = 1
                withAnimation(.easeInOut) {
                    offset = clamped(offset, in: size)
                }
                dragStart = offset
            }
        return drag.simultaneously(with: magnify)
    }

    /// The visible part of the photo, as the wallpaper image.
    private func croppedImage(in size: CGSize) -> UIImage {
        guard movable else { return image }
        let scale = fillScale(in: size) * zoom
        let display = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = ((display.width - size.width) / 2 - offset.width) / scale
        let y = ((display.height - size.height) / 2 - offset.height) / scale
        let crop = CGRect(x: x, y: y, width: size.width / scale, height: size.height / scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: crop.size, format: format)
        return renderer.image { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(origin: .zero, size: crop.size))
            image.draw(at: CGPoint(x: -crop.origin.x, y: -crop.origin.y))
        }
    }

    // MARK: Set (`wallpaper_select_final`)

    private func set(_ targets: [WallpaperStore.Target], size: CGSize) {
        let final = croppedImage(in: size)
        showOverlay = true
        withAnimation(.linear(duration: 0.4)) { showSelectFinal = false }
        let started = Date()
        WallpaperStore.shared.set(choice, image: final, targets: targets) { _ in
            // OldOS showed the spinner for 1.25 s, the check, then closed at 2 s.
            let wait = max(0, 1.25 - Date().timeIntervalSince(started))
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                showCheck = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation { navigator.wallpaperPreview = nil }
                }
            }
        }
    }
}

/// `wallpaper_header` / `wallpaper_header_camera_roll`.
struct WallpaperHeader: View {
    let title: String
    let topInset: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.65)
                .overlay(
                    LinearGradient(oldOS: [Color.white.opacity(0.21), Color.white.opacity(0.085)])
                        .frame(height: 55),
                    alignment: .top
                )
                .oldOSBorder(width: 0.75, edges: [.top, .bottom], color: .black)
            Text(title)
                .foregroundColor(.white)
                .font(OldOSFont.bold(title == "Move and Scale" ? 22 : 24))
                .shadow(color: Color.black.opacity(0.92), radius: 0, x: 0, y: -1.2)
                .frame(height: 86)
        }
        .frame(height: topInset + 86)
    }
}

/// `wallpaper_footer`: Cancel (black) and Set (silver).
struct WallpaperFooter: View {
    let bottomInset: CGFloat
    let onCancel: () -> Void
    let onSet: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                LinearGradient(oldOS: [Color.oldOS(41, 40, 40).opacity(0.6), Color.oldOS(21, 20, 20).opacity(0.65)])
                    .oldOSInnerShadowBottom(color: Color.white.opacity(0.6), radius: 0.05)
                    .oldOSBorder(width: 1, edges: [.top], color: .black)
                Color.black.opacity(0.835)
            }
            HStack(spacing: 20) {
                SheetButton(title: "Cancel", style: .black, action: onCancel)
                    .padding(.leading, 25)
                SheetButton(title: "Set", style: .silver, action: onSet)
                    .padding(.trailing, 25)
            }
            .padding(.vertical, 28)
        }
        .frame(height: 110 + bottomInset)
    }
}

/// `wallpaper_select_final`: Set Lock Screen / Set Home Screen / Set Both / Cancel.
struct WallpaperSelectFinal: View {
    let bottomInset: CGFloat
    let onSet: ([WallpaperStore.Target]) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                LinearGradient(oldOS: [Color.oldOS(101, 100, 100).opacity(0.88), Color.oldOS(31, 30, 30).opacity(0.88)])
                    .oldOSInnerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1)
                    .oldOSBorder(width: 1, edges: [.top], color: .black)
                    .frame(height: 30)
                LinearGradient(oldOS: [Color.oldOS(21, 20, 20).opacity(0.88), Color.black.opacity(0.9)])
            }
            VStack(spacing: 5) {
                SheetButton(title: "Set Lock Screen", style: .silver) { onSet([.lock]) }
                    .padding(.top, 28)
                SheetButton(title: "Set Home Screen", style: .silver) { onSet([.home]) }
                SheetButton(title: "Set Both", style: .silver) { onSet([.lock, .home]) }
                Spacer()
                SheetButton(title: "Cancel", style: .black, dimmed: true, action: onCancel)
                    .padding(.bottom, 25 + bottomInset)
            }
            .padding(.horizontal, 25)
        }
    }
}

/// The black / silver iOS 6 sheet button (`wallpaper_footer`, `delete_note_view`).
struct SheetButton: View {
    enum Style {
        case black, silver
    }

    let title: String
    let style: Style
    var dimmed = false
    let action: () -> Void

    var body: some View {
        Button {
            OldSettingsHaptics.tap()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(oldOS: [.oldOS(3, 3, 3), .oldOS(21, 21, 21), .oldOS(32, 32, 32)]))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient(oldOS: [.oldOS(83, 83, 83), .oldOS(143, 143, 143)]), lineWidth: 0.5)
                    )
                    .opacity(dimmed ? 0.6 : 1)
                if style == .silver {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(oldOS: [
                            OldOSStop(.oldOS(235, 235, 236), 0),
                            OldOSStop(.oldOS(208, 209, 211), 0.52),
                            OldOSStop(.oldOS(192, 193, 196), 0.52),
                            OldOSStop(.oldOS(192, 193, 196), 1)
                        ]))
                        .oldOSAddBorder(LinearGradient(oldOS: [Color.white.opacity(0.9), Color.white.opacity(0.25)]), width: 0.4, cornerRadius: 9)
                        .padding(3)
                    Text(title)
                        .font(OldOSFont.bold(18))
                        .foregroundColor(.black)
                        .shadow(color: Color.white.opacity(0.9), radius: 0, x: 0, y: 0.9)
                } else {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(oldOS: [
                            OldOSStop(.oldOS(124, 124, 124), 0),
                            OldOSStop(.oldOS(26, 26, 26), 0.50),
                            OldOSStop(.oldOS(0, 0, 0), 0.53),
                            OldOSStop(.oldOS(0, 0, 0), 1)
                        ]))
                        .oldOSAddBorder(LinearGradient(oldOS: [Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), width: 0.4, cornerRadius: 9)
                        .padding(3)
                        .opacity(dimmed ? 0.6 : 1)
                    Text(title)
                        .font(OldOSFont.bold(18))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: -0.9)
                }
            }
            .frame(minHeight: 50, maxHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The "Saving Photo" HUD (spinner, then the check mark).
struct SavingPhotoHUD: View {
    let done: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.65))
            VStack {
                if done {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 26, weight: .bold))
                        .padding(.top, 9)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.75)
                        .padding(.bottom, 5)
                        .padding(.top, 10)
                }
                Text("Saving Photo")
                    .foregroundColor(.white)
                    .font(OldOSFont.bold(24))
                    .padding(.bottom, 2.5)
                    .padding(.top, 8)
            }
        }
        .frame(width: 200, height: 115)
    }
}
