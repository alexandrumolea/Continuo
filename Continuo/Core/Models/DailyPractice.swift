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

    init(id: String, title: String, emoji: String, category: String,
         categoryColor: Color, cardColor: Color, prompts: [String],
         gpReward: Int, competencyId: String? = nil) {
        self.id = id; self.title = title; self.emoji = emoji
        self.category = category; self.categoryColor = categoryColor
        self.cardColor = cardColor; self.prompts = prompts
        self.gpReward = gpReward; self.competencyId = competencyId
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
        )
    ]
}
