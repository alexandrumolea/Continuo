import SwiftUI
import UIKit

// MARK: - Haptic feedback helpers
enum HapticFeedback {
    static func light()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()    { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success()   { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// MARK: - Glass card container
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    let content: Content

    init(cornerRadius: CGFloat = 20, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(hex: "EDE8E0"), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "2D2926").opacity(0.06), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Background glow orbs
struct BackgroundOrbs: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ContinuoTheme.sunYellow.opacity(0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: 130, y: -160)

            Circle()
                .fill(ContinuoTheme.olive.opacity(0.07))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -130, y: 340)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Press scale button style (works outside ScrollView — PrimaryButton etc.)
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - Pressable card modifier (reliable inside horizontal ScrollView)
struct PressableCard: ViewModifier {
    var scale: CGFloat = 0.94
    var action: () -> Void
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .brightness(isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
            )
            .onTapGesture { HapticFeedback.light(); action() }
    }
}

extension View {
    func pressableCard(scale: CGFloat = 0.94, action: @escaping () -> Void) -> some View {
        modifier(PressableCard(scale: scale, action: action))
    }
}

// MARK: - Orange primary button
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(ContinuoTheme.rounded(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ContinuoTheme.sunOrange)
                    .shadow(color: ContinuoTheme.sunOrange.opacity(0.45), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .disabled(isLoading)
    }
}

// MARK: - Icon badge
struct TierBadge: View {
    let tier: SkillTier

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tier.icon)
                .font(.caption2)
            Text(tier.rawValue)
                .font(ContinuoTheme.rounded(10, weight: .semibold))
        }
        .foregroundColor(tier.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(tier.color.opacity(0.12))
        )
    }
}

// MARK: - Smooth progress bar
struct ContinuoProgressBar: View {
    var progress: Double          // 0.0 → 1.0
    var color: Color = ContinuoTheme.sunOrange
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.06))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progress)
            }
        }
        .frame(height: height)
    }
}
