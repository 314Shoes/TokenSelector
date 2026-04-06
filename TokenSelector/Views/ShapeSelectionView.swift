import SwiftUI

struct ShapeSelectionView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let onSelect: (ShapeChoice) -> Void
    
    @State private var crossScale: CGFloat = 0
    @State private var shapesOpacity: Double = 0.0
    @State private var wipeOffset: CGFloat = 0
    @State private var hasAppeared = false
    
    // Post-selection animation state
    @State private var pickedShape: ShapeChoice? = nil
    @State private var tokenX: CGFloat = 0
    @State private var tokenY: CGFloat = 0
    @State private var tokenSize: CGFloat = 0
    @State private var tokenRotation: Double = 0
    @State private var fadeWhite: Double = 0
    
    private var bgColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / 2
            let h = geo.size.height / 2
            
            ZStack {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // Upper-left: Square
                        ZStack {
                            bgColor
                            SquareShape()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                .opacity(shapesOpacity)
                                .overlay(
                                    SquareShape()
                                        .stroke(Color.black, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                        .opacity(shapesOpacity)
                                )
                                .contentShape(SquareShape())
                                .onTapGesture { selectShape(.square, geo: geo) }
                        }
                        .frame(width: w, height: h)
                        
                        // Upper-right: Circle
                        ZStack {
                            bgColor
                            Circle()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                .opacity(shapesOpacity)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                        .opacity(shapesOpacity)
                                )
                                .contentShape(Circle())
                                .onTapGesture { selectShape(.circle, geo: geo) }
                        }
                        .frame(width: w, height: h)
                    }
                    
                    HStack(spacing: 0) {
                        // Lower-left: Triangle Up
                        ZStack {
                            bgColor
                            TriangleUp()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                .opacity(shapesOpacity)
                                .overlay(
                                    TriangleUp()
                                        .stroke(Color.black, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                        .opacity(shapesOpacity)
                                )
                                .contentShape(TriangleUp())
                                .onTapGesture { selectShape(.triangleUp, geo: geo) }
                        }
                        .frame(width: w, height: h)
                        
                        // Lower-right: Triangle Down
                        ZStack {
                            bgColor
                            TriangleDown()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                .opacity(shapesOpacity)
                                .overlay(
                                    TriangleDown()
                                        .stroke(Color.black, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                        .opacity(shapesOpacity)
                                )
                                .contentShape(TriangleDown())
                                .onTapGesture { selectShape(.triangleDown, geo: geo) }
                        }
                        .frame(width: w, height: h)
                    }
                }
                
                // Solid color overlay — fades out to reveal shapes underneath
                bgColor
                    .ignoresSafeArea()
                    .opacity(1.0 - wipeOffset)
                    .allowsHitTesting(false)
                
                // Black cross — expands from center dot
                CrossShape()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: geo.size.width * crossScale, height: geo.size.height * crossScale)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .allowsHitTesting(false)
                
                // Fade to white overlay
                Color.white
                    .ignoresSafeArea()
                    .opacity(fadeWhite)
                    .allowsHitTesting(false)
                
                // Cartwheeling token
                if let shape = pickedShape {
                    CoinTokenView(
                        shade: shade,
                        colorChoice: colorChoice,
                        shapeChoice: shape,
                        xAngle: 0,
                        yAngle: 0
                    )
                        .frame(width: tokenSize, height: tokenSize)
                        .rotationEffect(.degrees(tokenRotation))
                        .position(x: tokenX, y: tokenY)
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.easeInOut(duration: 4.0)) {
                    wipeOffset = 1.0
                }
                // Cross expands from center (0.5s after wipe starts)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        crossScale = 1.0
                    }
                }
                // Shapes fade in after cross expansion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    withAnimation(.easeIn(duration: 0.6)) {
                        shapesOpacity = 1.0
                    }
                }
            }
        }
    }
    
    // MARK: - Shape Selection + Cartwheel Animation
    
    private func selectShape(_ shape: ShapeChoice, geo: GeometryProxy) {
        guard pickedShape == nil else { return }
        pickedShape = shape
        
        let w = geo.size.width / 2
        let h = geo.size.height / 2
        
        // Shape quadrant centers
        let origin: CGPoint
        switch shape {
        case .square:      origin = CGPoint(x: w / 2, y: h / 2)
        case .circle:      origin = CGPoint(x: w + w / 2, y: h / 2)
        case .triangleUp:  origin = CGPoint(x: w / 2, y: h + h / 2)
        case .triangleDown: origin = CGPoint(x: w + w / 2, y: h + h / 2)
        }
        
        // Start: token at exact same position and size as black outline shape
        let shapeSize = min(w, h) * 0.88
        tokenX = origin.x
        tokenY = origin.y
        tokenSize = shapeSize
        tokenRotation = 0
        
        // Fade background to white immediately
        withAnimation(.easeIn(duration: 1.0)) {
            fadeWhite = 1.0
        }
        
        // Token dwells for 0.75s in outline position, then cartwheels to destination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            // Destination: center-top of screen (where token sits in TokenView)
            let destX = geo.size.width / 2
            let destY = geo.size.height / 6
            
            // Cartwheel to destination
            withAnimation(.easeInOut(duration: 2.5)) {
                tokenX = destX
                tokenY = destY
                tokenSize = 124
                tokenRotation = 1080  // 3 full cartwheels
            }
        }
        
        // Transition to next screen after cartwheel completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            onSelect(shape)
        }
    }
}

// MARK: - Cross Shape

struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let cy = h / 2
        
        // Horizontal line
        path.move(to: CGPoint(x: 0, y: cy))
        path.addLine(to: CGPoint(x: w, y: cy))
        
        // Vertical line
        path.move(to: CGPoint(x: cx, y: 0))
        path.addLine(to: CGPoint(x: cx, y: h))
        
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
