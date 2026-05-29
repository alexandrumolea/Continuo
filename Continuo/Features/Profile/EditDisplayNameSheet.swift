import SwiftUI

/// Bottom sheet for changing the display name from Profile → Edit name.
struct EditDisplayNameSheet: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var isSaving = false
    @FocusState private var nameFocused: Bool

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed != (auth.profile?.displayName ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                VStack(spacing: 24) {
                    Text("Edit your name")
                        .font(ContinuoTheme.rounded(20, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .padding(.top, 12)

                    AuthField(icon: "person.fill", placeholder: "Display name", text: $name)
                        .focused($nameFocused)
                        .padding(.horizontal, 24)

                    PrimaryButton(title: isSaving ? "Saving…" : "Save", isLoading: isSaving) {
                        Task {
                            isSaving = true
                            await auth.updateDisplayName(name)
                            isSaving = false
                            HapticFeedback.success()
                            dismiss()
                        }
                    }
                    .disabled(!canSave || isSaving)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ContinuoTheme.textMedium)
                }
            }
        }
        .onAppear {
            name = auth.profile?.displayName ?? ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { nameFocused = true }
        }
    }
}

#Preview {
    EditDisplayNameSheet().environmentObject(AuthService())
}
