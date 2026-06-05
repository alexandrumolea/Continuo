import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GrowthView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = GrowthViewModel()

    // Client-only state
    @State private var finishedAssignments: [Assignment] = []
    @State private var assignmentListener: ListenerRegistration?
    @State private var assignmentToReactivate: Assignment? = nil
    @State private var competencyScores: [CompetencyScore] = []
    @State private var scoresListener: ListenerRegistration?
    @State private var recentActivityDates: Set<String> = []
    @State private var showAllBadges = false

    // Coach-only state
    @State private var coachClients: [ContinuoUser] = []
    @State private var clientsListener: ListenerRegistration?
    @State private var selectedCoachPractice: CoachPractice? = nil

    private var totalGP: Int          { auth.profile?.totalGP          ?? 0 }
    private var isCoach: Bool         { auth.profile?.role == .coach }
    private var practiceCount: Int    { auth.profile?.totalPracticeCount ?? 0 }
    private var coachingCount: Int    { auth.profile?.totalCoachingCount ?? 0 }
    private var maxCompScore: Int     { competencyScores.map(\.effectivePoints).max() ?? 0 }
    private var currentStreak: Int    { auth.profile?.currentStreak  ?? 0 }
    private var longestStreak: Int    { auth.profile?.longestStreak  ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        if isCoach {
                            coachGrowthContent
                        } else {
                            tierCard
                            competenciesSection
                            if !finishedAssignments.isEmpty {
                                completedChallengesSection
                            }
                            streakCard
                            badgesSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Scroll carousel to current tier immediately
                let idx = vm.currentTierIndex(gp: totalGP)
                scrolledTierID = vm.tiers[idx].id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    carouselReady = true
                }

                guard let uid = auth.firebaseUser?.uid else { return }
                if isCoach {
                    clientsListener = AssignmentService.shared.clientsListener(coachId: uid) {
                        coachClients = $0
                    }
                } else {
                    vm.startBadgesListener(userId: uid)
                    assignmentListener = AssignmentService.shared.finishedAssignmentsListener(clientId: uid) {
                        finishedAssignments = $0
                    }
                    scoresListener = CompetencyService.shared.scoresListener(userId: uid) {
                        competencyScores = $0
                    }
                    Task {
                        recentActivityDates = await StreakService.shared.recentActivityDates(userId: uid, days: 30)
                    }
                }
            }
            .onDisappear {
                assignmentListener?.remove()
                clientsListener?.remove()
                scoresListener?.remove()
                vm.stopBadgesListener()
            }
            .sheet(item: $selectedCoachPractice) { practice in
                coachPracticeSheet(for: practice)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAllBadges) {
                AllBadgesSheet(
                    earnedBadgeDates: vm.earnedBadgeDates,
                    practiceCount: practiceCount,
                    coachingCount: coachingCount,
                    maxCompScore: maxCompScore
                )
            }
            .alert("Reactivate challenge?", isPresented: Binding(
                get: { assignmentToReactivate != nil },
                set: { if !$0 { assignmentToReactivate = nil } }
            )) {
                Button("Reactivate", role: .destructive) {
                    if let a = assignmentToReactivate,
                       let uid = auth.firebaseUser?.uid {
                        try? AssignmentService.shared.reactivateAssignment(a, userId: uid)
                    }
                    assignmentToReactivate = nil
                }
                Button("Cancel", role: .cancel) { assignmentToReactivate = nil }
            } message: {
                Text("Provocarea va reveni activă și cei 50 GP bonus vor fi scăzuți.")
            }
        }
    }

    // MARK: - Competencies section (client)

    private var competenciesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Sharpened Competencies")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            GlassCard {
                VStack(spacing: 20) {
                    // Radar chart
                    CompetencyRadarChart(
                        scores: radarData,
                        size: 220
                    )
                    .frame(height: 220)

                    Divider().opacity(0.3)

                    // Individual bars
                    VStack(spacing: 14) {
                        ForEach(Competency.catalog) { competency in
                            let pts = effectivePoints(for: competency.id)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(competency.emoji).font(.system(size: 18))
                                    Text(competency.name)
                                        .font(ContinuoTheme.rounded(17, weight: .semibold))
                                        .foregroundColor(ContinuoTheme.charcoal)
                                    Spacer()
                                    Text("\(pts) pts")
                                        .font(ContinuoTheme.rounded(15, weight: .medium))
                                        .foregroundColor(competency.color)
                                }
                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(competency.color.opacity(0.12))
                                            .frame(height: 7)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(competency.color)
                                            .frame(width: geo.size.width * min(CGFloat(pts) / 100.0, 1.0),
                                                   height: 7)
                                            .animation(.spring(response: 0.5), value: pts)
                                    }
                                }
                                .frame(height: 7)
                                Text(competency.description)
                                    .font(ContinuoTheme.rounded(13))
                                    .foregroundColor(ContinuoTheme.textLight)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private var radarData: [(Competency, Int)] {
        Competency.catalog.map { ($0, effectivePoints(for: $0.id)) }
    }

    private func effectivePoints(for competencyId: String) -> Int {
        competencyScores.first { $0.competencyId == competencyId }?.effectivePoints ?? 0
    }

    // MARK: - Coach dashboard
    @ViewBuilder
    private var coachGrowthContent: some View {
        VStack(alignment: .leading, spacing: 40) {
            getInspiredSection
            clientProgressSection
        }
    }

    private var getInspiredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Get Inspired")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(CoachPractice.catalog) { practice in
                        CoachPracticeCard(practice: practice) {
                            if case .comingSoon = practice.type { return }
                            selectedCoachPractice = practice
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -20)
        }
    }

    private var clientProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Client Progress")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            if coachClients.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Text("👥").font(.system(size: 40))
                        Text("No clients connected yet.\nShare your coach code to get started.")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(coachClients) { client in
                    CoachClientProgressCard(client: client)
                }
            }
        }
    }

    // MARK: - Coach practice sheet router

    @ViewBuilder
    private func coachPracticeSheet(for practice: CoachPractice) -> some View {
        let coachId = auth.firebaseUser?.uid ?? ""
        switch practice.type {
        case .questionList(let questions):
            CoachQuestionListView(practice: practice, coachId: coachId, questions: questions)
        case .reflectionForm(let prompts):
            CoachSessionReflectionView(practice: practice, coachId: coachId, prompts: prompts)
        case .comingSoon:
            EmptyView()
        }
    }

    // MARK: - Completed challenges
    private var completedChallengesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Completed Challenges")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            ForEach(finishedAssignments) { assignment in
                GlassCard(padding: 14) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ContinuoTheme.terracotta.opacity(0.10))
                                .frame(width: 48, height: 48)
                            Text(assignment.emoji ?? "🎯")
                                .font(.title2)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(assignment.title)
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundColor(ContinuoTheme.sunYellow)
                                Text("\(assignment.completionCount)× completed")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.textMedium)
                                Text("·")
                                    .foregroundColor(ContinuoTheme.textLight)
                                Text("+\(assignment.gpReward * assignment.completionCount + 50) GP total")
                                    .font(ContinuoTheme.rounded(11, weight: .medium))
                                    .foregroundColor(ContinuoTheme.sunOrange)
                            }
                        }

                        Spacer()

                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundColor(ContinuoTheme.olive)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        assignmentToReactivate = assignment
                    } label: {
                        Label("Reactivează provocarea", systemImage: "arrow.uturn.backward.circle")
                    }
                }
            }
        }
    }

    // MARK: - Level carousel
    @State private var scrolledTierID: GrowthTier.ID? = nil
    @State private var carouselReady = false

    // The tier currently centred in the carousel
    private var visibleTier: GrowthTier {
        vm.tiers.first(where: { $0.id == scrolledTierID }) ?? vm.currentTier(gp: totalGP)
    }

    private var tierCard: some View {
        let currentIdx = vm.currentTierIndex(gp: totalGP)

        return VStack(alignment: .leading, spacing: 0) {

            // ── Header ────────────────────────────────────────
            HStack {
                Text("Your Path to Wisdom")
                    .font(ContinuoTheme.rounded(20, weight: .bold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(ContinuoTheme.sunYellow)
                    Text("\(totalGP) GP")
                        .font(ContinuoTheme.rounded(14, weight: .semibold))
                        .foregroundColor(ContinuoTheme.sunYellow)
                }
            }
            .padding(.bottom, 28)

            // ── Carousel (compact cards) ───────────────────────
            GeometryReader { proxy in
                let cardWidth = proxy.size.width * 0.62
                let hPad     = (proxy.size.width - cardWidth) / 2

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(vm.tiers.enumerated()), id: \.element.id) { idx, tier in
                            LevelCarouselCard(
                                tier: tier,
                                index: idx,
                                currentIndex: currentIdx,
                                totalGP: totalGP,
                                progress: idx == currentIdx ? vm.tierProgress(gp: totalGP) : 0,
                                gpToNext: idx == currentIdx ? vm.gpToNextTier(gp: totalGP) : 0
                            )
                            .frame(width: cardWidth)
                            .id(tier.id)
                            .scrollTransition(.animated(.spring(response: 0.35, dampingFraction: 0.80))) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.84)
                                    .opacity(phase.isIdentity ? 1.0 : 0.55)
                            }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, hPad)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledTierID, anchor: .center)
                .scrollClipDisabled()
                .onChange(of: scrolledTierID) { _, _ in
                    guard carouselReady else { return }
                    HapticFeedback.selection()
                }
            }
            .frame(height: 230)

            // ── Description panel (updates with scroll) ───────
            let shown = visibleTier
            let shownIdx = vm.tiers.firstIndex(where: { $0.id == shown.id }) ?? 0
            let shownState: Int = shownIdx < currentIdx ? -1 : (shownIdx == currentIdx ? 0 : 1)

            VStack(spacing: 8) {
                // Level pill + name
                HStack(spacing: 8) {
                    Text("Level \(shownIdx + 1)")
                        .font(ContinuoTheme.rounded(11, weight: .semibold))
                        .foregroundColor(shown.color.opacity(shownState == 1 ? 0.4 : 0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(shown.color.opacity(shownState == 1 ? 0.06 : 0.13)))

                    Text(shown.name)
                        .font(ContinuoTheme.rounded(20, weight: .bold))
                        .foregroundColor(shownState == 1
                                         ? ContinuoTheme.charcoal.opacity(0.3)
                                         : ContinuoTheme.charcoal)

                    if shownState == -1 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(ContinuoTheme.olive)
                    } else if shownState == 1 {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(ContinuoTheme.textLight)
                    }
                }

                // GP range
                Text(shown.maxGP == Int.max ? "\(shown.minGP)+ GP" : "\(shown.minGP) – \(shown.maxGP) GP")
                    .font(ContinuoTheme.rounded(13, weight: .medium))
                    .foregroundColor(shownState == 1 ? ContinuoTheme.textLight.opacity(0.4) : shown.color)

                // Description
                Text(shown.description)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(shownState == 1
                                     ? ContinuoTheme.textLight.opacity(0.4)
                                     : ContinuoTheme.charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.bottom, 28)
            .padding(.horizontal, 4)
            .id(shown.id)  // forces re-render when card changes
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: scrolledTierID)
        }
    }

    // MARK: - Streak card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Streak")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            GlassCard {
                VStack(spacing: 20) {
                    // Headline numbers
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("🔥").font(.system(size: 26))
                                Text("\(currentStreak)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(ContinuoTheme.sunOrange)
                            }
                            Text("day streak")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 50).opacity(0.3)

                        VStack(spacing: 4) {
                            Text("\(longestStreak)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(ContinuoTheme.charcoal.opacity(0.45))
                            Text("best")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 50).opacity(0.3)

                        VStack(spacing: 4) {
                            Text("\(recentActivityDates.count)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(ContinuoTheme.olive)
                            Text("active / 30d")
                                .font(ContinuoTheme.rounded(13))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Streak message
                    if currentStreak > 0 {
                        Text(streakMessage)
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(ContinuoTheme.textMedium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    activityCalendar
                }
            }
        }
    }

    private var streakMessage: String {
        switch currentStreak {
        case 1:       return "Great start — come back tomorrow to build your streak."
        case 2..<7:   return "Building momentum. Keep it going! 🌱"
        case 7..<14:  return "One week strong. You're developing a real habit. 🌟"
        case 14..<30: return "Impressive consistency. This is becoming who you are. 💪"
        default:      return "Unstoppable. A month+ of daily practice. 🔥"
        }
    }

    private var activityCalendar: some View {
        let cal   = Calendar.current
        let today = Date()
        let f: DateFormatter = { let d = DateFormatter(); d.dateFormat = "yyyy-MM-dd"; return d }()
        let monthF: DateFormatter = { let d = DateFormatter(); d.dateFormat = "MMM"; return d }()

        // Build the 30-day window
        let windowStart = cal.date(byAdding: .day, value: -29, to: today)!

        // Find the Monday of the week containing windowStart
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: windowStart)
        comps.weekday = 2 // Monday
        let gridStart = cal.date(from: comps) ?? windowStart

        // Build all days from gridStart to today (complete weeks)
        var gridDays: [Date] = []
        var cursor = gridStart
        while cursor <= today {
            gridDays.append(cursor)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        // Pad to full last week
        while gridDays.count % 7 != 0 {
            gridDays.append(cal.date(byAdding: .day, value: 1, to: gridDays.last!)!)
        }

        let weeks = stride(from: 0, to: gridDays.count, by: 7).map {
            Array(gridDays[$0..<min($0 + 7, gridDays.count)])
        }

        let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

        return VStack(alignment: .leading, spacing: 4) {
            // Day-of-week header
            HStack(spacing: 0) {
                ForEach(dayHeaders.indices, id: \.self) { i in
                    Text(dayHeaders[i])
                        .font(ContinuoTheme.rounded(10, weight: .semibold))
                        .foregroundColor(ContinuoTheme.textLight)
                        .frame(maxWidth: .infinity)
                }
            }

            // Week rows
            ForEach(weeks.indices, id: \.self) { wIdx in
                let week = weeks[wIdx]
                HStack(spacing: 0) {
                    ForEach(week.indices, id: \.self) { dIdx in
                        let day        = week[dIdx]
                        let key        = f.string(from: day)
                        let isInWindow = day >= windowStart && day <= today
                        let isFuture   = day > today
                        let hasAct     = isInWindow && recentActivityDates.contains(key)
                        let isToday    = cal.isDateInToday(day)
                        let dayNum     = cal.component(.day, from: day)
                        let isFirst    = dayNum == 1 && !isFuture

                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    isFuture      ? Color.clear :
                                    hasAct        ? ContinuoTheme.sunOrange.opacity(0.80) :
                                    isInWindow    ? ContinuoTheme.charcoal.opacity(0.06)
                                                  : Color.clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(isToday ? ContinuoTheme.sunOrange : Color.clear, lineWidth: 1.5)
                                )

                            if !isFuture {
                                VStack(spacing: 1) {
                                    if isFirst {
                                        Text(monthF.string(from: day))
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundColor(hasAct ? .white.opacity(0.9) : ContinuoTheme.sunOrange)
                                            .lineLimit(1)
                                    }
                                    Text("\(dayNum)")
                                        .font(.system(size: isFirst ? 9 : 11, weight: isToday ? .bold : .regular, design: .rounded))
                                        .foregroundColor(
                                            hasAct  ? .white :
                                            isToday ? ContinuoTheme.sunOrange
                                                    : ContinuoTheme.charcoal.opacity(isInWindow ? 0.55 : 0.2)
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                    }
                }
            }

            // Legend
            HStack(spacing: 6) {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(ContinuoTheme.charcoal.opacity(0.06))
                    .frame(width: 12, height: 12)
                Text("No activity")
                    .font(ContinuoTheme.rounded(10))
                    .foregroundColor(ContinuoTheme.textLight)
                RoundedRectangle(cornerRadius: 3)
                    .fill(ContinuoTheme.sunOrange.opacity(0.80))
                    .frame(width: 12, height: 12)
                Text("Active day")
                    .font(ContinuoTheme.rounded(10))
                    .foregroundColor(ContinuoTheme.textLight)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Badges ("Next Up" cards)

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Badges")
                    .font(ContinuoTheme.rounded(20, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                Button { showAllBadges = true } label: {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(ContinuoTheme.rounded(13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(ContinuoTheme.terracotta)
                }
            }

            ForEach(BadgeCategory.allCases, id: \.self) { category in
                NextUpBadgeCard(
                    category: category,
                    nextBadge: vm.nextBadge(for: category),
                    allEarned: vm.allEarned(for: category),
                    progress: vm.nextBadge(for: category).map {
                        vm.progress(for: $0,
                                    practiceCount: practiceCount,
                                    coachingCount: coachingCount,
                                    maxCompetencyScore: maxCompScore)
                    } ?? 1.0,
                    currentValue: { () -> Int in
                        switch category {
                        case .practice:   return practiceCount
                        case .coaching:   return coachingCount
                        case .competency: return maxCompScore
                        }
                    }()
                )
            }
        }
    }
}

// MARK: - Radar chart

struct CompetencyRadarChart: View {
    let scores: [(Competency, Int)]   // (competency, effectivePoints)
    let size: CGFloat
    private let maxPoints: CGFloat = 100

    var body: some View {
        Canvas { ctx, canvasSize in
            let cx = canvasSize.width  / 2
            let cy = canvasSize.height / 2
            let r  = min(cx, cy) - 20
            let n  = scores.count
            guard n > 0 else { return }

            func point(index: Int, ratio: CGFloat) -> CGPoint {
                let angle = (2 * .pi * CGFloat(index) / CGFloat(n)) - (.pi / 2)
                return CGPoint(x: cx + cos(angle) * r * ratio,
                               y: cy + sin(angle) * r * ratio)
            }

            // Grid rings
            for level in stride(from: 0.25, through: 1.0, by: 0.25) {
                var ring = Path()
                for i in 0..<n {
                    let pt = point(index: i, ratio: CGFloat(level))
                    i == 0 ? ring.move(to: pt) : ring.addLine(to: pt)
                }
                ring.closeSubpath()
                ctx.stroke(ring, with: .color(.gray.opacity(0.15)), lineWidth: 1)
            }

            // Axes
            for i in 0..<n {
                var axis = Path()
                axis.move(to: CGPoint(x: cx, y: cy))
                axis.addLine(to: point(index: i, ratio: 1.0))
                ctx.stroke(axis, with: .color(.gray.opacity(0.15)), lineWidth: 1)
            }

            // Data polygon
            var data = Path()
            for (i, (_, pts)) in scores.enumerated() {
                let ratio = min(CGFloat(pts) / maxPoints, 1.0)
                let pt = point(index: i, ratio: max(ratio, 0.02))
                i == 0 ? data.move(to: pt) : data.addLine(to: pt)
            }
            data.closeSubpath()
            ctx.fill(data, with: .color(Color(hex: "C4536A").opacity(0.18)))
            ctx.stroke(data, with: .color(Color(hex: "C4536A").opacity(0.7)), lineWidth: 2)
        }
        .frame(width: size, height: size)
        .overlay(
            // Axis labels
            GeometryReader { geo in
                let cx = geo.size.width / 2
                let cy = geo.size.height / 2
                let r  = min(cx, cy) - 20
                let n  = scores.count
                ForEach(Array(scores.enumerated()), id: \.offset) { i, pair in
                    let angle = (2 * .pi * CGFloat(i) / CGFloat(n)) - (.pi / 2)
                    let labelR = r + 14
                    let x = cx + cos(angle) * labelR
                    let y = cy + sin(angle) * labelR
                    Text(pair.0.emoji)
                        .font(.system(size: 18))
                        .position(x: x, y: y)
                }
            }
        )
    }
}

// MARK: - Coach client progress card
struct CoachClientProgressCard: View {
    let client: ContinuoUser

    @State private var sessionCount: Int = 0

    private var tier: (emoji: String, name: String) {
        switch client.totalGP {
        case 0..<200:    return ("🦉", "Waking")
        case 200..<450:  return ("🦉", "Seeking")
        case 450..<700:  return ("🦉", "Emerging")
        case 700..<2500: return ("🦉", "Aligned")
        case 2500..<5000:return ("🦉", "Flourishing")
        default:         return ("🦉", "Sage")
        }
    }

    private var initials: String {
        let parts = client.displayName.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)) }
        return String(client.displayName.prefix(2)).uppercased()
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(ContinuoTheme.olive.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Text(initials)
                        .font(ContinuoTheme.rounded(16, weight: .bold))
                        .foregroundColor(ContinuoTheme.olive)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.displayName)
                        .font(ContinuoTheme.rounded(15, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)

                    HStack(spacing: 10) {
                        // Level
                        HStack(spacing: 4) {
                            Text(tier.emoji).font(.system(size: 13))
                            Text(tier.name)
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }

                        Text("·").foregroundColor(ContinuoTheme.textLight)

                        // Sessions
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                                .foregroundColor(ContinuoTheme.textLight)
                            Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(client.totalGP)")
                        .font(ContinuoTheme.rounded(18, weight: .bold))
                        .foregroundColor(ContinuoTheme.sunOrange)
                    Text("GP")
                        .font(ContinuoTheme.rounded(11))
                        .foregroundColor(ContinuoTheme.textLight)
                }
            }
        }
        .task {
            if let id = client.id {
                let snap = try? await Firestore.firestore()
                    .collection("coachingSessions")
                    .whereField("userId", isEqualTo: id)
                    .getDocuments()
                sessionCount = snap?.documents.count ?? 0
            }
        }
    }
}

// MARK: - Next Up badge card

struct NextUpBadgeCard: View {
    let category: BadgeCategory
    let nextBadge: BadgeDefinition?
    let allEarned: Bool
    let progress: Double   // 0…1
    let currentValue: Int

    private var accentColor: Color {
        switch category {
        case .coaching:   return Color(hex: "2E7DD1")
        case .practice:   return Color(hex: "4E7040")
        case .competency: return Color(hex: "7B5EA7")
        }
    }

    var body: some View {
        GlassCard(padding: 16) {
            if allEarned {
                allEarnedRow
            } else if let badge = nextBadge {
                progressRow(badge: badge)
            }
        }
    }

    private func progressRow(badge: BadgeDefinition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Text(badge.emoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(badge.title)
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text(category.title.uppercased())
                            .font(ContinuoTheme.rounded(9, weight: .bold))
                            .foregroundColor(accentColor.opacity(0.75))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accentColor.opacity(0.1)))
                            .kerning(0.3)
                    }
                    Text(badge.description)
                        .font(ContinuoTheme.rounded(12))
                        .foregroundColor(ContinuoTheme.textMedium)
                }

                Spacer(minLength: 0)

                Text("\(currentValue) / \(badge.threshold)")
                    .font(ContinuoTheme.rounded(12, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(accentColor.opacity(0.12))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(accentColor)
                        .frame(width: geo.size.width * max(progress, progress > 0 ? 0.03 : 0),
                               height: 7)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 7)
        }
    }

    private var allEarnedRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ContinuoTheme.olive.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundColor(ContinuoTheme.olive)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(category.title) — All earned!")
                    .font(ContinuoTheme.rounded(15, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Text("You've unlocked every badge in this series.")
                    .font(ContinuoTheme.rounded(12))
                    .foregroundColor(ContinuoTheme.textMedium)
            }
            Spacer()
        }
    }
}

