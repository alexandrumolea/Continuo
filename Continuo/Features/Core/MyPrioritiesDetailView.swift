import SwiftUI
import FirebaseFirestore

struct MyPrioritiesDetailView: View {
    let userId: String

    @State private var priorities: [PersonalPriority] = []
    @State private var listener: ListenerRegistration?
    @State private var newPriorityText = ""
    @FocusState private var inputFocused: Bool

    private let color = Color(hex: "C4873A")
    private let guidingQuestions = [
        "Time is limited. Where do you want to make sure you invest during this period of your life?",
        "What matters most to you in life?",
        "What makes you unhappy if you ignore it?",
        "What are your priorities and what is their order?"
    ]

    private var canAdd: Bool {
        !newPriorityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ContinuoTheme.background.ignoresSafeArea()
            BackgroundOrbs()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("📌")
                            .font(.system(size: 44))
                        Text("My Priorities")
                            .font(ContinuoTheme.rounded(28, weight: .bold))
                            .foregroundColor(ContinuoTheme.charcoal)
                        Text("Ordered by what matters most — reorder anytime")
                            .font(ContinuoTheme.rounded(13))
                            .foregroundColor(color.opacity(0.7))
                    }
                    .padding(.top, 4)

                    // ── Priorities list ──
                    if !priorities.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your priorities")
                                .font(ContinuoTheme.rounded(15, weight: .semibold))
                                .foregroundColor(ContinuoTheme.charcoal)

                            prioritiesList
                        }
                    }

                    // ── Add priority ──
                    VStack(alignment: .leading, spacing: 8) {
                        Text(priorities.isEmpty ? "Add your first priority" : "Add another priority")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)

                        HStack(spacing: 10) {
                            TextField("e.g. Family, Health, Career…", text: $newPriorityText)
                                .font(ContinuoTheme.rounded(14))
                                .foregroundColor(ContinuoTheme.charcoal)
                                .focused($inputFocused)
                                .submitLabel(.done)
                                .onSubmit { addPriority() }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.88))
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                inputFocused
                                                    ? color.opacity(0.5)
                                                    : Color(hex: "EDE8E0"),
                                                lineWidth: 1.5
                                            ))
                                )

                            Button(action: addPriority) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(canAdd ? color : ContinuoTheme.textLight)
                            }
                            .disabled(!canAdd)
                        }

                        if !priorities.isEmpty {
                            Text("Use ↑ ↓ to reorder")
                                .font(ContinuoTheme.rounded(11))
                                .foregroundColor(ContinuoTheme.textLight)
                        }
                    }

                    // ── Guiding questions ──
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Guiding questions")
                            .font(ContinuoTheme.rounded(15, weight: .semibold))
                            .foregroundColor(ContinuoTheme.charcoal)

                        ForEach(Array(guidingQuestions.enumerated()), id: \.offset) { idx, q in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 28, height: 28)
                                    Text("\(idx + 1)")
                                        .font(ContinuoTheme.rounded(12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Text(q)
                                    .font(ContinuoTheme.rounded(14))
                                    .foregroundColor(ContinuoTheme.charcoal)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(color.opacity(0.06))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(color.opacity(0.18), lineWidth: 1))
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            listener = PrioritiesService.shared.prioritiesListener(userId: userId) { priorities = $0 }
        }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Priorities list

    private var prioritiesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(priorities.enumerated()), id: \.element.id) { idx, priority in
                priorityRow(priority, index: idx)
                if idx < priorities.count - 1 {
                    Divider()
                        .padding(.horizontal, 16)
                        .opacity(0.4)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "EDE8E0"), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func priorityRow(_ priority: PersonalPriority, index: Int) -> some View {
        HStack(spacing: 12) {
            // Position badge
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                Text("\(index + 1)")
                    .font(ContinuoTheme.rounded(13, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(priority.text)
                .font(ContinuoTheme.rounded(14, weight: .medium))
                .foregroundColor(ContinuoTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Reorder controls
            VStack(spacing: 0) {
                Button {
                    movePriority(from: index, to: index - 1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(index > 0 ? color : color.opacity(0.2))
                        .frame(width: 32, height: 24)
                }
                .disabled(index == 0)

                Button {
                    movePriority(from: index, to: index + 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(index < priorities.count - 1 ? color : color.opacity(0.2))
                        .frame(width: 32, height: 24)
                }
                .disabled(index == priorities.count - 1)
            }

            // Delete
            Button {
                deletePriority(priority)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ContinuoTheme.textLight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Actions

    private func addPriority() {
        let text = newPriorityText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let nextOrder = (priorities.max(by: { $0.order < $1.order })?.order ?? -1) + 1
        let p = PersonalPriority(userId: userId, text: text, order: nextOrder, createdAt: Date())
        try? PrioritiesService.shared.addPriority(p)
        newPriorityText = ""
    }

    private func movePriority(from source: Int, to destination: Int) {
        guard destination >= 0, destination < priorities.count else { return }
        var updated = priorities
        let item = updated.remove(at: source)
        updated.insert(item, at: destination)
        priorities = updated   // Optimistic immediate update
        Task { try? await PrioritiesService.shared.reorder(priorities: updated) }
    }

    private func deletePriority(_ priority: PersonalPriority) {
        let remaining = priorities.filter { $0.id != priority.id }
        priorities = remaining   // Optimistic immediate update
        Task {
            try? await PrioritiesService.shared.deletePriority(priority)
            try? await PrioritiesService.shared.reorder(priorities: remaining)
        }
    }
}
