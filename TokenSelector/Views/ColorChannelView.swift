import SwiftUI

struct ColorChannelView: View {
    let onBack: () -> Void

    @State private var tokens: [DepositedToken] = []

    private let tokenSize: CGFloat = 22
    private let unit: CGFloat = 10

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

                // Compute per-color cumulative offsets (relative to 0)
                let blueOffsets = rawColorOffsets(from: tokenPositions, color: .blue)
                let greenOffsets = rawColorOffsets(from: tokenPositions, color: .green)
                let redOffsets = rawColorOffsets(from: tokenPositions, color: .red)

                // Spread base positions apart so lines never overlap
                let minGap: CGFloat = lh * 0.06
                let bases = spreadBases(
                    blueOffsets: blueOffsets, greenOffsets: greenOffsets, redOffsets: redOffsets,
                    nominalTop: topLineY, nominalMid: midLineY, nominalBot: botLineY,
                    lineStartX: lineStartX, lineEndX: lineEndX, minGap: minGap
                )
                let separated = buildResult(
                    blueOffsets: blueOffsets, greenOffsets: greenOffsets, redOffsets: redOffsets,
                    bases: bases, tokenPositions: tokenPositions,
                    lineStartX: lineStartX, lineEndX: lineEndX
                )

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

                    // MARK: - Three lines (using separated full paths)
                    linePath(points: separated.blueLine)
                    linePath(points: separated.greenLine)
                    linePath(points: separated.redLine)