// MARK: - All Badges sheet

struct AllBadgesSheet: View {
    let earnedBadgeDates: [String: Date]
    let practiceCount: Int
    let coachingCount: Int
    let maxCompScore: Int

    @Environment(\.dismiss) private var dismiss

    private let dateF: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        ForEach(BadgeCategory.allCases, id: \.self) { category in
                            categorySection(category)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("All Badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func categorySection(_ category: BadgeCategory) -> some View {
        let badges = BadgeService.catalog.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 12) {
            Text(category.title)
                .font(ContinuoTheme.rounded(18, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            VStack(spacing: 10) {
                ForEach(badges) { badge in
                    badgeRow(badge)
                }
            }
        }
    }

    private func badgeRow(_ badge: BadgeDefinition) -> some View {
        let earned      = earnedBadgeDates[badge.id]
        let isUnlocked  = earned != nil
        let accent      = accentFor(badge.category)

        let currentValue: Int = {
            switch badge.category {
            case .practice:   return practiceCount
            case .coaching:   return coachingCount
            case .competency: return maxCompScore
            }
        }()
        let progress = min(1.0, Double(currentValue) / Double(badge.threshold))

        return HStack(spacing: 14) {
            // ── Emoji badge ──────────────────────────────────────
            ZStack {
                Circle()
                    .fill(isUnlocked ? accent.opacity(0.15) : Color.clear)
                    .frame(width: 50, height: 50)
                Circle()
                    .stroke(isUnlocked ? accent.opacity(0.3) : ContinuoTheme.charcoal.opacity(0.12),
                            lineWidth: 1.5)
                    .frame(width: 50, height: 50)
                Text(badge.emoji)
                    .font(.system(size: 22))
                    .opacity(isUnlocked ? 1.0 : 0.2)
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal.opacity(0.3))
                        .offset(x: 14, y: 14)
                }
            }

            // ── Text + progress ───────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(badge.title)
                        .font(ContinuoTheme.rounded(15, weight: .semibold))
                        .foregroundColor(isUnlocked
                                         ? ContinuoTheme.charcoal
                                         : ContinuoTheme.charcoal.opacity(0.35))
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(accent)
                    }
                }
                Text(badge.description)
                    .font(ContinuoTheme.rounded(12))
                    .foregroundColor(isUnlocked
                                     ? ContinuoTheme.textMedium
                                     : ContinuoTheme.textLight.opacity(0.5))

