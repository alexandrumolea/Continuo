import Foundation
import FirebaseFirestore

final class FeedbackService {
    static let shared = FeedbackService()
    private let db = Firestore.firestore()

    // MARK: - Coach: send a form

    func sendForm(coachId: String, clientId: String, questionIds: [String]) {
        let id = UUID().uuidString
        let data: [String: Any] = [
            "id":          id,
            "coachId":     coachId,
            "clientId":    clientId,
            "questionIds": questionIds,
            "sentAt":      Timestamp(date: Date()),
            "status":      FeedbackFormStatus.pending.rawValue
        ]
        db.collection("feedbackForms").document(id).setData(data)
    }

    // MARK: - Client: pending forms listener

    func pendingFormsListener(
        clientId: String,
        onChange: @escaping ([FeedbackForm]) -> Void
    ) -> ListenerRegistration {
        db.collection("feedbackForms")
            .whereField("clientId",  isEqualTo: clientId)
            .whereField("status",    isEqualTo: FeedbackFormStatus.pending.rawValue)
            .addSnapshotListener { snap, _ in
                onChange((snap?.documents ?? []).compactMap(Self.decodeForm))
            }
    }

    // MARK: - Client: submit a response

    func submitResponse(
        form: FeedbackForm,
        clientName: String,
        answers: [FeedbackAnswer]
    ) {
        // Encode answers as [[String:Any]]
        let encodedAnswers: [[String: Any]] = answers.map { a in
            var d: [String: Any] = ["questionId": a.questionId]
            if let r = a.ratingValue     { d["ratingValue"]    = r }
            if let m = a.milestoneValue  { d["milestoneValue"] = m }
            if let t = a.openText, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                d["openText"] = t
            }
            return d
        }

        let responseData: [String: Any] = [
            "formId":       form.id,
            "coachId":      form.coachId,
            "clientId":     form.clientId,
            "clientName":   clientName,
            "answers":      encodedAnswers,
            "completedAt":  Timestamp(date: Date())
        ]
        db.collection("feedbackResponses").document(form.id).setData(responseData)
        db.collection("feedbackForms").document(form.id).updateData(["status": FeedbackFormStatus.completed.rawValue])
    }

    // MARK: - Coach: responses for one client

    func responsesListener(
        coachId: String,
        clientId: String,
        onChange: @escaping ([FeedbackResponse]) -> Void
    ) -> ListenerRegistration {
        db.collection("feedbackResponses")
            .whereField("coachId",  isEqualTo: coachId)
            .whereField("clientId", isEqualTo: clientId)
            .addSnapshotListener { snap, _ in
                let responses = (snap?.documents ?? []).compactMap(Self.decodeResponse)
                    .sorted { $0.completedAt.dateValue() > $1.completedAt.dateValue() }
                onChange(responses)
            }
    }

    // MARK: - Coach: all responses (for aggregate dashboard)

    func allResponsesListener(
        coachId: String,
        onChange: @escaping ([FeedbackResponse]) -> Void
    ) -> ListenerRegistration {
        db.collection("feedbackResponses")
            .whereField("coachId", isEqualTo: coachId)
            .addSnapshotListener { snap, _ in
                let responses = (snap?.documents ?? []).compactMap(Self.decodeResponse)
                    .sorted { $0.completedAt.dateValue() < $1.completedAt.dateValue() }
                onChange(responses)
            }
    }

    // MARK: - Coach: sent forms for one client

    func sentFormsListener(
        coachId: String,
        clientId: String,
        onChange: @escaping ([FeedbackForm]) -> Void
    ) -> ListenerRegistration {
        db.collection("feedbackForms")
            .whereField("coachId",  isEqualTo: coachId)
            .whereField("clientId", isEqualTo: clientId)
            .addSnapshotListener { snap, _ in
                let forms = (snap?.documents ?? []).compactMap(Self.decodeForm)
                    .sorted { $0.sentAt.dateValue() > $1.sentAt.dateValue() }
                onChange(forms)
            }
    }

    // MARK: - Aggregate computation (pure, called after fetching all responses)

    static func computeAggregates(from responses: [FeedbackResponse]) -> [QuestionAggregate] {
        // Group history entries per questionId (rating only)
        var historyMap: [String: [(date: Date, value: Double, clientName: String)]] = [:]

        for response in responses {
            for answer in response.answers {
                guard let rating = answer.ratingValue else { continue }
                let entry = (date: response.date, value: Double(rating), clientName: response.clientName)
                historyMap[answer.questionId, default: []].append(entry)
            }
        }

        return historyMap.compactMap { questionId, history in
            guard let question = FeedbackQuestion.catalog.first(where: { $0.id == questionId }) else { return nil }
            let sorted = history.sorted { $0.date < $1.date }
            let avg = sorted.map(\.value).reduce(0, +) / Double(sorted.count)
            return QuestionAggregate(
                questionId: questionId,
                questionText: question.text,
                average: avg,
                responseCount: sorted.count,
                history: sorted
            )
        }
        .sorted { $0.questionText < $1.questionText }
    }

    // MARK: - Decoders

    nonisolated private static func decodeForm(_ doc: QueryDocumentSnapshot) -> FeedbackForm? {
        let d = doc.data()
        guard
            let id          = d["id"]          as? String,
            let coachId     = d["coachId"]     as? String,
            let clientId    = d["clientId"]    as? String,
            let questionIds = d["questionIds"] as? [String],
            let sentAt      = d["sentAt"]      as? Timestamp,
            let statusRaw   = d["status"]      as? String,
            let status      = FeedbackFormStatus(rawValue: statusRaw)
        else { return nil }
        return FeedbackForm(id: id, coachId: coachId, clientId: clientId,
                            questionIds: questionIds, sentAt: sentAt, status: status)
    }

    nonisolated private static func decodeResponse(_ doc: QueryDocumentSnapshot) -> FeedbackResponse? {
        let d = doc.data()
        guard
            let formId      = d["formId"]      as? String,
            let coachId     = d["coachId"]     as? String,
            let clientId    = d["clientId"]    as? String,
            let completedAt = d["completedAt"] as? Timestamp
        else { return nil }

        let rawAnswers = (d["answers"] as? [[String: Any]]) ?? []
        let answers: [FeedbackAnswer] = rawAnswers.compactMap { a in
            guard let qId = a["questionId"] as? String else { return nil }
            return FeedbackAnswer(
                questionId:     qId,
                ratingValue:    a["ratingValue"]    as? Int,
                milestoneValue: a["milestoneValue"] as? String,
                openText:       a["openText"]       as? String
            )
        }

        return FeedbackResponse(
            id: formId,
            formId: formId,
            coachId: coachId,
            clientId: clientId,
            clientName: (d["clientName"] as? String) ?? "Client",
            answers: answers,
            completedAt: completedAt
        )
    }

    // MARK: - Coach: delete a form + its response

    func deleteForm(formId: String) {
        db.collection("feedbackForms").document(formId).delete()
        db.collection("feedbackResponses").document(formId).delete()
    }
}
