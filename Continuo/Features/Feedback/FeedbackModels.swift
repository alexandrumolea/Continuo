import Foundation
import FirebaseFirestore

// MARK: - Answer (one question's answer inside a response)

struct FeedbackAnswer: Codable {
    var questionId: String
    var ratingValue: Int?       // 1–10, for .rating questions
    var milestoneValue: String? // "behind" | "on_track" | "ahead"
    var openText: String?       // free text
}

// MARK: - Form (sent by coach to client)

struct FeedbackForm: Identifiable {
    var id: String
    var coachId: String
    var clientId: String
    var questionIds: [String]
    var sentAt: Timestamp
    var status: FeedbackFormStatus

    var date: Date { sentAt.dateValue() }
    var questionCount: Int { questionIds.count }
}

enum FeedbackFormStatus: String {
    case pending   = "pending"
    case completed = "completed"
}

// MARK: - Response (submitted by client)

struct FeedbackResponse: Identifiable {
    var id: String          // same as formId
    var formId: String
    var coachId: String
    var clientId: String
    var clientName: String
    var answers: [FeedbackAnswer]
    var completedAt: Timestamp

    var date: Date { completedAt.dateValue() }
}

// MARK: - Aggregate (per question, computed across all responses for a coach)

struct QuestionAggregate: Identifiable {
    var id: String { questionId }
    let questionId: String
    let questionText: String
    let average: Double
    let responseCount: Int
    let history: [(date: Date, value: Double, clientName: String)]  // sorted oldest→newest
}
