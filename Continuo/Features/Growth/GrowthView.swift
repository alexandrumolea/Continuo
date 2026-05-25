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
                    VStack(spacing: 20) {
                        if isCoach {
                            coachGrowthContent
                        } else {
                            tierCard
                            if !finishedAssignments.isEmpty {
                                completedChallengesSection
                            }
                            badgesSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Growth")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: totalGP) { _, newGP in
                if !isCoach { vm.loadBadges(totalGP: newGP) }
            }
            .onAppear {
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
                }
            }
            .onDisappear {
                assignmentListener?.remove()
                clientsListener?.remove()
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
                                .fill(assignment.type.color.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Text(assignment.type.emoji)
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

    // MARK: - Tier card
    private var tierCard: some View {
        let tier = vm.currentTier(gp: totalGP)
        let progress = vm.tierProgress(gp: totalGP)
        let toNext = vm.gpToNextTier(gp: totalGP)

        return GlassCard {
            VStack(spacing: 16) {
                // Tier info
                HStack(spacing: 16) {
                    Text(tier.emoji)
                        .font(.system(size: 52))
                        .shadow(color: ContinuoTheme.sunOrange.opacity(0.3), radius: 10)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tier.name)
                            .font(ContinuoTheme.rounded(22, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("\(totalGP) Growth Points")
                            .font(ContinuoTheme.rounded(14))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    Spacer()
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    ContinuoProgressBar(progress: progress, color: ContinuoTheme.sunOrange, height: 8)
                    if toNext > 0 {
                        Text("\(toNext) GP to next tier")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                    } else {
                        Text("Maximum tier reached ✨")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.sunOrange)
                    }
                }

                Divider().opacity(0.3)

                // Tier path
                HStack(spacing: 0) {
                    ForEach(Array(vm.tiers.enumerated()), id: \.element.id) { idx, t in
                        VStack(spacing: 4) {
                            Text(t.emoji)
                                .font(.title3)
                                .opacity(totalGP >= t.minGP ? 1.0 : 0.28)
                            Text(t.name)
                                .font(ContinuoTheme.rounded(9))
                                .foregroundColor(totalGP >= t.minGP
                                                 ? ContinuoTheme.charcoal.opacity(0.7)
                                                 : ContinuoTheme.charcoal.opacity(0.25))
                        }
                        .frame(maxWidth: .infinity)
                        if idx < vm.tiers.count - 1 {
                            Rectangle()
                                .fill(ContinuoTheme.charcoal.opacity(0.12))
                                .frame(height: 1)
                                .padding(.bottom, 16)
                        }
                    }
                }
            }
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

// MARK: - Coach client progress card
struct CoachClientProgressCard: View {
    let client: ContinuoUser

    @State private var sessionCount: Int = 0

    private var tier: (emoji: String, name: String) {
        switch client.totalGP {
        case 0..<100:    return ("🌱", "Seedling")
        case 100..<300:  return ("🌿", "Sprout")
        case 300..<600:  return ("🌸", "Bloom")
        case 600..<1000: return ("🌳", "Flourish")
        default:         return ("✨", "Radiant")
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

#Preview {
    GrowthView().environmentObject(AuthService())
}
