import SwiftUI

struct DailyPractice: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let category: String
    let categoryColor: Color
    let cardColor: Color
    let prompts: [String]
    let gpReward: Int
    let competencyId: String?   // hidden from user — awards points to this competency on completion
    let introMessage: String?   // optional framing paragraph shown above prompts in DailyPracticeDetailView

    init(id: String, title: String, emoji: String, category: String,
         categoryColor: Color, cardColor: Color, prompts: [String],
         gpReward: Int, competencyId: String? = nil, introMessage: String? = nil) {
        self.id = id; self.title = title; self.emoji = emoji
        self.category = category; self.categoryColor = categoryColor
        self.cardColor = cardColor; self.prompts = prompts
        self.gpReward = gpReward; self.competencyId = competencyId
        self.introMessage = introMessage
    }

    // Static catalog — order here is the display order
    static let catalog: [DailyPractice] = [
        DailyPractice(
            id: "setting_intention",
            title: "Set Your Intention",
            emoji: "🎯",
            category: "Planning",
            categoryColor: Color(hex: "4E7040"),
            cardColor: Color(hex: "EBF3E6"),
            prompts: [
                "What do you want to focus on achieving today?",
                "What can you decide now so that you grow your probability of achievement?"
            ],
            gpReward: 5,
            competencyId: "agency"
        ),
        DailyPractice(
            id: "preparing_for_challenges",
            title: "Preparing for Challenges",
            emoji: "🛡️",
            category: "Agency",
            categoryColor: Color(hex: "4E7040"),
            cardColor: Color(hex: "EBF3E6"),
            prompts: [
                "What is the challenge I anticipate?",
                "What is up to me? (in my control)",
                "What is not up to me? (up to others, chance, things I cannot control)"
            ],
            gpReward: 5,
            competencyId: "agency"
        ),
        DailyPractice(
            id: "activate_sage",
            title: "Activate Your Sage",
            emoji: "🦉",
            category: "Wisdom",
            categoryColor: Color(hex: "7B5EA7"),
            cardColor: Color(hex: "F3EFFE"),
            prompts: [
                "How will you live this wise part of yourself today?",
                "What challenges do you anticipate for today?",
                "How will you activate this part of yourself to meet them?"
            ],
            gpReward: 5,
            competencyId: "inner_harmony"
        ),
        DailyPractice(
            id: "mindfulness",
            title: "Mindfulness",
            emoji: "🧘",
            category: "Presence",
            categoryColor: Color(hex: "5B9FA8"),
            cardColor: Color(hex: "E8F2F4"),
            // First prompt is the home-card preview; the detail view (MindfulnessDetailView)
            // ignores `prompts` entirely and shows a timer + manual log + Health sync.
            prompts: ["Take a mindful pause and notice your breath."],
            gpReward: 5,
            competencyId: "inner_harmony"
        ),
        DailyPractice(
            id: "achievements_inventory",
            title: "Today's Achievements",
            emoji: "🌟",
            category: "Reflection",
            categoryColor: Color(hex: "C87B3E"),
            cardColor: Color(hex: "FEF0E6"),
            prompts: [
                "What are today's achievements you are proud of?"
            ],
            gpReward: 5,
            competencyId: "self_trust"
        ),
        DailyPractice(
            id: "deep_connection",
            title: "Deep Connection",
            emoji: "🤝",
            category: "Relationships",
            categoryColor: Color(hex: "2E7DD1"),
            cardColor: Color(hex: "E8F2FD"),
            prompts: [
                "Who brought a valuable contribution to your life today and how?"
            ],
            gpReward: 5,
            competencyId: "social_intelligence"
        ),
        DailyPractice(
            id: "releasing",
            title: "Releasing",
            emoji: "🌊",
            category: "Adaptability",
            categoryColor: Color(hex: "2D9B8A"),
            cardColor: Color(hex: "E6F6F4"),
            prompts: [
                "Where do you feel tension in your life?",
                "What do you need to let go of so that you move forward?",
                "Are there elements of your identity to which you cling too tightly today?",
                "Where in your life are you pursuing fixity where it might be beneficial to open yourself to the possibility — or in some cases, the inevitability — of change?"
            ],
            gpReward: 5,
            competencyId: "adaptability_quotient"
        ),
        DailyPractice(
            id: "growth_mindset",
            title: "Growth Mindset",
            emoji: "🌱",
            category: "Adaptability",
            categoryColor: Color(hex: "2D9B8A"),
            cardColor: Color(hex: "E6F6F4"),
            prompts: [
                "What is a situation you encountered today and you did not handle properly?",
                "What did I do wrong?",
                "What did I do right?",
                "What could I have done differently?"
            ],
            gpReward: 5,
            competencyId: "adaptability_quotient",
            introMessage: "We tend to repeat patterns until we learn our lessons. It happens because, living mostly in the same context, there simply is a high probability to encounter similar challenges from time to time. How do we prepare for that? We learn."
        ),
        DailyPractice(
            id: "positive_outlook",
            title: "Positive Outlook",
            emoji: "🌅",
            category: "Confidence",
            categoryColor: Color(hex: "C87B3E"),
            cardColor: Color(hex: "FEF6EC"),
            prompts: [
                "What challenge am I looking forward to — today or in the near future?",
                "How am I already prepared for it?",
                "What are my strengths for this challenge?"
            ],
            gpReward: 5,
            competencyId: "self_trust"
        ),
        DailyPractice(
            id: "priority_alignment",
            title: "Priority Alignment",
            emoji: "🧭",
            category: "Agency",
            categoryColor: Color(hex: "4E7040"),
            cardColor: Color(hex: "EBF3E6"),
            prompts: [
                "How well did my actions align with my priorities today?",
                "What did I learn from today?",
                "What would I like to do tomorrow to be more aligned with my priorities?"
            ],
            gpReward: 5,
            competencyId: "agency"
        ),
        DailyPractice(
            id: "journaling",
            title: "Daily Journal",
            emoji: "📓",
            category: "Journaling",
            categoryColor: Color(hex: "7B5EA7"),
            cardColor: Color(hex: "F3EFFE"),
            prompts: [
                "What am I feeling right now, without judgment?",
                "What is weighing on my mind right now?",
                "What keeps coming back to me lately?",
                "What am I resisting right now?",
                "What is happening inside me that I haven't named yet?",
                "What do I keep avoiding, and what does that tell me?",
                "What am I not allowing myself to feel?",
                "What do I keep circling back to in my thoughts?",
                "What is asking for my attention right now?",
                "What truth am I tiptoeing around?",
                "What do I really want right now, underneath everything else?",
                "What do I need right now that I'm not giving myself?",
                "What feels unfinished in my life right now?",
                "What do I need to say that I haven't said yet?",
                "What is taking up space in my mind that I haven't dealt with?",
                "What do I notice when I slow down and actually listen to myself?",
                "What am I carrying that isn't mine to carry?",
                "What is my gut telling me that my head keeps overriding?",
                "What do I wish someone understood about me?",
                "What am I overthinking right now?",
                "What parts of myself am I holding back, and why?",
                "What am I learning about myself lately?",
                "What story am I telling myself that might not be true?",
                "What am I pretending not to know?",
                "What am I afraid of right now?",
                "Where in my body do I feel tension right now, and what is it about?",
                "What would I write if I knew no one would ever read this?",
                "What is the feeling I keep pushing away?",
                "What have I been meaning to look at but keep postponing?",
                "What do I need to hear from myself today?"
            ],
            gpReward: 5,
            competencyId: "inner_harmony"
        )
    ]
}
