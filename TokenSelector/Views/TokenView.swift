import SwiftUI
import QuartzCore

struct TokenView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let tokenID: String
    let onRestart: () -> Void
    let onUseToken: () -> Void
    
    @State private var xAngle: Double = 0
    @State private var yAngle: Double = 0
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @State private var isDisappearing = false
    @State private var disappearScale: CGFloat = 1.0
    @State private var spinSpeed: Double = 0
    @State private var tokenVisible = true
    @State private var screenHeight: CGFloat = 0
    
    private let coinLayers = 8
    private let layerDepth: CGFloat = 1.5
    private let flipDuration: Double = 6.0
    private let pauseDuration: Double = 0.8
    
    private var tokenColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }
    
    private var colorName: String {
        let prefix = shade == .black ? "Dark " : ""
        return prefix + colorChoice.rawValue.capitalized
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    topSection
                    middleSection
                    bottomSection
                }
                
                // Token overlay - floats above all sections
                if tokenVisible {
                    draggableToken
                        .position(x: geo.size.width / 2, y: geo.size.height / 6)
                }
            }
            .onAppear {
                screenHeight = geo.size.height
                startFlipSequence()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Sections
    
    private var topSection: some View {
        ZStack {
            Color.white
            Text("Your New Token")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
    }
    
    private var middleSection: some View {
        ZStack {
            Color(red: 0.85, green: 0.85, blue: 0.85)
            Text("Use Token")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.black.opacity(0.7))
        }
    }
    
    private var bottomSection: some View {
        ZStack {
            Color.black
            Text("Pause again and create new token")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var draggableToken: some View {
        if tokenVisible {
            coinTokenView
                .frame(width: 124, height: 124)
                .scaleEffect(isDisappearing ? disappearScale : (isDragging ? 1.1 : 1.0))
                .offset(x: offset.width, y: offset.height)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            guard !isDisappearing else { return }
                            isDragging = true
                            offset = CGSize(
                                width: value.location.x - value.startLocation.x,
                                height: value.location.y - value.startLocation.y
                            )
                        }
                        .onEnded { value in
                            guard !isDisappearing else { return }
                            isDragging = false
                            offset = CGSize(
                                width: value.location.x - value.startLocation.x,
                                height: value.location.y - value.startLocation.y
                            )
                            handleDrop(dropY: value.location.y)
                        }
                )
        }
    }
    
    private func handleDrop(dropY: CGFloat) {
        let sectionHeight = screenHeight / 3
        if dropY > sectionHeight * 2 {
            // Black section - restart app
            startDisappearAnimation(target: .restart)
        } else if dropY > sectionHeight {
            // Grey section - use token
            startDisappearAnimation(target: .useToken)
        } else {
            // White section - do nothing
        }
    }
    
    // MARK: - Derived Colors
    
    private var edgeColor: Color {
        // Much darker version for the ridge/edge
        switch shade {
        case .white:
            switch colorChoice {
            case .blue:  return Color(red: 0.05, green: 0.08, blue: 0.25)
            case .green: return Color(red: 0.02, green: 0.15, blue: 0.08)
            case .red:   return Color(red: 0.25, green: 0.04, blue: 0.04)
            }
        case .black:
            switch colorChoice {
            case .blue:  return Color(red: 0.03, green: 0.05, blue: 0.18)
            case .green: return Color(red: 0.02, green: 0.10, blue: 0.05)
            case .red:   return Color(red: 0.18, green: 0.03, blue: 0.03)
            }
        }
    }
    
    // Incenter anchor for equidistant inset on each shape
    private var impressionAnchor: UnitPoint {
        switch shapeChoice {
        case .square, .circle:
            return .center
        case .triangleUp:
            // Incenter of isoceles triangle in square: y ≈ sqrt(5)/(1+sqrt(5)) ≈ 0.691
            return UnitPoint(x: 0.5, y: 0.691)
        case .triangleDown:
            return UnitPoint(x: 0.5, y: 0.309)
        }
    }
    
    // MARK: - 3D Coin
    
    private var coinTokenView: some View {
        ZStack {
            // Protruding ridge layers - create visible 3D edge
            ForEach(0..<coinLayers, id: \.self) { i in
                tokenShapeView(color: edgeColor.opacity(0.4))
                    .allowsHitTesting(false)
                    .modifier(CoinLayerEffect(
                        xAngle: xAngle,
                        yAngle: yAngle,
                        zOffset: -CGFloat(coinLayers - i) * layerDepth
                    ))
            }
            
            // Back face
            baseFace
                .allowsHitTesting(false)
                .modifier(CoinLayerEffect(
                    xAngle: xAngle,
                    yAngle: yAngle,
                    zOffset: -CGFloat(coinLayers) * layerDepth
                ))
            
            // Front face (no directional lighting baked in)
            baseFace
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .modifier(CoinLayerEffect(
                    xAngle: xAngle,
                    yAngle: yAngle,
                    zOffset: 0
                ))
        }
    }
    
    // MARK: - Simple Flat Token
    
    @ViewBuilder
    private var baseFace: some View {
        ZStack {
            // Protruding ridge - much lighter color
            tokenShapeView(color: edgeColor.opacity(0.4))
            
            // Flat center - vibrant token color
            tokenShapeView(color: tokenColor.opacity(1.0))
                .scaleEffect(0.75, anchor: impressionAnchor)
            
        }
    }
    
    // MARK: - Shape Helpers
    
    private func currentShape() -> TokenShape {
        TokenShape(shapeChoice: shapeChoice)
    }
    
    @ViewBuilder
    private func tokenShapeView(color: Color) -> some View {
        switch shapeChoice {
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
    
    // MARK: - Animation
    
    private enum DisappearTarget {
        case restart, useToken
    }
    
    private func startFlipSequence() {
        guard !isDisappearing else { return }
        
        // Phase 1: Horizontal flip (X axis)
        withAnimation(.easeInOut(duration: flipDuration)) {
            xAngle += 360
        }
        
        // Phase 2: Vertical flip (Y axis)
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration + pauseDuration) {
            guard !self.isDisappearing else { return }
            withAnimation(.easeInOut(duration: flipDuration)) {
                yAngle += 360
            }
        }
        
        // Restart cycle
        let totalCycle = (flipDuration + pauseDuration) * 2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalCycle) {
            guard !self.isDisappearing else { return }
            startFlipSequence()
        }
    }
    
    private func startDisappearAnimation(target: DisappearTarget) {
        isDisappearing = true
        
        // Switch to vertical-only rapid spin + shrink over 2 seconds
        withAnimation(.easeIn(duration: 2.0)) {
            yAngle += 360 * 8
            disappearScale = 0.01
        }
        
        // After 2 seconds, hide token and navigate
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            tokenVisible = false
            switch target {
            case .restart:
                onRestart()
            case .useToken:
                onUseToken()
            }
        }
    }
}

