import SwiftUI
import FirebaseFirestore

struct FeedbackDashboardView: View {
    let coachId: String

    @State private var allResponses: [FeedbackResponse] = []
    @State private var listener: ListenerRegistration?
    @State private var selectedTab: DashboardTab = .aggregate

    enum DashboardTab: String, CaseIterable {
        case aggregate = "All Clients"
        case perClient = "Per Client"
    }

    private var aggregates: [QuestionAggregate] {
        FeedbackService.computeAggregates(from: allResponses)
    }

    private var clientNames: [String] {
        Array(Set(allResponses.map(\.clientName))).sorted()
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            if allResponses.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Picker("View", selection: $selectedTab) {
                            ForEach(DashboardTab.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        if selectedTab == .aggregate {
                            aggregateContent
                        } else {
                            perClientContent
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Feedback Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            listener = FeedbackService.shared.allResponsesListener(coachId: coachId) {
                allResponses = $0
            }
        }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📊").font(.system(size: 52))
            Text("No feedback yet")
                .font(ContinuoTheme.rounded(20, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
            Text("Send feedback forms to your clients\nfrom their activity page.")
                .font(ContinuoTheme.rounded(14))
                .foregroundColor(ContinuoTheme.textMedium)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - All Clients tab

    private var aggregateContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            // ── Rating questions ──
            if !aggregates.isEmpty {
                sectionHeader("Rating Questions", icon: "star.fill", color: ContinuoTheme.sunYellow)
                    .padding(.horizontal, 20)

                ForEach(aggregates) { agg in
                    AggregateCard(aggregate: agg)
                        .padding(.horizontal, 20)
                }
            }

            // ── Open & milestone questions ──
            let openPairs = openPairsFromResponses(allResponses)
            if !openPairs.isEmpty {
                sectionHeader("Open & Milestone", icon: "text.bubble.fill", color: Color(hex: "2E7DD1"))
                    .padding(.horizontal, 20)

                ForEach(openQuestionIds(from: openPairs), id: \.self) { qId in
                    if let question = FeedbackQuestion.catalog.first(where: { $0.id == qId }) {
                        let items = openPairs.filter { $0.answer.questionId == qId }
                        ExpandableOpenQuestion(question: question, items: items)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: - Per Client tab

    private var perClientContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(clientNames, id: \.self) { name in
                ClientFeedbackSection(
                    clientName: name,
                    responses: allResponses.filter { $0.clientName == name }
                )
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helpers

    private func openPairsFromResponses(_ responses: [FeedbackResponse])
        -> [(response: FeedbackResponse, answer: FeedbackAnswer)]
    {
        responses.flatMap { response in
            response.answers.filter { answer in
                guard let q = FeedbackQuestion.catalog.first(where: { $0.id == answer.questionId })
                else { return false }
                return q.type == .open || q.type == .milestone
            }.map { (response, $0) }
        }
    }

    /// Returns questionIds in catalog order (preserving question bank sequence).
    private func openQuestionIds(from pairs: [(response: FeedbackResponse, answer: FeedbackAnswer)]) -> [String] {
        let present = Set(pairs.map(\.answer.questionId))
        return FeedbackQuestion.catalog
            .filter { present.contains($0.id) && ($0.type == .open || $0.type == .milestone) }
            .map(\.id)
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            Text(title)
                .font(ContinuoTheme.rounded(17, weight: .semibold))
                .foregroundColor(ContinuoTheme.charcoal)
        }
    }
}

// MARK: - Expandable open question row (All Clients)

struct ExpandableOpenQuestion: View {
    let question: FeedbackQuestion
    let items: [(response: FeedbackResponse, answer: FeedbackAnswer)]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — always visible, tappable
            Button {
                HapticFeedback.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question.text)
                            .font(ContinuoTheme.rounded(14, weight: .medium))
                            .foregroundColor(ContinuoTheme.charcoal)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        Text("\(items.count) answer\(items.count == 1 ? "" : "s")")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ContinuoTheme.textLight)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded answers
            if isExpanded {
                Divider().opacity(0.4).padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(items.indices, id: \.self) { i in
                        answerRow(items[i])
                        if i < items.count - 1 {
                            Divider().opacity(0.3)
                        }
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "EDE8E0"), lineWidth: 1))
        )
        .shadow(color: Color(hex: "2D2926").opacity(0.05), radius: 10, x: 0, y: 3)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func answerRow(_ item: (response: FeedbackResponse, answer: FeedbackAnswer)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.response.clientName)
                    .font(ContinuoTheme.rounded(12, weight: .semibold))
                    .foregroundColor(ContinuoTheme.textMedium)
                Spacer()
                Text(item.response.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(ContinuoTheme.textLight)
            }

            if let text = item.answer.openText, !text.isEmpty {
                Text(text)
                    .font(ContinuoTheme.rounded(14))
                    .foregroundColor(ContinuoTheme.charcoal.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let ms = item.answer.milestoneValue,
               let milestone = MilestoneValue(rawValue: ms) {
                HStack(spacing: 5) {
                    Text(milestone.emoji).font(.system(size: 14))
                    Text(milestone.label)
                        .font(ContinuoTheme.rounded(13, weight: .semibold))
                        .foregroundColor(milestone.color)
                }
            }
        }
    }
}

// MARK: - Aggregate card (rating question with sparkline)

struct AggregateCard: View {
    let aggregate: QuestionAggregate

    private var trendColor: Color {
        guard aggregate.history.count >= 2 else { return ContinuoTheme.textLight }
        let delta = aggregate.history.last!.value - aggregate.history[aggregate.history.count - 2].value
        return delta > 0 ? ContinuoTheme.olive : delta < 0 ? Color(hex: "C0392B") : ContinuoTheme.textLight
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(aggregate.questionText)
                    .font(ContinuoTheme.rounded(13, weight: .medium))
                    .foregroundColor(ContinuoTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center, spacing: 16) {
                    // Average circle
                    ZStack {
                        Circle()
                            .stroke(ContinuoTheme.sunYellow.opacity(0.15), lineWidth: 5)
                            .frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0, to: CGFloat(aggregate.average / 10.0))
                            .stroke(ContinuoTheme.sunYellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 60, height: 60)
                        VStack(spacing: 0) {
                            Text(String(format: "%.1f", aggregate.average))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(ContinuoTheme.charcoal)
                            Text("/10")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(ContinuoTheme.textLight)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(aggregate.responseCount) response\(aggregate.responseCount == 1 ? "" : "s")")
                            .font(ContinuoTheme.rounded(12))
                            .foregroundColor(ContinuoTheme.textMedium)
                        if aggregate.history.count >= 2 {
                            let delta = aggregate.history.last!.value - aggregate.history[aggregate.history.count - 2].value
                            HStack(spacing: 4) {
                                Image(systemName: delta > 0 ? "arrow.up" : delta < 0 ? "arrow.down" : "minus")
                                    .font(.caption2)
                                Text(delta == 0 ? "No change" : String(format: "%+.1f from last", delta))
                                    .font(ContinuoTheme.rounded(11))
                            }
                            .foregroundColor(trendColor)
                        }
                    }

                    Spacer()

                    if aggregate.history.count >= 2 {
                        SparklineView(values: aggregate.history.map(\.value), range: 1...10)
                            .frame(width: 80, height: 36)
                    }
                }
            }
        }
    }
}

// MARK: - Sparkline

struct SparklineView: View {
    let values: [Double]
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let span = range.upperBound - range.lowerBound

            Path { path in
                for (i, v) in values.enumerated() {
                    let x = w * CGFloat(i) / CGFloat(max(values.count - 1, 1))
                    let y = h - h * CGFloat((v - range.lowerBound) / span)
                    i == 0 ? path.move(to: .init(x: x, y: y)) : path.addLine(to: .init(x: x, y: y))
                }
            }
            .stroke(ContinuoTheme.sunYellow, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            ForEach(values.indices, id: \.self) { i in
                let x = w * CGFloat(i) / CGFloat(max(values.count - 1, 1))
                let y = h - h * CGFloat((values[i] - range.lowerBound) / span)
                Circle().fill(ContinuoTheme.sunYellow).frame(width: 5, height: 5).position(x: x, y: y)
            }
        }
    }
}

// MARK: - Per-client section

struct ClientFeedbackSection: View {
    let clientName: String
    let responses: [FeedbackResponse]

    private var aggregates: [QuestionAggregate] {
        FeedbackService.computeAggregates(from: responses)
    }

    /// All open/milestone answers grouped by questionId, in catalog order.
    private var openGroups: [(question: FeedbackQuestion, items: [(response: FeedbackResponse, answer: FeedbackAnswer)])] {
        var map: [String: [(FeedbackResponse, FeedbackAnswer)]] = [:]
        for response in responses {
            for answer in response.answers {
                guard let q = FeedbackQuestion.catalog.first(where: { $0.id == answer.questionId }),
                      q.type == .open || q.type == .milestone
                else { continue }
                map[q.id, default: []].append((response, answer))
            }
        }
        return FeedbackQuestion.catalog
            .filter { map[$0.id] != nil }
            .compactMap { q in
                guard let items = map[q.id] else { return nil }
                return (q, items.sorted { $0.0.date < $1.0.date })
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Client header
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(ContinuoTheme.terracotta.opacity(0.12)).frame(width: 38, height: 38)
                    Text(initials).font(ContinuoTheme.rounded(13, weight: .bold)).foregroundColor(ContinuoTheme.terracotta)
                }
                Text(clientName)
                    .font(ContinuoTheme.rounded(17, weight: .semibold))
                    .foregroundColor(ContinuoTheme.charcoal)
                Spacer()
                Text("\(responses.count) form\(responses.count == 1 ? "" : "s")")
                    .font(ContinuoTheme.rounded(12))
                    .foregroundColor(ContinuoTheme.textMedium)
            }

            // Rating questions
            if !aggregates.isEmpty {
                Text("Ratings")
                    .font(ContinuoTheme.rounded(13, weight: .semibold))
                    .foregroundColor(ContinuoTheme.textMedium)
                    .padding(.top, 2)

                ForEach(aggregates) { agg in
                    AggregateCard(aggregate: agg)
                }
            }

            // Open & milestone questions
            if !openGroups.isEmpty {
                Text("Open & Milestone")
                    .font(ContinuoTheme.rounded(13, weight: .semibold))
                    .foregroundColor(ContinuoTheme.textMedium)
                    .padding(.top, aggregates.isEmpty ? 2 : 8)

                ForEach(openGroups.indices, id: \.self) { i in
                    let group = openGroups[i]
                    ExpandableOpenQuestion(
                        question: group.question,
                        items: group.items.map { ($0.0, $0.1) }
                    )
                }
            }

            if aggregates.isEmpty && openGroups.isEmpty {
                Text("No answers yet.")
                    .font(ContinuoTheme.rounded(13))
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
    }

    private var initials: String {
        let parts = clientName.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased() }
        return String(clientName.prefix(2)).uppercased()
    }
}
