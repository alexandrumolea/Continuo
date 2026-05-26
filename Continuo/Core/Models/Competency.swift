import SwiftUI

struct Competency: Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let color: Color

    static let catalog: [Competency] = [
        Competency(
            id: "agency",
            name: "Agency",
            description: "Your capacity to take intentional action and shape your own path — to act rather than be acted upon. The ability to respond instead of reacting.",
            emoji: "🎯",
            color: Color(hex: "4E7040")
        ),
        Competency(
            id: "self_trust",
            name: "Self-Trust",
            description: "The ability to acknowledge your achievements, recognize what you do well, and build a secure, compassionate relationship with yourself.",
            emoji: "⭐",
            color: Color(hex: "C87B3E")
        ),
        Competency(
            id: "inner_harmony",
            name: "Inner Harmony",
            description: "The wisdom to listen to your deeper self, navigate internal tensions, and align your daily actions with your deeper values.",
            emoji: "🦉",
            color: Color(hex: "7B5EA7")
        ),
        Competency(
            id: "social_intelligence",
            name: "Social Intelligence",
            description: "Your awareness of the people around you — recognizing contributions, deepening connections, and nurturing meaningful relationships.",
            emoji: "🤝",
            color: Color(hex: "2E7DD1")
        ),
        Competency(
            id: "adaptability_quotient",
            name: "Adaptability Quotient",
            description: "The capacity to release what no longer serves you, embrace change with openness, and move forward with resilience and flexibility.",
            emoji: "🌊",
            color: Color(hex: "2D9B8A")
        )
    ]

    static func find(_ id: String) -> Competency? {
        catalog.first { $0.id == id }
    }
}
