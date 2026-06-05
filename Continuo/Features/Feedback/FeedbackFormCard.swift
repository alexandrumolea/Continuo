import SwiftUI

struct FeedbackFormCard: View {
    let form: FeedbackForm
    let clientName: String
    let userId: String

    @State private var showForm = false

    var body: some View {
        Button { showForm = true } label: {
            GlassCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ContinuoTheme.terracotta.opacity(0.10))
                            .frame(width: 48, height: 48)
                        Text("💬").font(.system(size: 24))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coach asked for feedback.")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("\(form.questionCount) question\(form.questionCount == 1 ? "" : "s") · \(form.date, style: .relative)")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ContinuoTheme.textLight)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .sheet(isPresented: $showForm) {
            FeedbackFormView(form: form, clientName: clientName, userId: userId)
                .presentationDetents([.large])
        }
    }
}
