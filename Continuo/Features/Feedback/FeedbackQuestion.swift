import SwiftUI

// MARK: - Question type

enum FeedbackQuestionType: String, Codable {
    case rating    // 1–10
    case milestone // Behind / On Track / Ahead
    case open      // free text
}

// MARK: - Static question

struct FeedbackQuestion: Identifiable {
    let id: String
    let category: String
    let text: String
    let type: FeedbackQuestionType

    // MARK: - Full catalog

    static let catalog: [FeedbackQuestion] = [

        // ── 1. Session Experience ────────────────────────────────────────────
        FeedbackQuestion(id: "se_useful",     category: "Session Experience", text: "How useful was today's session for you?",                                                                                              type: .rating),
        FeedbackQuestion(id: "se_present",    category: "Session Experience", text: "How present and focused did you feel during our conversation?",                                                                        type: .rating),
        FeedbackQuestion(id: "se_safe",       category: "Session Experience", text: "How safe did you feel to be fully honest in this session?",                                                                            type: .rating),
        FeedbackQuestion(id: "se_worked",     category: "Session Experience", text: "What worked well in today's session?",                                                                                                 type: .open),
        FeedbackQuestion(id: "se_not_worked", category: "Session Experience", text: "What didn't work for you in this session?",                                                                                            type: .open),
        FeedbackQuestion(id: "se_valuable",   category: "Session Experience", text: "What was the most valuable moment in our conversation?",                                                                               type: .open),
        FeedbackQuestion(id: "se_value",      category: "Session Experience", text: "Has our conversation / coaching relationship brought you value? If yes, how do you know? If not, why do you think that happened?",    type: .open),

        // ── 2. Progress & Goals ─────────────────────────────────────────────
        FeedbackQuestion(id: "pg_milestone",  category: "Progress & Goals",   text: "Overall progress toward your goals",                                                                                                   type: .milestone),
        FeedbackQuestion(id: "pg_achieving",  category: "Progress & Goals",   text: "How well are you achieving your objectives?",                                                                                          type: .rating),
        FeedbackQuestion(id: "pg_progress",   category: "Progress & Goals",   text: "How much progress do you feel you've made toward your goal?",                                                                          type: .rating),
        FeedbackQuestion(id: "pg_clarity",    category: "Progress & Goals",   text: "How clear do you feel about your next steps?",                                                                                         type: .rating),
        FeedbackQuestion(id: "pg_feel",       category: "Progress & Goals",   text: "How do you feel about the progress you've made so far?",                                                                               type: .open),
        FeedbackQuestion(id: "pg_stuck",      category: "Progress & Goals",   text: "Where are you stuck and not making enough progress?",                                                                                  type: .open),
        FeedbackQuestion(id: "pg_unclear",    category: "Progress & Goals",   text: "What is still unclear or unresolved for you?",                                                                                         type: .open),

        // ── 3. Reflection & Growth ──────────────────────────────────────────
        FeedbackQuestion(id: "rg_lessons",    category: "Reflection & Growth", text: "Looking back, what are your 2–3 most important lessons?",                                                                             type: .open),
        FeedbackQuestion(id: "rg_changed",    category: "Reflection & Growth", text: "In what ways have you changed as a person in recent months?",                                                                         type: .open),
        FeedbackQuestion(id: "rg_learned",    category: "Reflection & Growth", text: "What have you learned about yourself through our work together?",                                                                     type: .open),
        FeedbackQuestion(id: "rg_proud",      category: "Reflection & Growth", text: "What are the achievements you are most proud of?",                                                                                    type: .open),
        FeedbackQuestion(id: "rg_contrib",    category: "Reflection & Growth", text: "Who has made an important contribution to your life in recent months, and how have they helped you?",                                 type: .open),
        FeedbackQuestion(id: "rg_conclusion", category: "Reflection & Growth", text: "What is the conclusion of this review?",                                                                                              type: .open),

        // ── 4. Coaching Relationship ────────────────────────────────────────
        FeedbackQuestion(id: "cr_understand", category: "Coaching Relationship", text: "How well do you feel I understand you and your situation?",                                                                          type: .rating),
        FeedbackQuestion(id: "cr_challenged", category: "Coaching Relationship", text: "How challenged do you feel in our sessions?",                                                                                        type: .rating),
        FeedbackQuestion(id: "cr_supported",  category: "Coaching Relationship", text: "How supported do you feel in our coaching relationship?",                                                                            type: .rating),
        FeedbackQuestion(id: "cr_describe",   category: "Coaching Relationship", text: "How would you describe our relationship? In your own words, as you feel it.",                                                       type: .open),
        FeedbackQuestion(id: "cr_needs",      category: "Coaching Relationship", text: "What needs do you have from me that aren't yet sufficiently met?",                                                                   type: .open),
        FeedbackQuestion(id: "cr_strength",   category: "Coaching Relationship", text: "What do you think is my strongest point in our coaching sessions?",                                                                  type: .open),
        FeedbackQuestion(id: "cr_style",      category: "Coaching Relationship", text: "How would you describe my coaching style?",                                                                                          type: .open),
        FeedbackQuestion(id: "cr_different",  category: "Coaching Relationship", text: "Is there anything you'd like me to do differently as your coach?",                                                                   type: .open),
        FeedbackQuestion(id: "cr_unsaid",     category: "Coaching Relationship", text: "Is there something you haven't said yet that you'd like me to know?",                                                                type: .open),

        // ── 5. Coaching Process ─────────────────────────────────────────────
        FeedbackQuestion(id: "cp_frequency",  category: "Coaching Process",   text: "How well does the frequency of our sessions work for you?",                                                                             type: .rating),
        FeedbackQuestion(id: "cp_format",     category: "Coaching Process",   text: "How well does the format of our sessions work for you?",                                                                                type: .rating),
        FeedbackQuestion(id: "cp_overall",    category: "Coaching Process",   text: "How would you rate our overall coaching process so far?",                                                                               type: .rating),
        FeedbackQuestion(id: "cp_team",       category: "Coaching Process",   text: "What works best about the way we work together as a team?",                                                                            type: .open),
        FeedbackQuestion(id: "cp_improve",    category: "Coaching Process",   text: "What would you like us to improve about our process?",                                                                                 type: .open),
        FeedbackQuestion(id: "cp_better",     category: "Coaching Process",   text: "What would make our coaching process work better for you?",                                                                            type: .open),

        // ── 6. Looking Forward ──────────────────────────────────────────────
FeedbackQuestion(id: "lf_describe",   category: "Looking Forward",    text: "How would you describe the value of our coaching to someone else?",                                                                     type: .open),
        FeedbackQuestion(id: "lf_proud",      category: "Looking Forward",    text: "What are you most proud of since we started?",                                                                                          type: .open)
    ]

    static let categories: [String] = {
        var seen = Set<String>()
        return catalog.compactMap { q in
            seen.insert(q.category).inserted ? q.category : nil
        }
    }()

    static func questions(in category: String) -> [FeedbackQuestion] {
        catalog.filter { $0.category == category }
    }
}

// MARK: - Milestone values

enum MilestoneValue: String, CaseIterable {
    case behind   = "behind"
    case onTrack  = "on_track"
    case ahead    = "ahead"

    var label: String {
        switch self {
        case .behind:  return "Behind"
        case .onTrack: return "On Track"
        case .ahead:   return "Ahead"
        }
    }

    var color: Color {
        switch self {
        case .behind:  return Color(hex: "C0392B")
        case .onTrack: return Color(hex: "4E7040")
        case .ahead:   return Color(hex: "2E7DD1")
        }
    }

    var emoji: String {
        switch self {
        case .behind:  return "🔴"
        case .onTrack: return "🟢"
        case .ahead:   return "🔵"
        }
    }
}
