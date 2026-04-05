import SwiftUI

// MARK: - Custom Shapes

struct SquareShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: rect.width * 0.3)
    }
}

struct TriangleUp: Shape {
    func path(in rect: CGRect) -> Path {
        let cr = min(rect.width, rect.height) * 0.15
        var path = Path()
        
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: rect.maxY)
        
        path.move(to: CGPoint(x: (left.x + top.x) / 2, y: (left.y + top.y) / 2))
        path.addArc(tangent1End: top, tangent2End: right, radius: cr)
        path.addArc(tangent1End: right, tangent2End: left, radius: cr)
        path.addArc(tangent1End: left, tangent2End: top, radius: cr)
        path.closeSubpath()
        
        return path
    }
}

struct TriangleDown: Shape {
    func path(in rect: CGRect) -> Path {
        let cr = min(rect.width, rect.height) * 0.15
        var path = Path()
        
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let right = CGPoint(x: rect.maxX, y: rect.minY)
        let left = CGPoint(x: rect.minX, y: rect.minY)
        
        path.move(to: CGPoint(x: (left.x + bottom.x) / 2, y: (left.y + bottom.y) / 2))
        path.addArc(tangent1End: bottom, tangent2End: right, radius: cr)
        path.addArc(tangent1End: right, tangent2End: left, radius: cr)
        path.addArc(tangent1End: left, tangent2End: bottom, radius: cr)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Token Shape Helper

struct TokenShapeHelper {
    @ViewBuilder
    static func shapeView(shape: ShapeChoice, color: Color) -> some View {
        switch shape {
        case .square:
            SquareShape().fill(color)
        case .circle:
            Circle().fill(color)
        case .triangleUp:
            TriangleUp().fill(color)
        case .triangleDown:
            TriangleDown().fill(color)
        }
    }
    
    static func impressionAnchor(for shape: ShapeChoice) -> UnitPoint {
        switch shape {
        case .square, .circle:
            return .center
        case .triangleUp:
            return UnitPoint(x: 0.5, y: 0.691)
        case .triangleDown:
            return UnitPoint(x: 0.5, y: 0.309)
        }
    }
}

// MARK: - Color Helper

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
            case .blue:  return Color(red: 0.157, green: 0.318, blue: 0.518) // #285184
            case .green: return Color(red: 0.102, green: 0.424, blue: 0.227) // #1A6C3A
            case .red:   return Color(red: 0.596, green: 0.118, blue: 0.118) // #981E1E
            }
        }
    }
}
