import SwiftUI
import QuartzCore

struct UseTokenView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let tokenID: String
    let onDeposit: () -> Void
    
    @State private var xAngle: Double = 0
    @State private var yAngle: Double = 0
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @State private var tokenScale: CGFloat = 0.01
    @State private var tokenVisible = false
    @State private var appearPhase = 0
    
    private let coinLayers = 8
    private let layerDepth: CGFloat = 1.5
    private let flipDuration: Double = 6.0
    private let pauseDuration: Double = 0.8
    
    private var tokenColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }
    
    private var edgeColor: Color {
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
    
    private var impressionAnchor: UnitPoint {
        switch shapeChoice {
        case .square, .circle:
            return .center
        case .triangleUp:
            return UnitPoint(x: 0.5, y: 0.691)
        case .triangleDown:
            return UnitPoint(x: 0.5, y: 0.309)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / 2
            let h = geo.size.height / 2
            
            ZStack {
                // 4 quadrants
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // Top-left: Blue - "Apply to Self"
                        ZStack {
                            Color(red: 0.231, green: 0.510, blue: 0.965)
                            Text("Apply to Self")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(width: w, height: h)
                        
                        // Top-right: Green - "Sync with Others"
                        ZStack {
                            Color(red: 0.133, green: 0.773, blue: 0.369)
                            Text("Sync with Others")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(width: w, height: h)
                    }
                    
                    HStack(spacing: 0) {
                        // Bottom-left: Red - "Discover Patterns"
                        ZStack {
                            Color(red: 0.937, green: 0.267, blue: 0.267)
                            Text("Discover Patterns")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(width: w, height: h)
                        
                        // Bottom-right: White - "Deposit to Treasure Chest"
                        ZStack {
                            Color.white
                            Text("Deposit to Treasure Chest")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                        .frame(width: w, height: h)
                    }
                }
                
                // Draggable token in center
                if tokenVisible {
                    coinTokenView
                        .frame(width: 124, height: 124)
                        .scaleEffect(tokenScale)
                        .offset(
                            x: offset.width,
                            y: offset.height
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    offset = value.translation
                                }
                                .onEnded { value in
                                    isDragging = false
                                    offset = value.translation
                                    handleUseTokenDrop(value.translation)
                                }
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAppearAnimation()
        }
    }
    
    // MARK: - 3D Coin
    
    private var coinTokenView: some View {
        ZStack {
            ForEach(0..<coinLayers, id: \.self) { i in
                tokenShapeView(color: edgeColor.opacity(0.4))
                    .allowsHitTesting(false)
                    .modifier(CoinLayerEffect(
                        xAngle: xAngle,
                        yAngle: yAngle,
                        zOffset: -CGFloat(coinLayers - i) * layerDepth
                    ))
            }
            
            baseFace
                .allowsHitTesting(false)
                .modifier(CoinLayerEffect(
                    xAngle: xAngle,
                    yAngle: yAngle,
                    zOffset: -CGFloat(coinLayers) * layerDepth
                ))
            
            baseFace
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .modifier(CoinLayerEffect(
                    xAngle: xAngle,
                    yAngle: yAngle,
                    zOffset: 0
                ))
        }
    }
    
    @ViewBuilder
    private var baseFace: some View {
        ZStack {
            tokenShapeView(color: edgeColor.opacity(0.4))
            tokenShapeView(color: tokenColor.opacity(1.0))
                .scaleEffect(0.75, anchor: impressionAnchor)
        }
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
    
    // MARK: - Drop Detection
    
    private func handleUseTokenDrop(_ translation: CGSize) {
        // Determine which quadrant based on token position relative to center
        if translation.width > 100 && translation.height < -100 {
            // Top-right quadrant (Green - Sync with Others)
            // Add future functionality here
        } else if translation.width < -100 && translation.height > 100 {
            // Bottom-left quadrant (Red - Discover Patterns)
            // Add future functionality here
        } else if translation.width > 100 && translation.height > 100 {
            // Bottom-right quadrant (White - Deposit to Treasure Chest)
            startDisappearAnimationAndRestart()
        } else {
            // Top-left quadrant (Blue - Apply to Self) or center
            // Add future functionality here
        }
    }
    
    private func startDisappearAnimationAndRestart() {
        // Disappear animation (same as before)
        withAnimation(.easeIn(duration: 2.0)) {
            yAngle += 360 * 8
            tokenScale = 0.01
        }
        
        // Navigate to beginning after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onDeposit()
        }
    }
    
    // MARK: - Appear Animation (reverse of disappear)
    
    private func startAppearAnimation() {
        // Delay 1 second before token appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            tokenVisible = true
            tokenScale = 0.01
            
            // Phase 1: Rapid vertical spin + grow over 2 seconds
            withAnimation(.easeOut(duration: 2.0)) {
                yAngle += 360 * 8
                tokenScale = 1.0
            }
            
            // Phase 2: Start normal flip sequence after appear completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                startFlipSequence()
            }
        }
    }
    
    private func startFlipSequence() {
        // Phase 1: Horizontal flip (X axis)
        withAnimation(.easeInOut(duration: flipDuration)) {
            xAngle += 360
        }
        
        // Phase 2: Vertical flip (Y axis)
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration + pauseDuration) {
            withAnimation(.easeInOut(duration: flipDuration)) {
                yAngle += 360
            }
        }
        
        // Restart cycle
        let totalCycle = (flipDuration + pauseDuration) * 2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalCycle) {
            startFlipSequence()
        }
    }
}

struct UseTokenView_Previews: PreviewProvider {
    static var previews: some View {
        UseTokenView(
            shade: .white,
            colorChoice: .blue,
            shapeChoice: .circle,
            tokenID: "TOKEN-A3F2B1C9",
            onDeposit: { print("Deposit - restart") }
        )
    }
}
