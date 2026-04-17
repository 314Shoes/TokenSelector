import SwiftUI

struct UseTokenView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let tokenID: String
    var showALabel: Bool = false
    var showILabel: Bool = false
    var showMLabel: Bool = false
    let onDeposit: () -> Void
    let onCalendar: () -> Void
    
    @State private var xAngle: Double = 0
    @State private var yAngle: Double = 0
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @State private var tokenScale: CGFloat = 0.01
    @State private var tokenVisible = false
    @State private var isDisappearing = false
    @State private var currentFlipAxis: Double = 0 // 0 = x-axis, 90 = y-axis
    
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
                        quadrant(color: ColorHelper.resolve(color: .blue, shade: .white),
                                 label: "Apply\nto Self", labelColor: .white)
                            .frame(width: w, height: h)
                        quadrant(color: ColorHelper.resolve(color: .green, shade: .white),
                                 label: "Sync with\nOthers", labelColor: .white)
                            .frame(width: w, height: h)
                    }
                    HStack(spacing: 0) {
                        quadrant(color: ColorHelper.resolve(color: .red, shade: .white),
                                 label: "Discover\nPatterns", labelColor: .white)
                            .frame(width: w, height: h)
                        quadrant(color: .white,
                                 label: "Deposit\nto Treasure\nChest", labelColor: .black)
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
                    let centroidY = TokenShapeHelper.centroidAnchor(for: shapeChoice).y
                    let visualCenterOffset = (centroidY - 0.5) * 124
                    coinTokenView
                        .frame(width: 124, height: 124)
                        .offset(y: -visualCenterOffset)
                        .contentShape(Rectangle())
                        .scaleEffect(tokenScale)
                        .offset(
                            x: offset.width,
                            y: offset.height
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                .onChanged { value in
                                    isDragging = true
                                    offset = CGSize(
                                        width: value.location.x - value.startLocation.x,
                                        height: value.location.y - value.startLocation.y
                                    )
                                }
                                .onEnded { value in
                                    isDragging = false
                                    offset = CGSize(
                                        width: value.location.x - value.startLocation.x,
                                        height: value.location.y - value.startLocation.y
                                    )
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
    
    // MARK: - Quadrant

    private func quadrant(color: Color, label: String, labelColor: Color) -> some View {
        ZStack {
            color
            Text(label)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(labelColor)
                .multilineTextAlignment(.center)
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
            showGoldRim: showALabel && showILabel && showMLabel
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
            startDisappearAnimation(onComplete: onDeposit)
        } else if touchesTopLeft && tokenCenterX <= midX && tokenCenterY <= midY {
            // Top-left quadrant (Blue - Apply to Self)
            // Future functionality
        } else if touchesTopRight && tokenCenterX > midX && tokenCenterY <= midY {
            // Top-right quadrant (Green - Sync with Others)
            // Future functionality
        } else if touchesBottomLeft && tokenCenterX <= midX && tokenCenterY > midY {
            // Bottom-left quadrant (Red - Discover Patterns)
            startDisappearAnimation(onComplete: onCalendar)
        } else if touchesBottomRight {
            startDisappearAnimation(onComplete: onDeposit)
        } else if touchesTopLeft {
            // Future functionality
        } else if touchesTopRight {
            // Future functionality
        } else if touchesBottomLeft {
            startDisappearAnimation(onComplete: onCalendar)
        }
        // If no quadrant touched (token still in center), do nothing
    }
    
    private func startDisappearAnimation(onComplete: @escaping () -> Void) {
        isDisappearing = true

        let onX = currentFlipAxis == 0

        let stages: [(duration: Double, scale: CGFloat, primaryFrac: Double)] = [
            (1.20, 0.80, 1.0),
            (0.90, 0.60, 0.75),
            (0.66, 0.40, 0.50),
            (0.46, 0.20, 0.25),
            (0.30, 0.01, 0.0),
        ]

        var delay: Double = 0
        let spin: Double = 180

        for stage in stages {
            let d = delay
            let addX = onX ? spin * stage.primaryFrac : spin * (1.0 - stage.primaryFrac)
            let addY = onX ? spin * (1.0 - stage.primaryFrac) : spin * stage.primaryFrac

            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.easeInOut(duration: stage.duration)) {
                    self.xAngle += addX
                    self.yAngle += addY
                    self.tokenScale = stage.scale
                }
            }
            delay += stage.duration
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
            onComplete()
        }
    }
    
    // MARK: - Appear Animation (reverse of disappear — single smooth animation)

    private func startAppearAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tokenVisible = true
            tokenScale = 0.01
            xAngle = 720
            yAngle = 540

            // Single smooth animation: spin down to 0 and scale up to 1
            let totalDuration: Double = 3.5
            withAnimation(.easeOut(duration: totalDuration)) {
                self.xAngle = 0
                self.yAngle = 0
                self.tokenScale = 1.0
            }

            // Start idle flip after appear completes
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.1) {
                self.startFlipSequence()
            }
        }
    }
    
    private func startFlipSequence() {
        guard !isDisappearing else { return }

        currentFlipAxis = 0 // x-axis
        withAnimation(.linear(duration: flipDuration)) {
            xAngle += 360
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration) {
            guard !self.isDisappearing else { return }
            self.xAngle = 0
            self.currentFlipAxis = 90 // y-axis
            withAnimation(.linear(duration: self.flipDuration)) {
                self.yAngle += 360
            }

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