                    // MARK: - Tokens (positioned at separated Y values)
                    ForEach(Array((separated.blueTokens + separated.greenTokens + separated.redTokens).enumerated()), id: \.element.token.id) { _, point in
                        TokenBadgeView(token: point.token, size: tokenSize, labelSize: 3)
                            .shadow(color: .white.opacity(0.3), radius: 2)
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

    // MARK: - Raw color offsets (cumulative, relative to 0)
    private func rawColorOffsets(from allPositions: [(x: CGFloat, token: DepositedToken)], color: ColorChoice) -> [(x: CGFloat, offset: CGFloat, token: DepositedToken)] {
        let colorPositions = allPositions.filter { $0.token.color == color }
        var cumulative: CGFloat = 0
        var result: [(x: CGFloat, offset: CGFloat, token: DepositedToken)] = []
        for pos in colorPositions {
            cumulative += pos.token.shade == .white ? -unit : unit
            result.append((x: pos.x, offset: cumulative, token: pos.token))
        }
        return result
    }

    // MARK: - Spread bases so lines never overlap
    struct SpreadBases {
        let blue: CGFloat
        let green: CGFloat
        let red: CGFloat
    }

    private func spreadBases(
        blueOffsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)],
        greenOffsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)],
        redOffsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)],
        nominalTop: CGFloat, nominalMid: CGFloat, nominalBot: CGFloat,
        lineStartX: CGFloat, lineEndX: CGFloat, minGap: CGFloat
    ) -> SpreadBases {
        // Collect all x positions where any line changes (need all for gap checking)
        var xSet = Set<CGFloat>()
        xSet.insert(lineStartX)
        xSet.insert(lineEndX)
        for p in blueOffsets { xSet.insert(p.x) }
        for p in greenOffsets { xSet.insert(p.x) }
        for p in redOffsets { xSet.insert(p.x) }
        let sortedXs = xSet.sorted()

        func offsetAtX(_ offsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)], x: CGFloat) -> CGFloat {
            var current: CGFloat = 0
            for p in offsets {
                if p.x <= x { current = p.offset } else { break }
            }
            return current
        }

        // Find the worst-case encroachment between adjacent lines at any x.
        // Blue is top (smallest Y), green middle, red bottom.
        // blueY = blueBase + blueOffset, greenY = greenBase + greenOffset
        // We need greenY - blueY >= minGap for all x:
        //   (greenBase - blueBase) + (greenOffset - blueOffset) >= minGap
        //   greenBase - blueBase >= minGap + max_over_x(blueOffset - greenOffset)
        // Similarly for red-green.

        var maxBlueMinusGreen: CGFloat = 0  // max(blueOffset - greenOffset)
        var maxGreenMinusRed: CGFloat = 0   // max(greenOffset - redOffset)

        for x in sortedXs {
            let bOff = offsetAtX(blueOffsets, x: x)
            let gOff = offsetAtX(greenOffsets, x: x)
            let rOff = offsetAtX(redOffsets, x: x)
            maxBlueMinusGreen = max(maxBlueMinusGreen, bOff - gOff)
            maxGreenMinusRed = max(maxGreenMinusRed, gOff - rOff)
        }

        // Required minimum spacing between bases
        let requiredBG = minGap + maxBlueMinusGreen
        let requiredGR = minGap + maxGreenMinusRed

        // Start from nominal positions and widen if needed
        let nominalBG = nominalMid - nominalTop
        let nominalGR = nominalBot - nominalMid

        let actualBG = max(nominalBG, requiredBG)
        let actualGR = max(nominalGR, requiredGR)

        // Center the group around the original center
        let nominalCenter = (nominalTop + nominalBot) / 2
        let totalSpan = actualBG + actualGR
        let blueBase = nominalCenter - totalSpan / 2
        let greenBase = blueBase + actualBG
        let redBase = greenBase + actualGR

        return SpreadBases(blue: blueBase, green: greenBase, red: redBase)
    }

    // MARK: - Build final result from offsets + bases
    struct SeparatedResult {
        let blueLine: [CGPoint]
        let greenLine: [CGPoint]
        let redLine: [CGPoint]
        let blueTokens: [(x: CGFloat, y: CGFloat, token: DepositedToken)]
        let greenTokens: [(x: CGFloat, y: CGFloat, token: DepositedToken)]
        let redTokens: [(x: CGFloat, y: CGFloat, token: DepositedToken)]
    }

    private func buildResult(
        blueOffsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)],
        greenOffsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)],
        redOffsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)],
        bases: SpreadBases,
        tokenPositions: [(x: CGFloat, token: DepositedToken)],
        lineStartX: CGFloat, lineEndX: CGFloat
    ) -> SeparatedResult {
        // Each line only has control points at its own tokens (+ start/end)
        func linePoints(_ offsets: [(x: CGFloat, offset: CGFloat, token: DepositedToken)], base: CGFloat) -> [CGPoint] {
            var pts = [CGPoint(x: lineStartX, y: base)]
            for p in offsets {
                pts.append(CGPoint(x: p.x, y: base + p.offset))
            }
            pts.append(CGPoint(x: lineEndX, y: base + (offsets.last?.offset ?? 0)))
            return pts
        }

        let blueLine = linePoints(blueOffsets, base: bases.blue)
        let greenLine = linePoints(greenOffsets, base: bases.green)
        let redLine = linePoints(redOffsets, base: bases.red)

        let blueTokens = blueOffsets.map { p in (x: p.x, y: bases.blue + p.offset, token: p.token) }
        let greenTokens = greenOffsets.map { p in (x: p.x, y: bases.green + p.offset, token: p.token) }
        let redTokens = redOffsets.map { p in (x: p.x, y: bases.red + p.offset, token: p.token) }

        return SeparatedResult(
            blueLine: blueLine, greenLine: greenLine, redLine: redLine,
            blueTokens: blueTokens, greenTokens: greenTokens, redTokens: redTokens
        )
    }

    // MARK: - Smooth line using Catmull-Rom spline
    private func linePath(points: [CGPoint]) -> some View {
        Path { path in
            guard points.count >= 2 else { return }
            path.move(to: points[0])

            if points.count == 2 {
                path.addLine(to: points[1])
                return
            }

            // Convert Catmull-Rom to cubic Bézier segments
            let alpha: CGFloat = 0.5 // centripetal
            for i in 0..<(points.count - 1) {
                let p0 = points[max(i - 1, 0)]
                let p1 = points[i]
                let p2 = points[min(i + 1, points.count - 1)]
                let p3 = points[min(i + 2, points.count - 1)]

                let d1 = hypot(p1.x - p0.x, p1.y - p0.y)
                let d2 = hypot(p2.x - p1.x, p2.y - p1.y)
                let d3 = hypot(p3.x - p2.x, p3.y - p2.y)

                let d1a = pow(d1, alpha)
                let d2a = pow(d2, alpha)
                let d3a = pow(d3, alpha)

                var cp1 = p1
                if d1a + d2a > 0.0001 {
                    let b = d1a * 2
                    let a = d2a * 2
                    cp1 = CGPoint(
                        x: (a * p0.x + b * p2.x - d2a * p1.x * 2 + d1a * p1.x * 2) / (a + b) * (d2a / (d1a + d2a)) + p1.x * (1 - d2a / (d1a + d2a)),
                        y: (a * p0.y + b * p2.y - d2a * p1.y * 2 + d1a * p1.y * 2) / (a + b) * (d2a / (d1a + d2a)) + p1.y * (1 - d2a / (d1a + d2a))
                    )
                    // Simpler formulation
                    cp1 = CGPoint(
                        x: p1.x + (p2.x - p0.x) / (3 * (1 + d1 / d2)),
                        y: p1.y + (p2.y - p0.y) / (3 * (1 + d1 / d2))
                    )
                }

                var cp2 = p2
                if d2a + d3a > 0.0001 {
                    cp2 = CGPoint(
                        x: p2.x - (p3.x - p1.x) / (3 * (1 + d3 / d2)),
                        y: p2.y - (p3.y - p1.y) / (3 * (1 + d3 / d2))
                    )
                }

                path.addCurve(to: p2, control1: cp1, control2: cp2)
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
