import SwiftUI

struct TokenView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let tokenID: String
    var showALabel: Bool = false
    var showILabel: Bool = false
    var showMLabel: Bool = false
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
    // Letter-by-letter reveal state (opacity-based so layout is stable)
    @State private var aOpacity: Double = 0
    @State private var iOpacity: Double = 0
    @State private var mOpacity: Double = 0
    @State private var rimRevealed: Bool = false
    @State private var rimProgress: CGFloat = 0
    // Fireworks state
    @State private var fireworksActive: Bool = false
    @State private var sparkExpand: CGFloat = 0
    @State private var sparkOpacity: Double = 1.0
    @State private var ringScales: [CGFloat] = [0.3, 0.3, 0.3, 0.3]
    @State private var ringOpacity: Double = 1.0
    
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
                    ZStack {
                        draggableToken

                        // Fireworks explosion
                        if fireworksActive {
                            fireworksView
                                .allowsHitTesting(false)
                        }
                    }
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
                // Start the letter-by-letter reveal sequence
                startLetterRevealSequence()
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
            .contentShape(Rectangle())
            .scaleEffect(isDisappearing ? disappearScale : 1.0)
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
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
            yAngle: yAngle,
            showALabel: showALabel,
            showILabel: showILabel,
            showMLabel: showMLabel,
            aLabelOpacity: aOpacity,
            iLabelOpacity: iOpacity,
            mLabelOpacity: mOpacity,
            showGoldRim: rimRevealed,
            rimProgress: rimProgress
        )
    }

    // MARK: - Fireworks

    private let sparkAngles: [Double] = (0..<20).map { Double($0) * 18.0 }

    @ViewBuilder
    private var fireworksView: some View {
        ZStack {
            // Expanding rings
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(
                        CoinTokenView.goldLight.opacity(ringOpacity * (0.8 - Double(i) * 0.15)),
                        lineWidth: CGFloat(3 - i)
                    )
                    .frame(width: 50, height: 50)
                    .scaleEffect(ringScales[i])
            }

            // Sparks radiating outward
            ForEach(0..<20, id: \.self) { i in
                let angle = sparkAngles[i] * .pi / 180
                let dist = (60 + CGFloat(i % 4) * 25) * sparkExpand
                Circle()
                    .fill(CoinTokenView.goldLight)
                    .frame(width: CGFloat(4 - i % 3), height: CGFloat(4 - i % 3))
                    .offset(x: CGFloat(cos(angle)) * dist, y: CGFloat(sin(angle)) * dist)
                    .opacity(sparkOpacity * (i % 2 == 0 ? 1.0 : 0.7))
            }
        }
    }

    // MARK: - Letter-by-Letter Reveal

    private func startLetterRevealSequence() {
        var delay: Double = 1.0  // initial settle time

        // 1. Reveal "A" if earned (waited 6 pulses)
        if showALabel {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) { aOpacity = 1.0 }
            }
            delay += 0.6
        }

        // 2. Reveal "I" if earned
        if showILabel {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) { iOpacity = 1.0 }
            }
            delay += 0.6
        }

        // 3. Reveal "M" if earned
        if showMLabel {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) { mOpacity = 1.0 }
            }
            delay += 0.8
        }

        // 4. Rim traces around the token (only if AIM complete)
        if showALabel && showILabel && showMLabel {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                rimRevealed = true
                withAnimation(.easeInOut(duration: 1.5)) {
                    rimProgress = 1.0
                }
            }
            delay += 1.8

            // 5. Fireworks explosion — then gone forever
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                triggerFireworks()
            }
        }
    }

    private func triggerFireworks() {
        fireworksActive = true
        sparkExpand = 0
        sparkOpacity = 1.0
        ringOpacity = 1.0
        ringScales = [0.3, 0.3, 0.3, 0.3]

        // Rings burst outward at staggered times
        withAnimation(.easeOut(duration: 0.6)) { ringScales[0] = 4.0 }
        withAnimation(.easeOut(duration: 0.8).delay(0.05)) { ringScales[1] = 5.5 }
        withAnimation(.easeOut(duration: 1.0).delay(0.1)) { ringScales[2] = 7.0 }
        withAnimation(.easeOut(duration: 1.2).delay(0.15)) { ringScales[3] = 9.0 }

        // Sparks fly outward
        withAnimation(.easeOut(duration: 1.0)) { sparkExpand = 1.0 }

        // Everything fades
        withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
            sparkOpacity = 0
            ringOpacity = 0
        }

        // Remove fireworks completely
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            fireworksActive = false
        }
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
    var anchorY: CGFloat = 0.5

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
                perspective: perspective,
                anchorY: anchorY
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
    var anchorY: CGFloat = 0.5

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
        let cy = size.height * anchorY

        // Centroid → rotate X → rotate Y → offset Z depth → un-centroid
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
