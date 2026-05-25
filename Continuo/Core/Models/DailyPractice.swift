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

    // Static catalog — add new practices here
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
            gpReward: 5
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
            gpReward: 5
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
            gpReward: 5
        )
    ]
}
