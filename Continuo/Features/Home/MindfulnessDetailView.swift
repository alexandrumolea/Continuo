import SwiftUI

struct MindfulnessDetailView: View {
    let practice: DailyPractice
    let userId: String
    var onCompleted: ((String) -> Void)? = nil

    // Data
    @State private var minutesToday: Int = 0
    @State private var sessions: [MindfulSession] = []
    @State private var isHealthAuthorized = false
    @State private var hasCheckedAuth = false

    // Timer
    @State private var timerStart: Date? = nil

    // Manual entry
    @State private var customMinutes: String = ""
    @FocusState private var customFocused: Bool

    // Feedback
    @State private var lastGPGained: Int = 0
    @State private var showGPToast = false

    @Environment(\.dismiss) private var dismiss

    private let dailyGoal: Int = 10
    private var accent: Color { practice.categoryColor }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    todayCard
                    timerCard
                    manualLogCard
                    if !sessions.isEmpty {
                        sessionsCard
                    }
                    healthFooter
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .overlay(alignment: .top) { gpToast }
        .presentationDragIndicator(.visible)
        .task { await initialLoad() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(practice.emoji).font(.system(size: 44))
            Text(practice.title)
                .font(ContinuoTheme.rounded(26, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
            HStack(spacing: 6) {
                Text("Daily Practice")
                    .font(ContinuoTheme.rounded(12))
                    .foregroundColor(ContinuoTheme.textMedium)
                Text("·").foregroundColor(ContinuoTheme.textLight)
                Text("+3 GP at 5 min · +5 GP at 10 min")
                    .font(ContinuoTheme.rounded(12, weight: .semibold))
                    .foregroundColor(ContinuoTheme.sunYellow)
            }
        }
        .padding(.top, 28)
    }

    // MARK: - Today progress card

    private var todayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Today")
                        .font(ContinuoTheme.rounded(13))
                        .foregroundColor(ContinuoTheme.textMedium)
                    Spacer()
                    if minutesToday >= dailyGoal {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 11))
                            Text("Goal reached").font(ContinuoTheme.rounded(11, weight: .semibold))
                        }
                        .foregroundColor(ContinuoTheme.olive)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(ContinuoTheme.olive.opacity(0.12)))
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(minutesToday)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                    Text("min")
                        .font(ContinuoTheme.rounded(16, weight: .medium))
                        .foregroundColor(ContinuoTheme.textMedium)
                    Spacer()
                    if minutesToday > dailyGoal {
                        Text("+\(minutesToday - dailyGoal) over goal")
                            .font(ContinuoTheme.rounded(12, weight: .semibold))
                            .foregroundColor(ContinuoTheme.olive)
                    } else if minutesToday == dailyGoal {
                        Text("Goal complete")
                            .font(ContinuoTheme.rounded(12, weight: .semibold))
                            .foregroundColor(ContinuoTheme.olive)
                    } else {
                        Text("of \(dailyGoal) min goal")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textLight)
                    }
                }

                GeometryReader { geo in
                    let progress = min(CGFloat(minutesToday) / CGFloat(dailyGoal), 1)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(accent.opacity(0.12))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(accent)
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.4), value: minutesToday)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    // MARK: - Timer card

    private var timerCard: some View {
        GlassCard {
            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "timer").foregroundColor(accent)
                    Text("Meditation Timer")
                        .font(ContinuoTheme.rounded(14, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                }

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let elapsed = elapsedSeconds(at: context.date)
                    Text(formatElapsed(elapsed))
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(timerStart != nil ? accent : ContinuoTheme.charcoal.opacity(0.7))
                        .contentTransition(.numericText())
                }

                Button { toggleTimer() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: timerStart == nil ? "play.fill" : "stop.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(timerStart == nil ? "Start" : "Stop & Save")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(timerStart == nil ? accent : ContinuoTheme.terracotta)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Manual log card

    private var manualLogCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle").foregroundColor(accent)
                    Text("Log manually")
                        .font(ContinuoTheme.rounded(14, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                }

                HStack(spacing: 8) {
                    ForEach([5, 10, 15, 20], id: \.self) { mins in
                        Button { Task { await logManual(minutes: mins) } } label: {
                            Text("\(mins) min")
                                .font(ContinuoTheme.rounded(13, weight: .semibold))
                                .foregroundColor(accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(accent.opacity(0.10))
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(accent.opacity(0.3), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    TextField("Custom (min)", text: $customMinutes)
                        .keyboardType(.numberPad)
                        .focused($customFocused)
                        .font(ContinuoTheme.rounded(14))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1.5))
                        )

                    Button {
                        guard let n = Int(customMinutes), n > 0 else { return }
                        customMinutes = ""
                        customFocused = false
                        Task { await logManual(minutes: n) }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(11)
                            .background(Circle().fill(
                                Int(customMinutes).map { $0 > 0 } ?? false ? accent : ContinuoTheme.textLight))
                    }
                    .disabled(!(Int(customMinutes).map { $0 > 0 } ?? false))
                }
            }
        }
    }

    // MARK: - Sessions today

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sessions today")
                .font(ContinuoTheme.rounded(15, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
                .padding(.horizontal, 4)

            GlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(sessions.enumerated()), id: \.element.id) { idx, session in
                        sessionRow(session)
                        if idx < sessions.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
    }

    private func sessionRow(_ session: MindfulSession) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundColor(accent)
                .frame(width: 28, height: 28)
                .background(Circle().fill(accent.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(session.minutes) min")
                    .font(ContinuoTheme.rounded(14, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Text(session.start, style: .time)
                    .font(ContinuoTheme.rounded(11))
                    .foregroundColor(ContinuoTheme.textLight)
            }

            Spacer()

            Text(session.sourceName)
                .font(ContinuoTheme.rounded(10))
                .foregroundColor(ContinuoTheme.textLight)
                .lineLimit(1)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Health footer

    @ViewBuilder
    private var healthFooter: some View {
        if !HealthKitService.shared.isAvailable {
            EmptyView()
        } else if isHealthAuthorized {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .font(.system(size: 12))
                Text("Synced with Apple Health")
                    .font(ContinuoTheme.rounded(11))
                    .foregroundColor(ContinuoTheme.textLight)
                Spacer()
            }
            .padding(.horizontal, 4)
        } else if hasCheckedAuth {
            Button { Task { await requestHealthAuth() } } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.circle")
                        .foregroundColor(.pink)
                    Text("Connect to Apple Health")
                        .font(ContinuoTheme.rounded(13, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(ContinuoTheme.textLight)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.pink.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pink.opacity(0.2), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - GP toast

    @ViewBuilder
    private var gpToast: some View {
        if showGPToast && lastGPGained > 0 {
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundColor(ContinuoTheme.sunYellow)
                Text("+\(lastGPGained) GP")
                    .font(ContinuoTheme.rounded(15, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(
                Capsule().fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(ContinuoTheme.sunYellow.opacity(0.3), lineWidth: 1))
            )
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Timer helpers

    private func elapsedSeconds(at now: Date) -> Int {
        guard let start = timerStart else { return 0 }
        return max(0, Int(now.timeIntervalSince(start)))
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func toggleTimer() {
        if let start = timerStart {
            // Stop & save
            let seconds = Int(Date().timeIntervalSince(start))
            timerStart = nil
            let minutes = seconds / 60
            guard minutes >= 1 else {
                HapticFeedback.light()
                return
            }
            HapticFeedback.success()
            Task { await saveSession(durationMinutes: minutes, sessionStart: start) }
        } else {
            timerStart = Date()
            HapticFeedback.selection()
        }
    }

    // MARK: - Actions

    private func initialLoad() async {
        isHealthAuthorized = HealthKitService.shared.isWriteAuthorized
        hasCheckedAuth = true

        // First open of mindfulness ever → ask for auth automatically
        if HealthKitService.shared.isAvailable && !isHealthAuthorized {
            isHealthAuthorized = await HealthKitService.shared.requestMindfulnessAuth()
        }

        await refresh(awardGP: true)
    }

    private func requestHealthAuth() async {
        isHealthAuthorized = await HealthKitService.shared.requestMindfulnessAuth()
        await refresh(awardGP: true)
    }

    /// Re-reads HealthKit minutes + sessions and syncs them with Firestore.
    private func refresh(awardGP: Bool) async {
        let hkMinutes = await HealthKitService.shared.mindfulnessMinutesToday()
        let hkSessions = await HealthKitService.shared.mindfulnessSessionsToday()
        await MainActor.run {
            minutesToday = max(minutesToday, hkMinutes)
            sessions = hkSessions
        }

        if awardGP {
            do {
                let gained = try await DailyPracticeService.shared.updateMindfulnessTotal(
                    userId: userId, minutesToday: minutesToday
                )
                if gained > 0 {
                    await MainActor.run {
                        lastGPGained = gained
                        withAnimation { showGPToast = true }
                        onCompleted?(practice.id)
                    }
                    try? await Task.sleep(nanoseconds: 2_400_000_000)
                    await MainActor.run { withAnimation { showGPToast = false } }
                }
            } catch {
                print("❌ mindfulness sync: \(error)")
            }
        }
    }

    /// Writes a session (timer or manual). Saves to HealthKit if authorized, then syncs.
    private func saveSession(durationMinutes: Int, sessionStart: Date? = nil) async {
        let end = Date()
        let start = sessionStart ?? end.addingTimeInterval(-Double(durationMinutes * 60))

        if isHealthAuthorized {
            await HealthKitService.shared.saveMindfulnessSession(start: start, end: end)
        } else {
            // No HealthKit → bump local total directly
            await MainActor.run { minutesToday += durationMinutes }
        }

        await refresh(awardGP: true)
    }

    private func logManual(minutes: Int) async {
        HapticFeedback.success()
        await saveSession(durationMinutes: minutes)
    }
}
