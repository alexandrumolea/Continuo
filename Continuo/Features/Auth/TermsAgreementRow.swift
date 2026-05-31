import SwiftUI

/// Required GDPR-style consent checkbox shown during account creation (email signup
/// and the post-social-auth welcome flow). The Terms / Privacy text uses Markdown so
/// each phrase becomes a tappable link that opens the public docs.
///
/// `showError` flips on when the parent view detects a submit attempt without consent;
/// it self-clears as soon as the user ticks the box.
struct TermsAgreementRow: View {
    @Binding var agreed: Bool
    @Binding var showError: Bool

    init(agreed: Binding<Bool>, showError: Binding<Bool> = .constant(false)) {
        self._agreed = agreed
        self._showError = showError
    }

    private var errorVisible: Bool { showError && !agreed }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    HapticFeedback.selection()
                    withAnimation(.easeInOut(duration: 0.12)) { agreed.toggle() }
                } label: {
                    Image(systemName: agreed ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(boxColor)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // String literal → SwiftUI parses it as LocalizedStringKey,
                // which renders Markdown links inline.
                Text("I have read and agree to the [Terms of Service](https://alexandrumolea.github.io/Continuo/terms/) and [Privacy Policy](https://alexandrumolea.github.io/Continuo/).")
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.textMedium)
                    .tint(ContinuoTheme.terracotta)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }

            if errorVisible {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Please accept the Terms and Privacy Policy to continue.")
                        .font(ContinuoTheme.rounded(12, weight: .medium))
                }
                .foregroundColor(.red)
                .padding(.leading, 44)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .onChange(of: agreed) { _, newValue in
            if newValue && showError {
                withAnimation(.easeOut(duration: 0.2)) { showError = false }
            }
        }
    }

    private var boxColor: Color {
        if agreed { return ContinuoTheme.olive }
        if errorVisible { return .red }
        return ContinuoTheme.textLight
    }
}

#Preview {
    @Previewable @State var agreed = false
    @Previewable @State var showError = true
    return TermsAgreementRow(agreed: $agreed, showError: $showError)
        .padding()
}
