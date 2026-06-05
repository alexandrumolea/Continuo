import SwiftUI
import FirebaseFirestore

// MARK: - Practice type

enum CoachPracticeType {
    case questionList([String])
    case reflectionForm([String])
    case comingSoon
}

// MARK: - Practice model

struct CoachPractice: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let category: String
    let categoryColor: Color
    let cardColor: Color
    let subtitle: String
    let type: CoachPracticeType

    static let catalog: [CoachPractice] = [
        CoachPractice(
            id: "coaching_contract_relationship",
            title: "Setting Up the Relationship",
            emoji: "🤝",
            category: "A Good Coaching Contract",
            categoryColor: Color(hex: "2E7DD1"),
            cardColor: Color(hex: "E8F2FD"),
            subtitle: "Explore questions that strengthen the coaching alliance.",
            type: .questionList([
                "What are your needs in a relationship?",
                "What is important to you in a coaching relationship?",
                "How do we know our relationship is successful?",
                "How often should we check in to see how the process is working for you?",
                "What are your needs when working with a coach?",
                "What would you like us to do if at some point something difficult happens in our session?",
                "How would we know I've accompanied you well in this conversation?",
                "What expectations do you have of yourself, and of me, in this session / coaching framework?",
                "How do you like to be challenged?",
                "How would you like this session to unfold?",
                "If something triggers you, what would you like us to do, or what would you like me to do?",
                "I notice X in our coaching practice (maybe that the client keeps coming up with new subjects and the old ones are not solved). How do you see this? How do you think it would be best to proceed?",
                "How will I know if you've reached a limit beyond which you don't want to be challenged anymore?",
                "Considering our differences (in age, ethnicity, sex) — how do you think this could influence our coaching process?"
            ])
        ),
        CoachPractice(
            id: "coaching_contract_session",
            title: "Setting Up the Session",
            emoji: "🎙️",
            category: "A Good Coaching Contract",
            categoryColor: Color(hex: "4E7040"),
            cardColor: Color(hex: "EBF3E6"),
            subtitle: "Questions to open and frame each coaching session.",
            type: .comingSoon
        ),
        CoachPractice(
            id: "session_reflection",
            title: "Session Reflection",
            emoji: "🪞",
            category: "After Coaching",
            categoryColor: Color(hex: "7B5EA7"),
            cardColor: Color(hex: "F3EFFE"),
            subtitle: "Reflect on what happened and what you're learning.",
            type: .reflectionForm([
                "How was the session? What was the client's subject?",
                "What did you do well?",
                "What did you do wrong?",
                "If you were in the exact same situation, what would you do differently? Specifically, how would you say things?",
                "What did you learn about yourself? How is your client's situation connected to your life?"
            ])
        )
    ]
}

// MARK: - Practice Entry (stored in Firestore)

struct CoachPracticeEntry: Identifiable {
    var id: String
    var practiceId: String
    var practiceTitle: String
    var practiceEmoji: String
    var questionText: String?       // set for question-list type
    var responses: [String: String] // prompt → answer
    var createdAt: Timestamp

    var date: Date { createdAt.dateValue() }

    var firstResponse: String? {
        responses.values.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
