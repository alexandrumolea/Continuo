import SwiftUI
import FirebaseFirestore

// MARK: - Supporting types

struct CoachQuestionCategory: Identifiable {
    let id: String          // kebab-case slug
    let name: String
    let questions: [String]
}

enum CoachPracticeType {
    case questionRandomizer([String])
    case categoryRandomizer([CoachQuestionCategory])
    case reflectionForm([String])
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

        // ── Session Reflection ───────────────────────────────────────────────
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
        ),

        // ── Setting Up the Relationship ──────────────────────────────────────
        CoachPractice(
            id: "coaching_contract_relationship",
            title: "Setting Up the Relationship",
            emoji: "🤝",
            category: "A Good Coaching Contract",
            categoryColor: Color(hex: "2E7DD1"),
            cardColor: Color(hex: "E8F2FD"),
            subtitle: "Highlight a question to use in building the coaching alliance.",
            type: .questionRandomizer([
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

        // ── Setting Up the Session ───────────────────────────────────────────
        CoachPractice(
            id: "coaching_contract_session",
            title: "Setting Up the Session",
            emoji: "🎙️",
            category: "A Good Coaching Contract",
            categoryColor: Color(hex: "4E7040"),
            cardColor: Color(hex: "EBF3E6"),
            subtitle: "Highlight a question to open and frame your next session.",
            type: .questionRandomizer([
                "If this session brought you a significant progress, what would that be?",
                "Imagine this session brought you exactly what you needed. You look back at it and you are really happy we had this conversation. How would you recognize that?",
                "What do you notice differently?",
                "How does the ideal solution look for you?",
                "Magic wand: If you had a magic wand and could do anything, what would you do? If you could create the situation exactly as you want it, how would you rearrange things?",
                "How will you recognize that this conversation has been useful for you?",
                "What do you want to achieve by the end of this session?",
                "What would need to happen for you by the end of this conversation so that you feel you've taken an important step toward your goal?",
                "What is important today in our session?",
                "What is an outcome you would like to take away from this session?",
                "What is a current specific situation that perfectly reflects the subject you want to work on today?",
                "What is one concrete thing you want to get out of this conversation?",
                "Let's suppose that at some point from now on, things work out very well for you. What would you be doing differently then?",
                "Travel to the future: Let's suppose that a year from now, you look back and smile — with gratitude — thinking about how easily you resolved this situation for good. You realize this session was a complete breakthrough for you. What happened in it that managed to completely shift your direction?",
                "Six months have passed and you are perfectly satisfied. Can you describe what things look like?",
                "Let's suppose you succeeded and are now truly at your best. What do others recognize in you?",
                "What does a truly good outcome look like?",
                "How do we measure success?",
                "How do we know / recognize that we've arrived there?",
                "You wake up and suddenly this goal is achieved. What do you notice that's different? What do others notice?",
                "How would this situation look if it were already solved?",
                "What do you truly truly want in this situation?",
                "What achievement would fill you with joy?",
                "What topic are we discussing and what deadline would be appropriate?",
                "Imagine you've already made progress. What benefits will that bring you?",
                "What is your intention for this conversation? (Coach adds a synthesis: \"So, this? Please correct me if I'm wrong.\")"
            ])
        ),

        // ── Perspective Change ───────────────────────────────────────────────
        CoachPractice(
            id: "perspective_change",
            title: "Perspective Change",
            emoji: "🔭",
            category: "Coaching Toolkit",
            categoryColor: Color(hex: "C87B3E"),
            cardColor: Color(hex: "FEF0E6"),
            subtitle: "Highlight a category of reframing questions to explore in your sessions.",
            type: .categoryRandomizer([
                CoachQuestionCategory(id: "leverage", name: "Leverage & Prioritization", questions: [
                    "I hear that this situation feels complex. If you could resolve just one thing, which resolution would have the greatest impact on your goal?",
                    "Looking at everything that's happening, what is the leverage point?",
                    "If one thing shifted, what would create the greatest ripple effect?",
                    "Which 20% of these ideas would make the biggest difference?"
                ]),
                CoachQuestionCategory(id: "presence", name: "Presence", questions: [
                    "Imagine the meeting, the decision, or the people involved are all here in the room with us right now. What do you do?",
                    "What would it mean to move from reactiveness to presence?",
                    "What becomes available when you move from reactiveness to presence?",
                    "What would presence look like right now?",
                    "Can you accept yourself exactly where you are right now?"
                ]),
                CoachQuestionCategory(id: "higher-order", name: "Higher Order Plane", questions: [
                    "What higher-order goal is impacted by this situation?",
                    "How does this affect other areas of your life or other plans?",
                    "When you step back and look at the bigger picture, what do you see?"
                ]),
                CoachQuestionCategory(id: "teleology", name: "Teleology", questions: [
                    "What purpose might this situation be serving in your life right now?",
                    "What purpose might this behaviour be serving in your life right now?",
                    "What is the growth opportunity for you here?",
                    "What is this situation asking from you?"
                ]),
                CoachQuestionCategory(id: "responsibility", name: "Responsibility & Agency", questions: [
                    "What is 100% within your control?",
                    "Whose responsibility is it to resolve this situation?",
                    "What is your part?",
                    "In what ways are you contributing to this situation?",
                    "What would it mean to stop contributing?"
                ]),
                CoachQuestionCategory(id: "assumptions", name: "Assumptions & Meaning-Making", questions: [
                    "What assumptions might you be making that you're not yet aware of?",
                    "How are those assumptions creating what you observe?",
                    "What new possibilities could you invent?",
                    "What made you believe this?",
                    "If this is what's visible on the surface, what might be underneath?"
                ]),
                CoachQuestionCategory(id: "perspective-shifts", name: "Perspective Shifts", questions: [
                    "If you became the person or situation causing your stress, how would things look from there?",
                    "If you were a fly on the wall, what would you notice?",
                    "What would you do differently with that perspective?",
                    "If this situation happened at home with your spouse or child, how would it look?"
                ]),
                CoachQuestionCategory(id: "inside-out", name: "Inside-Out / Outside-In", questions: [
                    "How is what you're experiencing internally reflected in your external world?",
                    "How does what is happening externally affect what is happening internally?",
                    "If someone observed your life from the outside, how would they notice what is happening inside you?",
                    "Where do you notice alignment between your inner and outer worlds?",
                    "Where do you notice a gap?",
                    "What would greater alignment look like?"
                ]),
                CoachQuestionCategory(id: "emotions", name: "Emotions & Compassion", questions: [
                    "How does this make you feel?",
                    "How is this showing up inside of you?",
                    "What would it mean to meet your scared part with compassion?",
                    "If sadness, fear, anger, or joy were perfect indicators, what would they be telling you?"
                ]),
                CoachQuestionCategory(id: "mind-heart-gut", name: "Mind – Heart – Gut", questions: [
                    "What does your mind say?",
                    "What does your heart say?",
                    "What does your gut say?"
                ]),
                CoachQuestionCategory(id: "resources", name: "Resources & Strengths", questions: [
                    "What gives you confidence that this goal is achievable?",
                    "What do you know about yourself that reassures you that you can handle this?",
                    "Tell me about a time when you achieved something similar.",
                    "What exactly did you do?",
                    "How did you resolve a similar situation in the past?",
                    "What strengths do your family and friends appreciate in you?",
                    "How could you use those strengths here?",
                    "What personal qualities will help you achieve the outcome you want?",
                    "What resources do you see in yourself?",
                    "What resources do others see in you?",
                    "What resources do I see in you?"
                ]),
                CoachQuestionCategory(id: "patterns", name: "Patterns & Awareness", questions: [
                    "Where else in your life do you see this pattern?",
                    "What does this situation teach you about yourself?"
                ]),
                CoachQuestionCategory(id: "identity", name: "Identity", questions: [
                    "Who do you want to be in this situation?",
                    "Who do you want to become through this experience?",
                    "What does a person like that do?"
                ]),
                CoachQuestionCategory(id: "metaphor", name: "Metaphor & Symbolic Work", questions: [
                    "If this situation were a metaphor, what would it be?",
                    "A metaphor comes to mind as I listen. Would you like to explore it together?",
                    "How does it look from your perspective?",
                    "If this confusion existed outside of you, what would it look like?"
                ]),
                CoachQuestionCategory(id: "shadow", name: "Shadow & Avoidance", questions: [
                    "What might you be hiding from yourself or others?",
                    "What are you trying to avoid?",
                    "If your \"nasty self\" showed up, what would it do differently?"
                ]),
                CoachQuestionCategory(id: "systems", name: "Systems Thinking", questions: [
                    "How are you coordinating your efforts with others?",
                    "What communication channels exist?",
                    "How well are they functioning?",
                    "How does information flow?",
                    "Looking at the whole system, where is the leverage point?",
                    "If that person were standing here in your place, what would they say about this situation?",
                    "Who is supporting you in this situation?",
                    "Who could help you move this forward?",
                    "Who wants you to succeed?",
                    "What conversations are missing from your support system?"
                ]),
                CoachQuestionCategory(id: "possibilities", name: "Possibilities & Vision", questions: [
                    "What is the best possible outcome?",
                    "What positive consequences might emerge when you achieve your goal?",
                    "Who else benefits, and how?",
                    "What would this look like at maximum potential?"
                ]),
                CoachQuestionCategory(id: "consequences", name: "Consequences & Choice", questions: [
                    "What if nothing changed?",
                    "If nothing changed over the next six months, what would happen?",
                    "What is the cost of staying exactly where you are?",
                    "What benefits are you getting from staying exactly where you are?",
                    "What would become possible if this changed?"
                ]),
                CoachQuestionCategory(id: "action", name: "Action & Progress", questions: [
                    "What have you already accomplished?",
                    "What would indicate progress?",
                    "How will you track progress?",
                    "When would be a good time to take the first step?"
                ]),
                CoachQuestionCategory(id: "partnership", name: "Partnership", questions: [
                    "What could I do in this conversation to make it feel like a constructive partnership?",
                    "What can we change in our conversation right now to create more of what you need (more presence, teamwork, challenge, clarity, focus, safety, or anything else that feels missing in the relationship)?",
                    "How are things going so far?",
                    "What is missing from our conversation right now?",
                    "What would make this conversation more useful for you at this moment?"
                ]),
                CoachQuestionCategory(id: "journey", name: "Journey & Appreciation", questions: [
                    "When did this journey begin?",
                    "Where did you start?",
                    "How far have you come?",
                    "What has worked best so far?",
                    "Who would you like to thank when you reach your goal?",
                    "Taking a helicopter view over this issue in your life, how do you see this in the timeline of your whole life?"
                ])
            ])
        ),

        // ── Tracking ────────────────────────────────────────────────────────
        CoachPractice(
            id: "tracking",
            title: "Tracking",
            emoji: "📈",
            category: "Coaching Toolkit",
            categoryColor: Color(hex: "C87B3E"),
            cardColor: Color(hex: "FEF0E6"),
            subtitle: "Highlight a category of questions to monitor progress and sustain momentum.",
            type: .categoryRandomizer([
                CoachQuestionCategory(id: "motivation", name: "Facilitating Motivation", questions: [
                    "Just do a simple synthesis (focusing on the process, not the content).",
                    "You set out to... (coachee's goal) and you've been working on it for 2 weeks. We are now halfway through our coaching journey.",
                    "If you were to self-evaluate your progress, where do you stand right now in relation to your goal?",
                    "On a scale of 1 to 10, where are you right now in relation to your goal?"
                ]),
                CoachQuestionCategory(id: "reflection-learning", name: "Facilitating Reflection & Learning", questions: [
                    "What wins have you experienced so far?",
                    "What did you do well? What has worked well for you?",
                    "What do you feel made the biggest difference, and you want to keep doing?",
                    "How do you feel right now in relation to this goal?"
                ]),
                CoachQuestionCategory(id: "decisions", name: "Facilitating Decisions", questions: [
                    "You mentioned you are around a 6/10. What would a 7 look like?",
                    "What are you planning on doing next? What are your next steps?"
                ])
            ])
        ),

        // ── Action Planning ──────────────────────────────────────────────────
        CoachPractice(
            id: "action_planning",
            title: "Action Planning",
            emoji: "🧭",
            category: "Coaching Toolkit",
            categoryColor: Color(hex: "2D9B8A"),
            cardColor: Color(hex: "E6F6F4"),
            subtitle: "Highlight a closing question to anchor insight and next steps.",
            type: .questionRandomizer([
                "How would you sum up our conversation from your perspective?",
                "What is most important to you out of everything we've been through in this conversation?",
                "What are the key takeaways for you from this session?",
                "Closing the loop — where are you now compared to where you started?",
                "So, what is becoming clearer to you as a result of our discussion? What are your conclusions?",
                "Where do you stand right now in relation to your goal?",
                "We are approaching the end of the session — what else do you need to feel like you're moving forward with determination and energy?",
                "What else needs to happen before the end of this session to support your goal?",
                "What do you want to do after this session? What is your next step?",
                "What do you plan to do next? How will you do it? When do you want to do it?",
                "What is one risk you see? How do you plan to address it?",
                "If there were a weak link or vulnerability in your plan, what would it be? How will you manage it?",
                "Looking back at our conversation, what have you learned about yourself today?",
                "I hear your insight — how will you act on it so that you make sure you integrate it in your life?",
                "I hear your insight — what needs to change in your life or actions so that you make sure you capitalise on it?",
                "I hear your insight — what are you going to do differently in practice with it?",
                "What do you want to do with what you've learned? How will you do that?"
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
    var questionText: String?        // highlighted question, or category name
    var categoryQuestions: [String]? // questions in highlighted category (Perspective Change)
    var responses: [String: String]  // prompt → answer (reflection form only)
    var createdAt: Timestamp

    var date: Date { createdAt.dateValue() }

    var firstResponse: String? {
        responses.values.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