                if !isUnlocked {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(accent.opacity(0.08))
                                .frame(height: 4)
                            if progress > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(accent.opacity(0.45))
                                    .frame(width: max(geo.size.width * progress, 8), height: 4)
                            }
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            // ── Right side ────────────────────────────────────────
            if let date = earned {
                Text(dateF.string(from: date))
                    .font(ContinuoTheme.rounded(10))
                    .foregroundColor(accent.opacity(0.7))
                    .multilineTextAlignment(.trailing)
            } else {
                Text("\(currentValue)/\(badge.threshold)")
                    .font(ContinuoTheme.rounded(12, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.25))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isUnlocked
                      ? accent.opacity(0.06)
                      : ContinuoTheme.charcoal.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isUnlocked ? accent.opacity(0.18) : Color.clear, lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.55)
    }

    private func accentFor(_ category: BadgeCategory) -> Color {
        switch category {
        case .coaching:   return Color(hex: "2E7DD1")
        case .practice:   return Color(hex: "4E7040")
        case .competency: return Color(hex: "7B5EA7")
        }
    }
}

// MARK: - Level carousel card (compact)

struct LevelCarouselCard: View {
    let tier: GrowthTier
    let index: Int
    let currentIndex: Int
    let totalGP: Int
    let progress: Double
    let gpToNext: Int

