import SwiftUI

// MARK: - Shared 3D Coin Token View

struct CoinTokenView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let xAngle: Double
    let yAngle: Double
    var showALabel: Bool = true
    var showILabel: Bool = false
    var showMLabel: Bool = false
    var aLabelOpacity: Double = 1.0
    var iLabelOpacity: Double = 1.0
    var mLabelOpacity: Double = 1.0
    var showGoldRim: Bool = false
    var rimProgress: CGFloat = 1.0

    private let coinLayers = 5
    private let layerDepth: CGFloat = 2.5

    private var tokenColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }

    private var impressionAnchor: UnitPoint {
        TokenShapeHelper.impressionAnchor(for: shapeChoice)
    }

    private var anchorY: CGFloat {
        TokenShapeHelper.centroidAnchor(for: shapeChoice).y
    }

    private var labelsCenterOffset: CGFloat {
        (anchorY - 0.5) * 124
    }

    // Subtle gold palette
    static let goldLight = Color(red: 0.90, green: 0.80, blue: 0.45)
    static let goldDark = Color(red: 0.75, green: 0.60, blue: 0.20)
    static let goldLabel = Color(red: 0.85, green: 0.70, blue: 0.15)

    var body: some View {
        ZStack {
            // Protruding ridge layers - create visible 3D edge
            ForEach(0..<coinLayers, id: \.self) { i in
                TokenShapeHelper.shapeView(shape: shapeChoice, color: showGoldRim ? Self.goldDark.opacity(0.7) : tokenColor.opacity(0.8))
                    .allowsHitTesting(false)
                    .modifier(CoinFaceEffect(
                        xAngle: xAngle, yAngle: yAngle,
                        zOffset: -CGFloat(coinLayers - i) * layerDepth,
                        isFront: true, isEdge: true,
                        anchorY: anchorY
                    ))
            }

            // Back face
            backFace
                .allowsHitTesting(false)
                .modifier(CoinFaceEffect(
                    xAngle: xAngle, yAngle: yAngle,
                    zOffset: -CGFloat(coinLayers) * layerDepth,
                    isFront: false, isEdge: false,
                    anchorY: anchorY
                ))

            // Front face
            baseFace
                .shadow(color: showGoldRim ? Self.goldLight.opacity(0.3) : .black.opacity(0.12), radius: showGoldRim ? 10 : 8, y: 4)
                .modifier(CoinFaceEffect(
                    xAngle: xAngle, yAngle: yAngle,
                    zOffset: 0,
                    isFront: true, isEdge: false,
                    anchorY: anchorY
                ))
        }
    }

    // MARK: - Labels (centered VStack at centroid)

    @ViewBuilder
    private var centeredLabels: some View {
        VStack(spacing: 2) {
            if showALabel {
                Text("A")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Self.goldLabel)
                    .opacity(aLabelOpacity)
            }
            if showILabel {
                Text("I")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Self.goldLabel)
                    .opacity(iLabelOpacity)
            }
            if showMLabel {
                Text("M")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Self.goldLabel)
                    .opacity(mLabelOpacity)
            }
        }
        .offset(y: labelsCenterOffset)
        .allowsHitTesting(false)
    }

    // MARK: - Faces

    @ViewBuilder
    private var baseFace: some View {
        ZStack {
            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(0.8))

            TokenShapeHelper.shapeView(shape: shapeChoice, color: .black.opacity(0.2))
                .scaleEffect(0.90, anchor: impressionAnchor)

            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(1.0))
                .scaleEffect(0.86, anchor: impressionAnchor)

            // Gold rim line (animated trim)
            if showGoldRim {
                TokenShapeHelper.trimmedStrokeView(
                    shape: shapeChoice, lineWidth: 3,
                    color: Self.goldDark, trimEnd: rimProgress
                )
                .scaleEffect(0.93, anchor: impressionAnchor)
                .shadow(color: Self.goldLight.opacity(0.4), radius: 4)
            }

            centeredLabels
        }
    }

    @ViewBuilder
    private var backFace: some View {
        ZStack {
            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(0.8))

            TokenShapeHelper.shapeView(shape: shapeChoice, color: .black.opacity(0.2))
                .scaleEffect(0.90, anchor: impressionAnchor)

            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(1.0))
                .scaleEffect(0.86, anchor: impressionAnchor)

            if showGoldRim {
                TokenShapeHelper.trimmedStrokeView(
                    shape: shapeChoice, lineWidth: 3,
                    color: Self.goldDark, trimEnd: rimProgress
                )
                .scaleEffect(0.93, anchor: impressionAnchor)
                .shadow(color: Self.goldLight.opacity(0.4), radius: 4)
            }

            centeredLabels
        }
    }
}

// MARK: - Shared Flip Animation Logic

enum FlipAnimationState {
    static let flipDuration: Double = 3.0

    struct AnimationStage {
        let duration: Double
        let scale: CGFloat
    }

    static let appearStages: [AnimationStage] = [
        AnimationStage(duration: 0.20, scale: 0.20),
        AnimationStage(duration: 0.36, scale: 0.40),
        AnimationStage(duration: 0.56, scale: 0.60),
        AnimationStage(duration: 0.76, scale: 0.80),
        AnimationStage(duration: 1.00, scale: 1.00),
    ]
}
