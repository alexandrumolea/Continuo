import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CoreView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var values: [PersonalValue] = []
    @State private var valuesListener: ListenerRegistration?
    @State private var showMyValues = false

    @State private var strengths: [PersonalStrength] = []
    @State private var strengthsListener: ListenerRegistration?
    @State private var showMyStrengths = false

    @State private var skills: [PersonalSkill] = []
    @State private var skillsListener: ListenerRegistration?
    @State private var showMySkills = false

    @State private var priorities: [PersonalPriority] = []
    @State private var prioritiesListener: ListenerRegistration?
    @State private var showMyPriorities = false

    @State private var passions: [PersonalPassion] = []
    @State private var passionsListener: ListenerRegistration?
    @State private var showMyPassions = false

    var body: some View {
        NavigationStack {
            ZStack {
                ContinuoTheme.background.ignoresSafeArea()
                BackgroundOrbs()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Header ──
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Core")
                                .font(ContinuoTheme.rounded(32, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Know yourself deeper")
                                .font(ContinuoTheme.rounded(15))
                                .foregroundColor(ContinuoTheme.terracotta.opacity(0.7))
                        }
                        .padding(.top, 16)

                        // ── Cards ──
                        myValuesCard
                        myPrioritiesCard
                        myStrengthsCard
                        mySkillsCard
                        myPassionsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                guard let uid = auth.firebaseUser?.uid else { return }
                valuesListener     = ValuesService.shared.valuesListener(userId: uid)              { values     = $0 }
                strengthsListener  = StrengthsService.shared.strengthsListener(userId: uid)        { strengths  = $0 }
                skillsListener     = PersonalSkillsService.shared.skillsListener(userId: uid)      { skills     = $0 }
                passionsListener   = PersonalPassionsService.shared.passionsListener(userId: uid)  { passions   = $0 }
                prioritiesListener = PrioritiesService.shared.prioritiesListener(userId: uid)      { priorities = $0 }
            }
            .onDisappear {
                valuesListener?.remove()
                strengthsListener?.remove()
                skillsListener?.remove()
                passionsListener?.remove()
                prioritiesListener?.remove()
            }
            .sheet(isPresented: $showMyValues) {
                NavigationStack {
                    MyValuesDetailView(userId: auth.firebaseUser?.uid ?? "")
                        .navigationTitle("My Values")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMyStrengths) {
                NavigationStack {
                    MyStrengthsDetailView(userId: auth.firebaseUser?.uid ?? "")
                        .navigationTitle("My Strengths")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMySkills) {
                NavigationStack {
                    MySkillsDetailView(userId: auth.firebaseUser?.uid ?? "")
                        .navigationTitle("My Skills")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMyPassions) {
                NavigationStack {
                    MyPassionsDetailView(userId: auth.firebaseUser?.uid ?? "")
                        .navigationTitle("My Passions")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMyPriorities) {
                NavigationStack {
                    MyPrioritiesDetailView(userId: auth.firebaseUser?.uid ?? "")
                        .navigationTitle("My Priorities")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - My Values card

    private var myValuesCard: some View {
        Button { showMyValues = true } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {

                    // Card header
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ContinuoTheme.terracotta.opacity(0.1))
                                .frame(width: 46, height: 46)
                            Text("🧭")
                                .font(.system(size: 24))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Values")
                                .font(ContinuoTheme.rounded(17, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Self-discovery")
                                .font(ContinuoTheme.rounded(11, weight: .medium))
                                .foregroundColor(ContinuoTheme.terracotta)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(ContinuoTheme.terracotta.opacity(0.1)))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                    }

                    // Values preview (max 5 chips on card face)
                    if values.isEmpty {
                        emptyStateTag(text: "Tap to define your personal values",
                                      color: ContinuoTheme.terracotta)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            FlowLayout(spacing: 8) {
                                ForEach(values.prefix(5)) { value in
                                    coreChip(text: value.text, color: ContinuoTheme.terracotta)
                                }
                            }
                            if values.count > 5 {
                                Text("+ \(values.count - 5) more")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.terracotta.opacity(0.6))
                            }
                        }
                    }

                    // Progress dots (5 dots, fills when count ≥ 5)
                    progressDots(filled: min(values.count, 5), total: 5, color: ContinuoTheme.terracotta)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - My Strengths card

    private var myStrengthsCard: some View {
        let color = ContinuoTheme.olive
        return Button { showMyStrengths = true } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.1))
                                .frame(width: 46, height: 46)
                            Text("💪")
                                .font(.system(size: 24))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Strengths")
                                .font(ContinuoTheme.rounded(17, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Self-discovery")
                                .font(ContinuoTheme.rounded(11, weight: .medium))
                                .foregroundColor(color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(color.opacity(0.1)))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                    }

                    if strengths.isEmpty {
                        emptyStateTag(text: "Tap to identify your strengths", color: color)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(strengths) { strength in
                                coreChip(text: strength.text, color: color)
                            }
                        }
                    }

                    progressDots(filled: strengths.count, total: 5, color: color)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - My Skills card

    private var mySkillsCard: some View {
        let color = Color(hex: "2E7DD1")
        return Button { showMySkills = true } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.1))
                                .frame(width: 46, height: 46)
                            Text("🛠️")
                                .font(.system(size: 24))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Skills")
                                .font(ContinuoTheme.rounded(17, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Self-discovery")
                                .font(ContinuoTheme.rounded(11, weight: .medium))
                                .foregroundColor(color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(color.opacity(0.1)))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                    }

                    // Skills count (no chip preview per spec)
                    if skills.isEmpty {
                        emptyStateTag(text: "Tap to define your skills", color: color)
                    } else {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(color.opacity(0.1))
                                    .frame(width: 54, height: 40)
                                Text("\(skills.count)")
                                    .font(ContinuoTheme.rounded(24, weight: .bold))
                                    .foregroundColor(color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(skills.count) skill\(skills.count == 1 ? "" : "s") identified")
                                    .font(ContinuoTheme.rounded(14, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                Text("Tap to view & manage")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.textLight)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - My Passions card

    private var myPassionsCard: some View {
        let color = Color(hex: "C4536A")
        return Button { showMyPassions = true } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.1))
                                .frame(width: 46, height: 46)
                            Text("🔥")
                                .font(.system(size: 24))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Passions")
                                .font(ContinuoTheme.rounded(17, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Self-discovery")
                                .font(ContinuoTheme.rounded(11, weight: .medium))
                                .foregroundColor(color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(color.opacity(0.1)))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                    }

                    if passions.isEmpty {
                        emptyStateTag(text: "Tap to define your passions", color: color)
                    } else {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(color.opacity(0.1))
                                    .frame(width: 54, height: 40)
                                Text("\(passions.count)")
                                    .font(ContinuoTheme.rounded(24, weight: .bold))
                                    .foregroundColor(color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(passions.count) passion\(passions.count == 1 ? "" : "s") identified")
                                    .font(ContinuoTheme.rounded(14, weight: .semibold))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                Text("Tap to view & manage")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.textLight)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - My Priorities card

    private var myPrioritiesCard: some View {
        let color = Color(hex: "C4873A")
        return Button { showMyPriorities = true } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {

                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color.opacity(0.1))
                                .frame(width: 46, height: 46)
                            Text("📌")
                                .font(.system(size: 24))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Priorities")
                                .font(ContinuoTheme.rounded(17, weight: .bold))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("Self-discovery")
                                .font(ContinuoTheme.rounded(11, weight: .medium))
                                .foregroundColor(color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(color.opacity(0.1)))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ContinuoTheme.textLight)
                    }

                    // Top-3 numbered preview
                    if priorities.isEmpty {
                        emptyStateTag(text: "Tap to define your priorities", color: color)
                    } else {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(Array(priorities.prefix(3).enumerated()), id: \.element.id) { idx, p in
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 22, height: 22)
                                        Text("\(idx + 1)")
                                            .font(ContinuoTheme.rounded(11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    Text(p.text)
                                        .font(ContinuoTheme.rounded(13, weight: .medium))
                                        .foregroundColor(ContinuoTheme.charcoal)
                                        .lineLimit(1)
                                }
                            }
                            if priorities.count > 3 {
                                Text("+ \(priorities.count - 3) more")
                                    .font(ContinuoTheme.rounded(11))
                                    .foregroundColor(ContinuoTheme.textLight)
                                    .padding(.leading, 30)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared sub-views

    private func emptyStateTag(text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(ContinuoTheme.sunYellow)
            Text(text)
                .font(ContinuoTheme.rounded(13, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(ContinuoTheme.sunYellow.opacity(0.1)))
    }

    private func coreChip(text: String, color: Color) -> some View {
        Text(text)
            .font(ContinuoTheme.rounded(13, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color.opacity(0.09))
                    .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
            )
    }

    private func progressDots(filled: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filled ? color : color.opacity(0.15))
                    .frame(height: 3)
            }
        }
    }
}
