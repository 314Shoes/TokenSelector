import SwiftUI

struct UseTokenView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let tokenID: String
    let onDeposit: () -> Void
    let onCalendar: () -> Void
    
    @State private var xAngle: Double = 0
    @State private var yAngle: Double = 0
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @State private var tokenScale: CGFloat = 0.01
    @State private var tokenVisible = false
    @State private var isDisappearing = false
    
    private let flipDuration: Double = FlipAnimationState.flipDuration
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / 2
            let h = geo.size.height / 2
            
            let centerSize: CGFloat = 170
            
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
                
                // White center space for the token
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
                    .frame(width: centerSize, height: centerSize)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 3)
                
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
                                    handleUseTokenDrop(value.translation, geo: geo)
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
        CoinTokenView(
            shade: shade,
            colorChoice: colorChoice,
            shapeChoice: shapeChoice,
            xAngle: xAngle,
            yAngle: yAngle
        )
    }
    
    // MARK: - Drop Detection
    
    private func handleUseTokenDrop(_ translation: CGSize, geo: GeometryProxy) {
        // Token center position relative to screen center
        let tokenCenterX = geo.size.width / 2 + translation.width
        let tokenCenterY = geo.size.height / 2 + translation.height
        let tokenRadius: CGFloat = 62 * tokenScale  // half of 124pt token
        
        // Token bounding box
        let tokenLeft = tokenCenterX - tokenRadius
        let tokenRight = tokenCenterX + tokenRadius
        let tokenTop = tokenCenterY - tokenRadius
        let tokenBottom = tokenCenterY + tokenRadius
        
        let midX = geo.size.width / 2
        let midY = geo.size.height / 2
        
        // Check which quadrants the token overlaps (any part touching counts)
        let touchesTopLeft = tokenLeft < midX && tokenTop < midY
        let touchesTopRight = tokenRight > midX && tokenTop < midY
        let touchesBottomLeft = tokenLeft < midX && tokenBottom > midY
        let touchesBottomRight = tokenRight > midX && tokenBottom > midY
        
        // Pick the quadrant where the token center is closest to
        // but only if the token is actually touching that quadrant
        if touchesBottomRight && (tokenCenterX > midX || tokenCenterY > midY) {
            // Bottom-right quadrant (White - Deposit to Treasure Chest)
            startDisappearAnimationAndRestart()
        } else if touchesTopLeft && tokenCenterX <= midX && tokenCenterY <= midY {
            // Top-left quadrant (Blue - Apply to Self)
            // Future functionality
        } else if touchesTopRight && tokenCenterX > midX && tokenCenterY <= midY {
            // Top-right quadrant (Green - Sync with Others)
            // Future functionality
        } else if touchesBottomLeft && tokenCenterX <= midX && tokenCenterY > midY {
            // Bottom-left quadrant (Red - Discover Patterns)
            startDisappearAnimationAndNavigateToCalendar()
        } else if touchesBottomRight {
            startDisappearAnimationAndRestart()
        } else if touchesTopLeft {
            // Future functionality
        } else if touchesTopRight {
            // Future functionality
        } else if touchesBottomLeft {
            startDisappearAnimationAndNavigateToCalendar()
        }
        // If no quadrant touched (token still in center), do nothing
    }
    
    private func startDisappearAnimationAndRestart() {
        isDisappearing = true
        
        let stages = FlipAnimationState.disappearStages
        let stageCount = Double(stages.count)
        
        // Pre-calculate: axis goes from 90° to 210° (120° sweep)
        let startAxis: Double = 90
        let endAxis: Double = 210
        
        var delay: Double = 0
        var cumulativeFlip: Double = 0
        var currentSpeed: Double = 180
        
        for (i, stage) in stages.enumerated() {
            let d = delay
            let progress = Double(i + 1) / stageCount
            let axisAngle = startAxis + (endAxis - startAxis) * progress
            let axisRad = axisAngle * .pi / 180
            cumulativeFlip += currentSpeed
            
            let targetX = cumulativeFlip * cos(axisRad)
            let targetY = cumulativeFlip * sin(axisRad)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.linear(duration: stage.duration)) {
                    self.xAngle = targetX
                    self.yAngle = targetY
                    self.tokenScale = stage.scale
                }
            }
            currentSpeed = min(currentSpeed * 1.4, 480)
            delay += stage.duration
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
            self.onDeposit()
        }
    }
    
    private func startDisappearAnimationAndNavigateToCalendar() {
        isDisappearing = true
        
        let stages = FlipAnimationState.disappearStages
        let stageCount = Double(stages.count)
        
        // Pre-calculate: axis goes from 90° to 210° (120° sweep)
        let startAxis: Double = 90
        let endAxis: Double = 210
        
        var delay: Double = 0
        var cumulativeFlip: Double = 0
        var currentSpeed: Double = 180
        
        for (i, stage) in stages.enumerated() {
            let d = delay
            let progress = Double(i + 1) / stageCount
            let axisAngle = startAxis + (endAxis - startAxis) * progress
            let axisRad = axisAngle * .pi / 180
            cumulativeFlip += currentSpeed
            
            let targetX = cumulativeFlip * cos(axisRad)
            let targetY = cumulativeFlip * sin(axisRad)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.linear(duration: stage.duration)) {
                    self.xAngle = targetX
                    self.yAngle = targetY
                    self.tokenScale = stage.scale
                }
            }
            currentSpeed = min(currentSpeed * 1.4, 480)
            delay += stage.duration
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
            self.onCalendar()
        }
    }
    
    // MARK: - Appear Animation (reverse of disappear: fast+small → slow+big)
    
    private func startAppearAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tokenVisible = true
            tokenScale = 0.01
            
            // Start from where disappear would end
            let startFlip: Double = 1745  // Cumulative from disappear
            let startAxis: Double = 210
            let endAxis: Double = 90
            
            let stages = FlipAnimationState.appearStages
            let stageCount = Double(stages.count)
            
            // Calculate exact flip reduction per stage to reach 0 at end
            let flipReductionPerStage = startFlip / stageCount
            
            var delay: Double = 0
            var currentFlip: Double = startFlip
            
            for (i, stage) in stages.enumerated() {
                let d = delay
                let progress = Double(i + 1) / stageCount
                let axisAngle = startAxis + (endAxis - startAxis) * progress
                let axisRad = axisAngle * .pi / 180
                
                // Reduce flip amount each stage (will reach 0 at final stage)
                currentFlip = max(currentFlip - flipReductionPerStage, 0)
                
                let targetX = currentFlip * cos(axisRad)
                let targetY = currentFlip * sin(axisRad)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                    withAnimation(.linear(duration: stage.duration)) {
                        self.xAngle = targetX
                        self.yAngle = targetY
                        self.tokenScale = stage.scale
                    }
                }
                delay += stage.duration
            }
            
            // Start alternating axis flip (already at 0,0 so no reset needed)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.1) {
                self.startFlipSequence()
            }
        }
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
}

struct UseTokenView_Previews: PreviewProvider {
    static var previews: some View {
        UseTokenView(
            shade: .white,
            colorChoice: .blue,
            shapeChoice: .circle,
            tokenID: "TOKEN-A3F2B1C9",
            onDeposit: { print("Deposit - restart") },
            onCalendar: { print("Calendar") }
        )
    }
}
