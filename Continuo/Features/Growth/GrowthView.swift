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

    // Coach-only state
    @State private var coachClients: [ContinuoUser] = []
    @State private var clientsListener: ListenerRegistration?

    private var totalGP: Int { auth.profile?.totalGP ?? 0 }
    private var isCoach: Bool { auth.profile?.role == .coach }

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
                            badgesSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 48)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onChange(of: totalGP) { _, newGP in
                if !isCoach { vm.loadBadges(totalGP: newGP) }
            }
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
                    vm.loadBadges(totalGP: totalGP)
                    assignmentListener = AssignmentService.shared.finishedAssignmentsListener(clientId: uid) {
                        finishedAssignments = $0
                    }
                    scoresListener = CompetencyService.shared.scoresListener(userId: uid) {
                        competencyScores = $0
                    }
                }
            }
            .onDisappear {
                assignmentListener?.remove()
                clientsListener?.remove()
                scoresListener?.remove()
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

    // MARK: - Badges
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Badges")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)

            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(vm.badges) { badge in
                    BadgeCell(badge: badge)
                }
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

// MARK: - Badge cell
struct BadgeCell: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked
                          ? ContinuoTheme.sunOrange.opacity(0.14)
                          : ContinuoTheme.charcoal.opacity(0.05))
                    .frame(width: 56, height: 56)
                Text(badge.emoji)
                    .font(.title2)
                    .opacity(badge.isUnlocked ? 1.0 : 0.25)
                if !badge.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(ContinuoTheme.textLight)
                        .offset(x: 16, y: 16)
                }
            }
            Text(badge.title)
                .font(ContinuoTheme.rounded(10, weight: .medium))
                .foregroundColor(badge.isUnlocked
                                 ? ContinuoTheme.charcoal
                                 : ContinuoTheme.charcoal.opacity(0.35))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(badge.isUnlocked
                                ? ContinuoTheme.sunOrange.opacity(0.3)
                                : Color.white.opacity(0.5), lineWidth: 1)
                )
        )
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
