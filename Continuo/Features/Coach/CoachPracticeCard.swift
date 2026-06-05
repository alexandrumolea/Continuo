import SwiftUI

struct CoachPracticeCard: View {
    let practice: CoachPractice
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(practice.emoji)
                            .font(.system(size: 28))
                        Text(practice.title)
                            .font(ContinuoTheme.rounded(15, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                }

                Spacer(minLength: 12)

                Text(practice.subtitle)
                    .font(ContinuoTheme.rounded(12))
                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.65))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 16)

                HStack(spacing: 8) {
                    Text("Coaching Toolkit")
                        .font(ContinuoTheme.rounded(11))
                        .foregroundColor(ContinuoTheme.charcoal.opacity(0.5))
                    Spacer()
                    Text(practice.category)
                        .font(ContinuoTheme.rounded(11, weight: .semibold))
                        .foregroundColor(practice.categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(practice.categoryColor.opacity(0.12)))
                }
            }
            .padding(16)
            .frame(width: 200, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(practice.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(practice.categoryColor.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.96))
    }
}
