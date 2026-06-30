import SwiftUI
import FirebaseFirestore

struct MyMissionVisionDetailView: View {
    let userId: String

    @State private var missionDraft = ""
    @State private var visionDraft = ""
    @State private var loaded = false
    @State private var saveTask: DispatchWorkItem?
    @State private var listener: ListenerRegistration?

    @FocusState private var missionFocused: Bool
    @FocusState private var visionFocused: Bool

    private let accent = Color(hex: "4F5D9F")

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🔭")
                            .font(.system(size: 44))
                        Text("My Mission & Vision")
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("Your reason to wake up, and where you're headed")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    .padding(.top, 4)

                    // ── Mission ──
                    editorSection(
                        title: "My Mission",
                        subtitle: "The why behind your days",
                        prompt: "I wake up everyday to…",
                        text: $missionDraft,
                        focused: $missionFocused
                    )

                    // ── Vision ──
                    editorSection(
                        title: "My Vision",
                        subtitle: "Where you want to arrive",
                        prompt: "What I want to achieve is…",
                        text: $visionDraft,
                        focused: $visionFocused
                    )

                    if missionFocused || visionFocused {
                        HStack {
                            Spacer()
                            Button("Done") {
                                missionFocused = false
                                visionFocused = false
                            }
                            .font(ContinuoTheme.rounded(14, weight: .semibold))
                            .foregroundColor(accent)
                        }
                    }

                    // ── Gentle guidance ──
                    hintCard
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            listener = MissionVisionService.shared.listener(userId: userId) { mv in
                // Only adopt remote values until the user starts editing locally,
                // so a live save doesn't clobber what they're typing.
                guard !loaded else { return }
                missionDraft = mv?.mission ?? ""
                visionDraft = mv?.vision ?? ""
                loaded = true
            }
        }
        .onDisappear {
            listener?.remove()
            saveTask?.cancel()
            save()   // flush any pending edits immediately
        }
    }

    // MARK: - Editor section

    private func editorSection(
        title: String,
        subtitle: String,
        prompt: String,
        text: Binding<String>,
        focused: FocusState<Bool>.Binding
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ContinuoTheme.rounded(17, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text(subtitle)
                .font(ContinuoTheme.rounded(12))
                .foregroundColor(accent.opacity(0.7))

            TextField("", text: text, axis: .vertical)
                .font(ContinuoTheme.rounded(15))
                .foregroundColor(ContinuoTheme.charcoal)
                .lineLimit(3...)
                .focused(focused)
                .onChange(of: text.wrappedValue) { _, _ in scheduleSave() }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    focused.wrappedValue ? accent.opacity(0.5) : Color(hex: "EDE8E0"),
                                    lineWidth: 1.5
                                )
                        )
                )
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(prompt)
                            .font(ContinuoTheme.rounded(15))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(ContinuoTheme.sunYellow)
                Text("How to think about it")
                    .font(ContinuoTheme.rounded(14, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
            }
            Text("Your **mission** is your purpose in the present — what gets you up each morning. Your **vision** is the future you're building toward. Keep both short enough to remember by heart.")
                .font(ContinuoTheme.rounded(13))
                .foregroundColor(ContinuoTheme.charcoal.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(accent.opacity(0.18), lineWidth: 1))
        )
    }

    // MARK: - Debounced save

    private func scheduleSave() {
        saveTask?.cancel()
        let task = DispatchWorkItem { save() }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: task)
    }

    private func save() {
        guard loaded else { return }
        try? MissionVisionService.shared.save(
            userId: userId,
            mission: missionDraft.trimmingCharacters(in: .whitespacesAndNewlines),
            vision: visionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
