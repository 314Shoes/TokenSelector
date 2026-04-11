import SwiftUI

struct ColorChannelView: View {
    let onBack: () -> Void
    
    @State private var tokens: [DepositedToken] = []
    
    // Filter tokens to last 3 days
    private var recentTokens: [DepositedToken] {
        let cal = Calendar.current
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        return tokens.filter { $0.depositedAt >= threeDaysAgo }
    }
    
    // Token size used for grid spacing
    private let tokenSize: CGFloat = 22
    
    // Curve amount based on dark vs light ratio for a given color
    private func curveOffset(for color: ColorChoice) -> CGFloat {
        let colorTokens = recentTokens.filter { $0.color == color }
        guard !colorTokens.isEmpty else { return 0 }
        let darkCount = colorTokens.filter { $0.shade == .black }.count
        let lightCount = colorTokens.filter { $0.shade == .white }.count
        let ratio = CGFloat(darkCount - lightCount) / CGFloat(colorTokens.count)
        // Positive ratio = more dark = curve down, negative = more light = curve up
        return ratio * 25
    }
    
    // Y offset at a given normalized x position (0=lineStart, 1=lineEnd) along the curve
    private func curveY(at t: CGFloat, offset: CGFloat) -> CGFloat {
        // Quadratic bezier: peak at center (t=0.5)
        return 4 * offset * t * (1 - t)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Force landscape-style layout by rotating content 90 degrees
            GeometryReader { geo in
                // Use the full screen dimensions but lay out as landscape
                let portraitW = geo.size.width
                let portraitH = geo.size.height
                // In landscape: width = portraitH, height = portraitW
                let lw = portraitH
                let lh = portraitW
                
                let manSize: CGFloat = lh * 0.80
                let manX = lw - manSize * 0.35
                let manCenterY = lh / 2
                let lineStartX: CGFloat = 80
                let lineEndX = manX - 80
                let lineLength = lineEndX - lineStartX
                let maxTokens = Int(lineLength / tokenSize)
                
                // Three horizontal line Y positions (closer together, centered on man)
                let topLineY = manCenterY - lh * 0.08
                let midLineY = manCenterY
                let botLineY = manCenterY + lh * 0.08
                
                ZStack {
                    // MARK: - Top bar
                    HStack {
                        Button("Back") {
                            onBack()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, 50)
                        
                        Spacer()
                        
                        Text("Color Channel")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        Spacer().frame(width: 70)
                    }
                    .position(x: lw / 2, y: 40)
                    .zIndex(10)
                    
                    // MARK: - Three curved horizontal grey lines
                    let blueCurve = curveOffset(for: .blue)
                    let greenCurve = curveOffset(for: .green)
                    let redCurve = curveOffset(for: .red)
                    
                    curvedLine(startX: lineStartX, endX: lineEndX, baseY: topLineY, curveAmount: blueCurve)
                    curvedLine(startX: lineStartX, endX: lineEndX, baseY: midLineY, curveAmount: greenCurve)
                    curvedLine(startX: lineStartX, endX: lineEndX, baseY: botLineY, curveAmount: redCurve)
                    
                    // MARK: - Tokens on lines (globally ordered, no vertical alignment)
                    // Merge all tokens chronologically, assign unique slot to each
                    let allSorted = recentTokens.sorted { $0.depositedAt > $1.depositedAt }
                    let displayTokens = Array(allSorted.prefix(maxTokens))
                    ForEach(Array(displayTokens.enumerated()), id: \.element.id) { globalIndex, token in
                        let x = lineEndX - CGFloat(globalIndex) * tokenSize - tokenSize / 2
                        let baseY: CGFloat = token.color == .blue ? topLineY : (token.color == .green ? midLineY : botLineY)
                        let curve: CGFloat = token.color == .blue ? blueCurve : (token.color == .green ? greenCurve : redCurve)
                        let t = (x - lineStartX) / lineLength
                        let yOffset = curveY(at: t, offset: curve)
                        ZStack {
                            TokenShapeHelper.shapeView(
                                shape: token.shape,
                                color: ColorHelper.resolve(color: token.color, shade: token.shade)
                            )
                            if token.showALabel && token.showILabel && token.showMLabel {
                                TokenShapeHelper.strokeView(shape: token.shape, lineWidth: 1, color: CoinTokenView.goldDark)
                                    .scaleEffect(0.93)
                            }
                            VStack(spacing: 0) {
                                if token.showALabel {
                                    Text("A")
                                        .font(.system(size: 3, weight: .bold))
                                        .foregroundColor(CoinTokenView.goldLabel)
                                }
                                if token.showILabel {
                                    Text("I")
                                        .font(.system(size: 3, weight: .bold))
                                        .foregroundColor(CoinTokenView.goldLabel)
                                }
                                if token.showMLabel {
                                    Text("M")
                                        .font(.system(size: 3, weight: .bold))
                                        .foregroundColor(CoinTokenView.goldLabel)
                                }
                            }
                        }
                        .frame(width: tokenSize, height: tokenSize)
                        .shadow(color: Color.white.opacity(0.3), radius: 2)
                        .position(x: x, y: baseY + yOffset)
                    }
                    
                    // MARK: - Walking man image (right side, centered vertically)
                    Image("A1FF66D0-72A3-4382-B538-9EE37197DEA4_4_5005_c")
                        .resizable()
                        .frame(width: manSize * 0.35, height: manSize * 0.7)
                        .colorInvert()
                        .position(x: manX, y: manCenterY)
                }
                .frame(width: lw, height: lh)
                .rotationEffect(.degrees(90))
                .frame(width: portraitW, height: portraitH)
            }
        }
        .onAppear {
            tokens = TokenStorage.load()
        }
    }
    
    // MARK: - Curved Line
    private func curvedLine(startX: CGFloat, endX: CGFloat, baseY: CGFloat, curveAmount: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: startX, y: baseY))
            path.addQuadCurve(
                to: CGPoint(x: endX, y: baseY),
                control: CGPoint(x: (startX + endX) / 2, y: baseY + curveAmount)
            )
        }
        .stroke(Color.gray.opacity(0.6), lineWidth: 2)
    }
}

struct ColorChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ColorChannelView(onBack: {})
    }
}
