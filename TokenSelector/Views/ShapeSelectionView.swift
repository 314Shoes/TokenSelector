import SwiftUI

struct ShapeSelectionView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let onSelect: (ShapeChoice) -> Void
    
    private var bgColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / 2
            let h = geo.size.height / 2
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Upper-left: Square
                    Button {
                        onSelect(.square)
                    } label: {
                        ZStack {
                            bgColor
                            SquareShape()
                                .fill(.white)
                                .frame(width: min(w, h) * 0.4, height: min(w, h) * 0.4)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }
                        .frame(width: w, height: h)
                        .overlay(
                            Rectangle()
                                .frame(width: nil, height: 0.5)
                                .foregroundColor(.white.opacity(0.25)),
                            alignment: .bottom
                        )
                        .overlay(
                            Rectangle()
                                .frame(width: 0.5, height: nil)
                                .foregroundColor(.white.opacity(0.25)),
                            alignment: .trailing
                        )
                    }
                    
                    // Upper-right: Circle
                    Button {
                        onSelect(.circle)
                    } label: {
                        ZStack {
                            bgColor
                            Circle()
                                .fill(.white)
                                .frame(width: min(w, h) * 0.4, height: min(w, h) * 0.4)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }
                        .frame(width: w, height: h)
                        .overlay(
                            Rectangle()
                                .frame(width: nil, height: 0.5)
                                .foregroundColor(.white.opacity(0.25)),
                            alignment: .bottom
                        )
                    }
                }
                
                HStack(spacing: 0) {
                    // Lower-left: Triangle Up
                    Button {
                        onSelect(.triangleUp)
                    } label: {
                        ZStack {
                            bgColor
                            TriangleUp()
                                .fill(.white)
                                .frame(width: min(w, h) * 0.4, height: min(w, h) * 0.4)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }
                        .frame(width: w, height: h)
                        .overlay(
                            Rectangle()
                                .frame(width: 0.5, height: nil)
                                .foregroundColor(.white.opacity(0.25)),
                            alignment: .trailing
                        )
                    }
                    
                    // Lower-right: Triangle Down
                    Button {
                        onSelect(.triangleDown)
                    } label: {
                        ZStack {
                            bgColor
                            TriangleDown()
                                .fill(.white)
                                .frame(width: min(w, h) * 0.4, height: min(w, h) * 0.4)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }
                        .frame(width: w, height: h)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

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

struct ShapeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ShapeSelectionView(shade: .white, colorChoice: .blue) { shape in
            print("Selected: \(shape)")
        }
    }
}
