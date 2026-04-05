import SwiftUI

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
    @State private var tokenVisible = true
    @State private var screenHeight: CGFloat = 0
    @State private var sectionsOpacity: Double = 0
    
    private let flipDuration: Double = FlipAnimationState.flipDuration
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // White background to prevent flash during transition
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topSection
                    middleSection
                    bottomSection
                }
                .opacity(sectionsOpacity)
                
                // Token overlay - floats above all sections
                if tokenVisible {
                    draggableToken
                        .position(x: geo.size.width / 2, y: geo.size.height / 6)
                }
            }
            .onAppear {
                screenHeight = geo.size.height
                startFlipSequence()
                // Fade in sections
                withAnimation(.easeIn(duration: 0.8)) {
                    sectionsOpacity = 1.0
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Sections
    
    private var topSection: some View {
        ZStack {
            Color.white
            VStack {
                Spacer()
                Text("Your New Token")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 40)
            }
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
    
    // MARK: - 3D Coin
    
    private var coinTokenView: some View {
        CoinTokenView(
            shade: shade,
            colorChoice: colorChoice,
            shapeChoice: shapeChoice,
            xAngle: xAngle,
            yAngle: yAngle
        )
    }
    
    // MARK: - Animation
    
    private enum DisappearTarget {
        case restart, useToken
    }
    
    private func startFlipSequence() {
        guard !isDisappearing else { return }
        
        // Full 360° horizontal flip
        withAnimation(.linear(duration: flipDuration)) {
            xAngle += 360
        }
        
        // After horizontal completes, reset X and do vertical flip
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration) {
            guard !self.isDisappearing else { return }
            self.xAngle = 0
            withAnimation(.linear(duration: self.flipDuration)) {
                self.yAngle += 360
            }
            
            // After vertical completes, reset Y and restart
            DispatchQueue.main.asyncAfter(deadline: .now() + self.flipDuration) {
                guard !self.isDisappearing else { return }
                self.yAngle = 0
                self.startFlipSequence()
            }
        }
    }
    
    private func startDisappearAnimation(target: DisappearTarget) {
        isDisappearing = true
        
        let stages = FlipAnimationState.disappearStages
        let stageCount = Double(stages.count)
        
        // Pre-calculate: axis goes from 90° to 210° (120° sweep)
        let startAxis: Double = 90
        let endAxis: Double = 210
        
        var delay: Double = 0
        var cumulativeFlip: Double = 0
        var currentSpeed: Double = 180  // Starting flip degrees per stage
        
        for (i, stage) in stages.enumerated() {
            let d = delay
            // Pre-compute the axis angle at the END of this stage
            let progress = Double(i + 1) / stageCount
            let axisAngle = startAxis + (endAxis - startAxis) * progress
            let axisRad = axisAngle * .pi / 180
            cumulativeFlip += currentSpeed
            
            // Pre-compute target x/y from axis + cumulative flip
            let targetX = cumulativeFlip * cos(axisRad)
            let targetY = cumulativeFlip * sin(axisRad)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.linear(duration: stage.duration)) {
                    self.xAngle = targetX
                    self.yAngle = targetY
                    self.disappearScale = stage.scale
                }
            }
            currentSpeed = min(currentSpeed * 1.4, 480)
            delay += stage.duration
        }
        
        // After all stages complete, hide and navigate
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
            self.tokenVisible = false
            switch target {
            case .restart:
                self.onRestart()
            case .useToken:
                self.onUseToken()
            }
        }
    }
}

// MARK: - 3D Face Visibility Modifier

struct CoinFaceEffect: AnimatableModifier {
    var xAngle: Double
    var yAngle: Double
    var zOffset: CGFloat
    var isFront: Bool
    var isEdge: Bool
    var perspective: CGFloat = 1800
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(xAngle, yAngle) }
        set {
            xAngle = newValue.first
            yAngle = newValue.second
        }
    }
    
    private func faceOpacity() -> Double {
        guard !isEdge else { return 1 }
        let xRad = xAngle * .pi / 180
        let yRad = yAngle * .pi / 180
        let facing = cos(xRad) * cos(yRad)
        let raw = isFront ? facing : -facing
        return max(0, min(1, (raw + 0.1) / 0.2))
    }
    
    func body(content: Content) -> some View {
        content
            .modifier(CoinLayerEffect(
                xAngle: xAngle,
                yAngle: yAngle,
                zOffset: zOffset,
                perspective: perspective
            ))
            .opacity(faceOpacity())
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