    private var isCurrent:   Bool { index == currentIndex }
    private var isCompleted: Bool { index < currentIndex }
    private var isLocked:    Bool { index > currentIndex }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 22)
                .fill(tier.color.opacity(isLocked ? 0.06 : 0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(isCurrent ? tier.color.opacity(0.5) : tier.color.opacity(0.22),
                                lineWidth: isCurrent ? 2 : 1)
                )

            VStack(spacing: 0) {

                // ── Owl ──────────────────────────────────────
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Image(tier.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 86, height: 86)
                            .shadow(color: tier.color.opacity(isLocked ? 0.08 : 0.25),
                                    radius: 14, x: -2, y: 8)
                            .blendMode(.multiply)
                            .saturation(isLocked ? 0.35 : 1)
                            .opacity(isLocked ? 0.55 : 1)
                    }
                    .frame(width: 96, height: 96)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(ContinuoTheme.textLight.opacity(0.8)))
                            .offset(x: 2, y: 2)
                    } else if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(ContinuoTheme.olive))
                            .offset(x: 2, y: 2)
                    }
                }
                .padding(.top, 20)

                // ── Name ──────────────────────────────────────
                Text(tier.name)
                    .font(ContinuoTheme.rounded(20, weight: .bold))
                    .foregroundColor(isLocked
                                     ? ContinuoTheme.charcoal.opacity(0.45)
                                     : ContinuoTheme.charcoal)
                    .padding(.top, 10)

                // ── GP range ──────────────────────────────────
                Text(tier.maxGP == Int.max ? "\(tier.minGP)+ GP" : "\(tier.minGP)–\(tier.maxGP) GP")
                    .font(ContinuoTheme.rounded(12, weight: .medium))
                    .foregroundColor(isLocked ? tier.color.opacity(0.45) : tier.color)
                    .padding(.top, 3)

                Spacer(minLength: 10)

                // ── Progress bar (current only) ───────────────
                if isCurrent {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(tier.color.opacity(0.14))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [tier.color.opacity(0.6), tier.color],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * progress, height: 6)
                                .animation(.spring(response: 0.5), value: progress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                } else {
                    Spacer(minLength: 18)
                }
            }
        }
    }
}

#Preview {
    GrowthView().environmentObject(AuthService())
}
