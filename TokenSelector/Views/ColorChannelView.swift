import SwiftUI

struct ColorChannelView: View {
    let onBack: () -> Void

    @State private var tokens: [DepositedToken] = []

    private let tokenSize: CGFloat = 22
    private let unit: CGFloat = 18

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                let portraitW = geo.size.width
                let portraitH = geo.size.height
                let lw = portraitH
                let lh = portraitW

                let manSize: CGFloat = lh * 0.80
                let manX = lw - manSize * 0.35
                let manCenterY = lh / 2
                let lineStartX: CGFloat = 80
                let lineEndX = manX - 80

                let topLineY = manCenterY - lh * 0.08
                let midLineY = manCenterY
                let botLineY = manCenterY + lh * 0.08

                // All tokens sorted chronologically (oldest first = leftmost)
                let allSorted = tokens.sorted { $0.depositedAt < $1.depositedAt }
                let count = allSorted.count
                let colW = count > 0 ? (lineEndX - lineStartX) / CGFloat(count + 1) : tokenSize

                // Assign each token a column x position
                // Newest closest to man (rightmost), oldest furthest left
                let spacing = min(colW, tokenSize * 1.5)
                let tokenPositions: [(x: CGFloat, token: DepositedToken)] = allSorted.enumerated().map { i, token in
                    let x = lineEndX - CGFloat(count - 1 - i) * spacing
                    return (x: x, token: token)
                }

                // Compute per-color cumulative Y positions
                // Zone boundaries: each line stays in its third
                let zoneHalf = lh * 0.04  // half the gap between lines
                let bluePoints = colorPoints(from: tokenPositions, color: .blue, baseY: topLineY, minY: topLineY - lh * 0.15, maxY: topLineY + zoneHalf)
                let greenPoints = colorPoints(from: tokenPositions, color: .green, baseY: midLineY, minY: midLineY - zoneHalf, maxY: midLineY + zoneHalf)
                let redPoints = colorPoints(from: tokenPositions, color: .red, baseY: botLineY, minY: botLineY - zoneHalf, maxY: botLineY + lh * 0.15)

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

                    // MARK: - Three lines
                    channelLine(points: bluePoints, startX: lineStartX, endX: lineEndX, baseY: topLineY)
                    channelLine(points: greenPoints, startX: lineStartX, endX: lineEndX, baseY: midLineY)
                    channelLine(points: redPoints, startX: lineStartX, endX: lineEndX, baseY: botLineY)

                    // MARK: - Tokens
                    ForEach(Array((bluePoints + greenPoints + redPoints).enumerated()), id: \.element.token.id) { _, point in
                        let token = point.token
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
                        .position(x: point.x, y: point.y)
                    }

                    // MARK: - Walking man image
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

    // MARK: - Compute color points with cumulative Y, clamped to zone
    private func colorPoints(from allPositions: [(x: CGFloat, token: DepositedToken)], color: ColorChoice, baseY: CGFloat, minY: CGFloat, maxY: CGFloat) -> [(x: CGFloat, y: CGFloat, token: DepositedToken)] {
        let colorPositions = allPositions.filter { $0.token.color == color }
        var cumulativeY: CGFloat = 0
        var points: [(x: CGFloat, y: CGFloat, token: DepositedToken)] = []

        for pos in colorPositions {
            cumulativeY += pos.token.shade == .white ? -unit : unit
            let y = min(max(baseY + cumulativeY, minY), maxY)
            points.append((x: pos.x, y: y, token: pos.token))
        }

        return points
    }

    // MARK: - Channel Line
    private func channelLine(points: [(x: CGFloat, y: CGFloat, token: DepositedToken)], startX: CGFloat, endX: CGFloat, baseY: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: startX, y: baseY))

            if points.isEmpty {
                path.addLine(to: CGPoint(x: endX, y: baseY))
            } else {
                for point in points {
                    path.addLine(to: CGPoint(x: point.x, y: point.y))
                }
                path.addLine(to: CGPoint(x: endX, y: points.last!.y))
            }
        }
        .stroke(Color.gray.opacity(0.6), lineWidth: 2)
    }
}

struct ColorChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ColorChannelView(onBack: {})
    }
}
