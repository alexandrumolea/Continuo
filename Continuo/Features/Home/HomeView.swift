import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = HomeViewModel()
    @Environment(\.scenePhase) private var scenePhase
    // UI-only state (data lives in vm)
    @State private var selectedPractice: DailyPractice? = nil
    @State private var selectedJourneyEvent: JourneyEvent? = nil
    @State private var selectedGoal: Goal? = nil
    @State private var showAddGoal = false
    @State private var showReorderGoals = false

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        gpCard
                        weekStrip
                        inFocusSection
                        dailyPracticeSection
                        fromYourCoachSection
                        threadEventsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                guard let uid = auth.firebaseUser?.uid else { return }
                vm.start(userId: uid, isClient: auth.profile?.role == .client)
            }
            .onChange(of: auth.profile?.role) {
                guard let uid = auth.firebaseUser?.uid else { return }
                vm.start(userId: uid, isClient: auth.profile?.role == .client)
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    guard let uid = auth.firebaseUser?.uid else { return }
                    vm.start(userId: uid, isClient: auth.profile?.role == .client)
                }
            }
            .onDisappear { vm.stop() }
            .sheet(item: $selectedPractice) { practice in
                Group {
                    if practice.id == "activate_sage" {
                        ActivateSageDetailView(
                            practice: practice,
                            userId: auth.firebaseUser?.uid ?? "",
                            onCompleted: { id in vm.completedPracticeIds.insert(id) }
                        )
                    } else if practice.id == "mindfulness" {
                        MindfulnessDetailView(
                            practice: practice,
                            userId: auth.firebaseUser?.uid ?? "",
                            onCompleted: { id in vm.completedPracticeIds.insert(id) }
                        )
                    } else if practice.id == "releasing" {
                        ReleasingDetailView(
                            practice: practice,
                            userId: auth.firebaseUser?.uid ?? "",
                            onCompleted: { id in vm.completedPracticeIds.insert(id) }
                        )
                    } else if practice.id == "journaling" {
                        JournalingDetailView(
                            practice: practice,
                            userId: auth.firebaseUser?.uid ?? "",
                            onCompleted: { id in vm.completedPracticeIds.insert(id) }
                        )
                    } else if practice.id == "priority_alignment" {
                        PriorityAlignmentDetailView(
                            practice: practice,
                            userId: auth.firebaseUser?.uid ?? "",
                            onCompleted: { id in vm.completedPracticeIds.insert(id) }
                        )
                    } else {
                        DailyPracticeDetailView(
                            practice: practice,
                            userId: auth.firebaseUser?.uid ?? "",
                            onCompleted: { id in vm.completedPracticeIds.insert(id) }
                        )
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedJourneyEvent) { event in
                DailyPracticeResponseView(event: event, userId: auth.firebaseUser?.uid ?? "")
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedGoal) { goal in
                NavigationStack {
                    GoalDetailView(goal: goal, userId: auth.firebaseUser?.uid ?? "")
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalView(userId: auth.firebaseUser?.uid ?? "")
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showReorderGoals) {
                GoalReorderSheet(goals: $vm.goals)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - In Focus section
    private var inFocusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("In Focus")
                    .font(ContinuoTheme.rounded(20, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                HStack(spacing: 8) {
                    if !vm.goals.isEmpty {
                        Button { showReorderGoals = true } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ContinuoTheme.charcoal.opacity(0.7))
                            }
                            .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 0.5))
                        }
                    }
                    Button { showAddGoal = true } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ContinuoTheme.charcoal.opacity(0.7))
                        }
                        .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 0.5))
                    }
                }
            }

            if vm.goals.isEmpty {
                Button { showAddGoal = true } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 46, height: 46)
                            Image(systemName: "scope")
                                .font(.system(size: 20))
                                .foregroundStyle(ContinuoTheme.charcoal.opacity(0.35))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Add a goal")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal.opacity(0.75))
                            Text("Track what matters most to you")
                                .font(ContinuoTheme.rounded(12))
                                .foregroundColor(ContinuoTheme.textLight)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ContinuoTheme.textLight.opacity(0.6))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(.white.opacity(0.5), lineWidth: 0.5)
                            )
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.goals) { goal in
                            GoalCard(goal: goal) {
                                selectedGoal = goal
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Daily Practice section
    private var dailyPracticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Practice")
                    .font(ContinuoTheme.rounded(20, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                Text("+5 GP each")
                    .font(ContinuoTheme.rounded(11, weight: .medium))
                    .foregroundColor(ContinuoTheme.sunYellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ContinuoTheme.sunYellow.opacity(0.12)))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DailyPractice.catalog) { practice in
                        let isDone = vm.completedIdsForSelectedDate.contains(practice.id)
                        let isOpenEnded = practice.id == "activate_sage" || practice.id == "mindfulness"
                        DailyPracticeCard(
                            practice: practice,
                            isCompleted: isDone,
                            mindfulnessMinutes: practice.id == "mindfulness" ? vm.mindfulnessMinutesToday : nil
                        ) {
                            // Only allow interaction when viewing today
                            guard vm.isViewingToday else { return }
                            if !isDone || isOpenEnded {
                                selectedPractice = practice
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - With your coach section (always visible)
    private var fromYourCoachSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("With your coach")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            // Coaching sessions — always present
            CoachingSessionsCard(
                sessions: vm.coachingSessions,
                userId: auth.firebaseUser?.uid ?? ""
            )

            // Feedback forms — pending requests from coach
            ForEach(vm.pendingFeedbackForms) { form in
                FeedbackFormCard(
                    form: form,
                    clientName: auth.profile?.displayName ?? "",
                    userId: auth.firebaseUser?.uid ?? ""
                )
            }

            // Assignments — only when there are any
            ForEach(vm.assignments) { assignment in
                SwipeableAssignmentCard(
                    assignment: assignment,
                    userId: auth.firebaseUser?.uid ?? "",
                    onDelete: {
                        Task { try? await AssignmentService.shared.deleteAssignment(assignment) }
                    }
                )
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(greeting + ",")
                .font(ContinuoTheme.rounded(15))
                .foregroundColor(ContinuoTheme.textMedium)
            Text(auth.profile?.displayName ?? "")
                .font(ContinuoTheme.rounded(28, weight: .bold))
                .foregroundColor(ContinuoTheme.charcoal)
        }
        .padding(.top, 16)
    }

    // MARK: - GP card
    private var gpCard: some View {
        GlassCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Growth Points")
                        .font(ContinuoTheme.rounded(12))
                        .foregroundColor(ContinuoTheme.textMedium)
                    Text("\(auth.profile?.totalGP ?? 0)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(ContinuoTheme.terracotta)
                    Text(currentLevel.name)
                        .font(ContinuoTheme.rounded(12, weight: .semibold))
                        .foregroundColor(currentLevel.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(currentLevel.color.opacity(0.12)))
                }
                Spacer()
                Image(currentLevel.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .shadow(color: currentLevel.color.opacity(0.22), radius: 10, x: -2, y: 6)
                    .blendMode(.multiply)
            }
        }
    }

    private var currentLevel: (name: String, imageName: String, color: Color) {
        switch auth.profile?.totalGP ?? 0 {
        case 0..<200:    return ("Waking",     "OwlWaking",     Color(hex: "7B9CB8"))
        case 200..<450:  return ("Seeking",    "OwlSeeking",    Color(hex: "C4873A"))
        case 450..<700:  return ("Emerging",   "OwlEmerging",   Color(hex: "4E7040"))
        case 700..<2500: return ("Aligned",    "OwlAligned",    Color(hex: "2D9B8A"))
        case 2500..<5000:return ("Flourishing","OwlFlourishing",Color(hex: "C4A020"))
        default:         return ("Sage",       "OwlSage",       Color(hex: "7B5EA7"))
        }
    }

    // MARK: - Thread events (shown below daily practice)
    private var threadEventsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Thread")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            let dayEvents = eventsForSelectedDate
            if dayEvents.isEmpty {
                emptyThread
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(dayEvents.enumerated()), id: \.element.id) { idx, event in
                        JourneyRow(event: event, isLast: idx == dayEvents.count - 1,
                                   onTap: { selectedJourneyEvent = event },
                                   onDelete: {
                            let uid = auth.firebaseUser?.uid ?? ""
                            Task {
                                try? await FirestoreService.shared.deleteJourneyEvent(event)
                                // Reactivate practice card for that day
                                if event.type == .dailyPracticeCompleted,
                                   let practiceId = event.practiceId {
                                    try? await DailyPracticeService.shared.deleteCompletion(
                                        userId: uid,
                                        practiceId: practiceId,
                                        date: event.createdAt
                                    )
                                    await DailyPracticeService.shared.rollbackCompetencyPoints(
                                        userId: uid,
                                        practiceId: practiceId,
                                        points: event.gpEarned
                                    )
                                }
                            }
                        })
                    }
                }
            }
        }
    }

    // MARK: - Scrollable date strip (90 days back + 7 ahead)
    private var weekStrip: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let allDates = scrollableDates

        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(allDates, id: \.self) { day in
                        let isSelected = cal.isDate(day, inSameDayAs: vm.selectedDate)
                        let isToday    = cal.isDate(day, inSameDayAs: today)
                        let hasDot     = vm.events.contains { cal.isDate($0.createdAt, inSameDayAs: day) }
                        let isFirstOfMonth = cal.component(.day, from: day) == 1

                        VStack(spacing: 0) {
                            // Month label when month rolls over
                            if isFirstOfMonth {
                                Text(monthAbbrev(day))
                                    .font(ContinuoTheme.rounded(9, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.terracotta)
                                    .frame(height: 14)
                            } else {
                                Spacer().frame(height: 14)
                            }

                            Button {
                                HapticFeedback.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { vm.selectedDate = day }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(dayAbbrev(day))
                                        .font(ContinuoTheme.rounded(10))
                                        .foregroundColor(isSelected ? ContinuoTheme.terracotta : ContinuoTheme.textLight)

                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? ContinuoTheme.sunYellow : Color.clear)
                                            .frame(width: 34, height: 34)
                                        if isToday && !isSelected {
                                            Circle()
                                                .stroke(ContinuoTheme.sunYellow.opacity(0.5), lineWidth: 1.5)
                                                .frame(width: 34, height: 34)
                                        }
                                        Text(dayNumber(day))
                                            .font(ContinuoTheme.rounded(14, weight: isToday || isSelected ? .bold : .regular))
                                            .foregroundColor(isSelected ? .white : (isToday ? ContinuoTheme.charcoal : ContinuoTheme.textMedium))
                                    }

                                    Circle()
                                        .fill(hasDot ? ContinuoTheme.sunYellow : Color.clear)
                                        .frame(width: 4, height: 4)
                                }
                                .frame(width: 44)
                            }
                            .buttonStyle(.plain)
                            .id(day)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(today, anchor: .center)
                }
            }
        }
    }

    private var scrollableDates: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -90, to: today),
              let end   = cal.date(byAdding: .day, value: 7,  to: today) else { return [] }
        var dates: [Date] = []
        var cur = start
        while cur <= end {
            dates.append(cur)
            cur = cal.date(byAdding: .day, value: 1, to: cur) ?? cur
        }
        return dates
    }

    private func monthAbbrev(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: date).uppercased()
    }

    private var eventsForSelectedDate: [JourneyEvent] {
        let cal = Calendar.current
        return vm.events.filter { cal.isDate($0.createdAt, inSameDayAs: vm.selectedDate) }
    }

    private func dayAbbrev(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(3))
    }
    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    private var emptyThread: some View {
        GlassCard {
            VStack(spacing: 14) {
                Text("∞")
                    .font(.system(size: 44))
                    .foregroundColor(ContinuoTheme.sunOrange.opacity(0.5))
                Text(Calendar.current.isDateInToday(vm.selectedDate)
                     ? "Your journey begins here.\nComplete a habit or log a reflection."
                     : "Nothing logged on this day.")
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.textMedium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Goal card (In Focus)
struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void

    private var progressPercent: Int { Int((goal.progress * 100).rounded()) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Emoji + title
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.emoji ?? goal.type.emoji)
                        .font(.system(size: 32))
                    Text(goal.title)
                        .font(ContinuoTheme.rounded(15, weight: .bold))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                // Progress bar
                VStack(alignment: .leading, spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(goal.type.color.opacity(0.15))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(goal.type.color)
                                .frame(width: geo.size.width * goal.progress, height: 5)
                        }
                    }
                    .frame(height: 5)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(progressPercent)% achieved")
                            .font(ContinuoTheme.rounded(10))
                            .foregroundColor(goal.type.color.opacity(0.8))
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                            Text(goal.createdAt, style: .date)
                                .font(ContinuoTheme.rounded(9))
                        }
                        .foregroundColor(ContinuoTheme.textLight)
                    }
                }
            }
            .padding(16)
            .frame(width: 200, height: 175)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(goal.type.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(goal.type.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "2D2926").opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Daily practice card
struct DailyPracticeCard: View {
    let practice: DailyPractice
    let isCompleted: Bool
    var mindfulnessMinutes: Int? = nil
    let onTap: () -> Void

    /// Mindfulness is open-ended — never wash it out, the user is welcome to keep going.
    private var washedOut: Bool { mindfulnessMinutes == nil && isCompleted }
    private var hasMindfulnessProgress: Bool { (mindfulnessMinutes ?? 0) > 0 }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Emoji + title
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

                    if isCompleted || hasMindfulnessProgress {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(ContinuoTheme.olive)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Spacer(minLength: 12)

                // Subtitle — mindfulness shows live minutes, the rest show their prompt preview
                if let min = mindfulnessMinutes, min > 0 {
                    HStack(spacing: 4) {
                        Text("\(min)")
                            .font(ContinuoTheme.rounded(20, weight: .bold))
                            .foregroundColor(practice.categoryColor)
                        Text("min today")
                            .font(ContinuoTheme.rounded(12, weight: .medium))
                            .foregroundColor(ContinuoTheme.charcoal.opacity(0.7))
                    }
                } else {
                    Text(practice.prompts.first ?? "")
                        .font(ContinuoTheme.rounded(12))
                        .foregroundColor(ContinuoTheme.charcoal.opacity(washedOut ? 0.4 : 0.65))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                // Footer
                HStack(spacing: 8) {
                    if mindfulnessMinutes != nil {
                        // For mindfulness, show "Tap to log more" — never "Completed"
                        Text(hasMindfulnessProgress ? "Tap to log more" : "Today")
                            .font(ContinuoTheme.rounded(11, weight: hasMindfulnessProgress ? .semibold : .regular))
                            .foregroundColor(hasMindfulnessProgress ? practice.categoryColor : ContinuoTheme.charcoal.opacity(0.5))
                    } else if isCompleted {
                        Text("Completed")
                            .font(ContinuoTheme.rounded(11, weight: .semibold))
                            .foregroundColor(ContinuoTheme.olive)
                    } else {
                        Text("Today")
                            .font(ContinuoTheme.rounded(11))
                            .foregroundColor(ContinuoTheme.charcoal.opacity(0.5))
                    }
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
                            .stroke(
                                washedOut
                                    ? ContinuoTheme.olive.opacity(0.25)
                                    : practice.categoryColor.opacity(0.18),
                                lineWidth: 1
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(washedOut ? 0.35 : 0))
            )
            .shadow(color: Color(hex: "2D2926").opacity(washedOut ? 0.02 : 0.06), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Journey row (timeline item) with swipe-to-delete
struct JourneyRow: View {
    let event: JourneyEvent
    let isLast: Bool
    var onTap: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var swipeOffset: CGFloat = 0
    private let deleteWidth: CGFloat = 68

    private var isPractice: Bool { event.type == .dailyPracticeCompleted }
    private var filledResponses: [String] {
        (event.responses ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    private var practice: DailyPractice? {
        DailyPractice.catalog.first { $0.id == event.practiceId }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button (revealed on swipe)
            if onDelete != nil {
                Button {
                    HapticFeedback.medium()
                    withAnimation(.spring(response: 0.25)) { swipeOffset = 0 }
                    onDelete?()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                        Text("Delete")
                            .font(ContinuoTheme.rounded(10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteWidth)
                    .frame(maxHeight: .infinity)
                }
                .background(Color.red.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(swipeOffset < -8 ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: swipeOffset)
            }

            // Row content
            rowContent
                .offset(x: swipeOffset)
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { val in
                            guard onDelete != nil, val.translation.width < 0 else { return }
                            swipeOffset = max(val.translation.width, -deleteWidth)
                        }
                        .onEnded { val in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                swipeOffset = val.translation.width < -(deleteWidth / 2) ? -deleteWidth : 0
                            }
                        }
                )
        }
        .clipped()
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline column
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.iconColor.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: event.systemIcon)
                        .font(.caption)
                        .foregroundColor(event.iconColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(ContinuoTheme.charcoal.opacity(0.1))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }

            // Content column
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(ContinuoTheme.rounded(14, weight: .medium))
                        .foregroundColor(ContinuoTheme.charcoal)
                    Spacer()
                    if isPractice {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundColor(ContinuoTheme.textLight)
                    }
                }

                if !event.subtitle.isEmpty && !isPractice {
                    Text(event.subtitle)
                        .font(ContinuoTheme.rounded(12))
                        .foregroundColor(ContinuoTheme.textMedium)
                        .lineLimit(1)
                }

                // Inline responses
                if isPractice && !filledResponses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(filledResponses.indices, id: \.self) { idx in
                            Text(filledResponses[idx])
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                            if idx < filledResponses.count - 1 {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(practice?.cardColor.opacity(0.6) ?? Color.white.opacity(0.6))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
                    )
                }

                HStack(spacing: 8) {
                    Text(event.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(ContinuoTheme.textLight)
                    if event.gpEarned > 0 {
                        Text("+\(event.gpEarned) GP")
                            .font(ContinuoTheme.rounded(11, weight: .semibold))
                            .foregroundColor(ContinuoTheme.sunOrange)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, isLast ? 0 : 22)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if swipeOffset < 0 {
                withAnimation(.spring(response: 0.25)) { swipeOffset = 0 }
            } else if isPractice {
                onTap?()
            }
        }
    }
}

// MARK: - Assignment feed card
struct AssignmentFeedCard: View {
    let assignment: Assignment

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ContinuoTheme.terracotta.opacity(0.10))
                        .frame(width: 48, height: 48)
                    Text(assignment.emoji ?? "🎯").font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title)
                        .font(ContinuoTheme.rounded(15, weight: .semibold))
                        .foregroundColor(ContinuoTheme.charcoal)
                        .lineLimit(1)
                    if assignment.isDueNow {
                        Label("Due now", systemImage: "circle.fill")
                            .font(ContinuoTheme.rounded(11, weight: .semibold))
                            .foregroundColor(ContinuoTheme.olive)
                    } else {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(ContinuoTheme.rounded(11))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
        .overlay(
            Group {
                if assignment.isDueNow {
                    Circle()
                        .fill(ContinuoTheme.sunYellow)
                        .frame(width: 9, height: 9)
                        .padding(6)
                }
            }, alignment: .topTrailing
        )
    }
}

// MARK: - Coaching sessions card (face only — tap to open detail)

struct CoachingSessionsCard: View {
    let sessions: [CoachingSession]
    let userId: String

    @State private var showDetail = false

    private let accent = Color(hex: "6E443C")

    var body: some View {
        Button { showDetail = true } label: {
            GlassCard {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accent.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Text("🤝").font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coaching Sessions")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text("Growth")
                                .font(ContinuoTheme.rounded(11, weight: .medium))
                                .foregroundColor(accent)
                            Text("·")
                                .foregroundColor(ContinuoTheme.textLight)
                            Text(sessions.isEmpty
                                 ? "No sessions yet"
                                 : "\(sessions.count) session\(sessions.count == 1 ? "" : "s")")
                                .font(ContinuoTheme.rounded(11))
                                .foregroundColor(ContinuoTheme.textMedium)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ContinuoTheme.textLight)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                CoachingSessionsDetailView(userId: userId)
                    .navigationTitle("Coaching Sessions")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Assignment card with long-press delete

struct SwipeableAssignmentCard: View {
    let assignment: Assignment
    let userId: String
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(destination: AssignmentDetailView(
            assignment: assignment,
            userId: userId
        )) {
            AssignmentFeedCard(assignment: assignment)
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete assignment", systemImage: "trash")
            }
        }
    }
}

#Preview {
    HomeView().environmentObject(AuthService())
}
