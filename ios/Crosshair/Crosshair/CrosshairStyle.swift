import SwiftUI

enum ReticleShape: String, CaseIterable, Identifiable, Codable {
    case plus, plusGap, plusDot, cross, crossGap, dot, microDot
    case circle, circleDot, circlePlus, dualRing
    case square, squareDot, squareGap
    case diamond, diamondDot
    case tScope, chevron, brackets, corners
    case hLine, vLine, asterisk, sniper, triangle, rangeFinder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plus: return "Plus"
        case .plusGap: return "Plus Gap"
        case .plusDot: return "Plus Dot"
        case .cross: return "Cross"
        case .crossGap: return "Cross Gap"
        case .dot: return "Dot"
        case .microDot: return "Micro Dot"
        case .circle: return "Circle"
        case .circleDot: return "Circle Dot"
        case .circlePlus: return "Circle Plus"
        case .dualRing: return "Dual Ring"
        case .square: return "Square"
        case .squareDot: return "Square Dot"
        case .squareGap: return "Square Gap"
        case .diamond: return "Diamond"
        case .diamondDot: return "Diamond Dot"
        case .tScope: return "T Scope"
        case .chevron: return "Chevron"
        case .brackets: return "Brackets"
        case .corners: return "Corners"
        case .hLine: return "Horizontal"
        case .vLine: return "Vertical"
        case .asterisk: return "Asterisk"
        case .sniper: return "Sniper"
        case .triangle: return "Triangle"
        case .rangeFinder: return "Range"
        }
    }
}

struct PaletteColor: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
}

enum CrosshairPalette {
    static let colors: [PaletteColor] = [
        .init(id: "white", name: "White", color: .white),
        .init(id: "red", name: "Red", color: Color(red: 1, green: 0.18, blue: 0.18)),
        .init(id: "lime", name: "Lime", color: Color(red: 0.22, green: 1, blue: 0.28)),
        .init(id: "cyan", name: "Cyan", color: Color(red: 0.15, green: 0.92, blue: 1)),
        .init(id: "yellow", name: "Yellow", color: Color(red: 1, green: 0.92, blue: 0.15)),
        .init(id: "orange", name: "Orange", color: Color(red: 1, green: 0.55, blue: 0.1)),
        .init(id: "magenta", name: "Magenta", color: Color(red: 1, green: 0.2, blue: 0.85)),
        .init(id: "blue", name: "Blue", color: Color(red: 0.2, green: 0.45, blue: 1)),
        .init(id: "pink", name: "Pink", color: Color(red: 1, green: 0.45, blue: 0.7)),
        .init(id: "purple", name: "Purple", color: Color(red: 0.7, green: 0.3, blue: 1)),
        .init(id: "teal", name: "Teal", color: Color(red: 0.1, green: 0.85, blue: 0.7)),
        .init(id: "gold", name: "Gold", color: Color(red: 1, green: 0.78, blue: 0.15)),
        .init(id: "black", name: "Black", color: .black),
        .init(id: "gray", name: "Gray", color: Color(white: 0.72)),
        .init(id: "neon", name: "Neon", color: Color(red: 0.55, green: 1, blue: 0.05)),
        .init(id: "ice", name: "Ice", color: Color(red: 0.75, green: 0.95, blue: 1)),
    ]

    static func color(id: String) -> Color {
        colors.first(where: { $0.id == id })?.color ?? .white
    }
}

struct CrosshairStyle: Equatable, Codable, Identifiable {
    var id: Int
    var shape: ReticleShape
    var colorID: String
    var length: Double
    var thickness: Double
    var gap: Double
    var outline: Bool

    var color: Color { CrosshairPalette.color(id: colorID) }

    static let `default` = CrosshairStyle(
        id: 0,
        shape: .plusGap,
        colorID: "lime",
        length: 18,
        thickness: 2,
        gap: 6,
        outline: true
    )
}

enum PresetLibrary {
    static let all: [CrosshairStyle] = build()

    static var count: Int { all.count }

    private static func build() -> [CrosshairStyle] {
        let variants: [(Double, Double, Double, Bool)] = [
            (14, 1.6, 4, true),
            (18, 2.2, 6, true),
            (14, 1.6, 4, false),
            (22, 2.8, 8, true),
            (16, 2.0, 10, true),
        ]
        var items: [CrosshairStyle] = []
        items.reserveCapacity(ReticleShape.allCases.count * CrosshairPalette.colors.count * variants.count)
        var index = 1
        for shape in ReticleShape.allCases {
            for color in CrosshairPalette.colors {
                for variant in variants {
                    items.append(
                        CrosshairStyle(
                            id: index,
                            shape: shape,
                            colorID: color.id,
                            length: variant.0,
                            thickness: variant.1,
                            gap: variant.2,
                            outline: variant.3
                        )
                    )
                    index += 1
                }
            }
        }
        return items
    }
}
