import SwiftUI

/// OldOS `CustomSlider` with the Settings skin (`sounds_slider_content`,
/// `brightness_slider_content`): the blue filled track, the grey track and
/// the white round knob with its highlight. `value` goes from 0 to 100.
struct OldOSSlider: View {
    @Binding var value: Double
    var onChange: ((Double) -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let knob = geometry.size.height
            let travel = max(geometry.size.width - knob, 1)
            let x = CGFloat(min(max(value, 0), 100) / 100) * travel

            ZStack(alignment: .leading) {
                // Right (empty) track.
                LinearGradient(oldOS: [OldOSStop(.oldOS(180, 180, 180), 0), OldOSStop(.oldOS(250, 250, 250), 0.55)])
                    .overlay(
                        LinearGradient(oldOS: [Color.black.opacity(0.21), Color.clear])
                            .frame(height: 3),
                        alignment: .top
                    )
                    .frame(height: 8.5)
                    .cornerRadius(4.25)
                    .overlay(RoundedRectangle(cornerRadius: 4.25).stroke(Color.gray, lineWidth: 0.25))

                // Left (filled) track.
                LinearGradient(oldOS: [.oldOS(47, 100, 183), .oldOS(119, 173, 246)])
                    .overlay(
                        LinearGradient(oldOS: [Color.oldOS(17, 63, 139).opacity(0.5), Color.clear])
                            .frame(height: 3),
                        alignment: .top
                    )
                    .frame(width: x + knob / 2, height: 8.5)
                    .cornerRadius(4.25)
                    .overlay(RoundedRectangle(cornerRadius: 4.25).stroke(Color.gray, lineWidth: 0.25))

                // Knob.
                ZStack {
                    Circle()
                        .fill(LinearGradient(oldOS: [.oldOS(166, 166, 166), .oldOS(252, 252, 252)]))
                        .shadow(color: Color.black.opacity(0.56), radius: 1, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .trim(from: 0.05, to: 0.45)
                                .stroke(Color.white.opacity(0.8), lineWidth: 0.4)
                                .scaleEffect(0.96)
                                .rotationEffect(.degrees(-180))
                                .blur(radius: 0.35)
                        )
                    Circle().stroke(Color.gray, lineWidth: 0.25)
                }
                .frame(width: knob, height: knob)
                .offset(x: x)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let position = min(max(drag.location.x - knob / 2, 0), travel)
                        let newValue = Double(position / travel) * 100
                        value = newValue
                        onChange?(newValue)
                    }
            )
        }
        .frame(height: 21)
    }
}
