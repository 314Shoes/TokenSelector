import SwiftUI

struct ColorHelper {
    static func resolve(color: ColorChoice, shade: ShadeChoice) -> Color {
        switch shade {
        case .white:
            // Normal shades
            switch color {
            case .blue:  return Color(red: 0.231, green: 0.510, blue: 0.965) // #3B82F6
            case .green: return Color(red: 0.133, green: 0.773, blue: 0.369) // #22C55E
            case .red:   return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
            }
        case .black:
            // Less dark shades
            switch color {
            case .blue:  return Color(red: 0.196, green: 0.396, blue: 0.647) // #3265A5
            case .green: return Color(red: 0.133, green: 0.545, blue: 0.294) // #228B4B
            case .red:   return Color(red: 0.749, green: 0.176, blue: 0.176) // #BF2D2D
            }
        }
    }
}