// MARK: - Token Shape (iOS 14+ compatible shape wrapper)

struct TokenShape: Shape {
    let shapeChoice: ShapeChoice
    
    func path(in rect: CGRect) -> Path {
        switch shapeChoice {
        case .square: return SquareShape().path(in: rect)
        case .circle: return Circle().path(in: rect)
        case .triangleUp: return TriangleUp().path(in: rect)
        case .triangleDown: return TriangleDown().path(in: rect)
        }
    }
}

// MARK: - 3D Coin Layer Effect

struct CoinLayerEffect: GeometryEffect {
    var xAngle: Double
    var yAngle: Double
    var zOffset: CGFloat
    var perspective: CGFloat = 1800
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(xAngle, yAngle) }
        set {
            xAngle = newValue.first
            yAngle = newValue.second
        }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        var t = CATransform3DIdentity
        t.m34 = -1 / perspective
        
        let cx = size.width / 2
        let cy = size.height / 2
        
        // Center → rotate X → rotate Y → offset Z depth → uncenter
        t = CATransform3DTranslate(t, cx, cy, 0)
        t = CATransform3DRotate(t, xAngle * .pi / 180, 1, 0, 0)
        t = CATransform3DRotate(t, yAngle * .pi / 180, 0, 1, 0)
        t = CATransform3DTranslate(t, 0, 0, zOffset)
        t = CATransform3DTranslate(t, -cx, -cy, 0)
        
        return ProjectionTransform(t)
    }
}

struct TokenView_Previews: PreviewProvider {
    static var previews: some View {
        TokenView(
            shade: .white,
            colorChoice: .blue,
            shapeChoice: .circle,
            tokenID: "TOKEN-A3F2B1C9",
            onRestart: { print("Restart") },
            onUseToken: { print("Use Token") }
        )
    }
}
