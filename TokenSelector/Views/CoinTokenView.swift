import SwiftUI

// MARK: - Shared 3D Coin Token View

struct CoinTokenView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let xAngle: Double
    let yAngle: Double
    
    private let coinLayers = 5
    private let layerDepth: CGFloat = 2.5
    
    private var tokenColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }
    
    private var impressionAnchor: UnitPoint {
        TokenShapeHelper.impressionAnchor(for: shapeChoice)
    }
    
    var body: some View {
        ZStack {
            // Protruding ridge layers - create visible 3D edge
            ForEach(0..<coinLayers, id: \.self) { i in
                TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(0.8))
                    .allowsHitTesting(false)
                    .modifier(CoinFaceEffect(
                        xAngle: xAngle,
                        yAngle: yAngle,
                        zOffset: -CGFloat(coinLayers - i) * layerDepth,
                        isFront: true,
                        isEdge: true
                    ))
            }
            
            // Back face - visible when front faces away
            backFace
                .allowsHitTesting(false)
                .modifier(CoinFaceEffect(
                    xAngle: xAngle,
                    yAngle: yAngle,
                    zOffset: -CGFloat(coinLayers) * layerDepth,
                    isFront: false,
                    isEdge: false
                ))
            
            // Front face - visible when facing viewer
            baseFace
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .modifier(CoinFaceEffect(
                    xAngle: xAngle,
                    yAngle: yAngle,
                    zOffset: 0,
                    isFront: true,
                    isEdge: false
                ))
        }
    }
    
    @ViewBuilder
    private var baseFace: some View {
        ZStack {
            // Protruding ridge
            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(0.8))
            
            // Shadow line inside ridge
            TokenShapeHelper.shapeView(shape: shapeChoice, color: .black.opacity(0.2))
                .scaleEffect(0.90, anchor: impressionAnchor)
            
            // Flat center - vibrant token color
            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(1.0))
                .scaleEffect(0.86, anchor: impressionAnchor)
        }
    }
    
    @ViewBuilder
    private var backFace: some View {
        ZStack {
            // Protruding ridge - same as front
            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(0.8))
            
            // Shadow line inside ridge
            TokenShapeHelper.shapeView(shape: shapeChoice, color: .black.opacity(0.2))
                .scaleEffect(0.90, anchor: impressionAnchor)
            
            // Back center - exactly same as front
            TokenShapeHelper.shapeView(shape: shapeChoice, color: tokenColor.opacity(1.0))
                .scaleEffect(0.86, anchor: impressionAnchor)
        }
    }
}

// MARK: - Shared Flip Animation Logic

struct FlipAnimationState {
    var xAngle: Double = 0
    var yAngle: Double = 0
    
    static let flipDuration: Double = 3.0
    
    struct DisappearStage {
        let duration: Double
        let scale: CGFloat
        let axis: String
    }
    
    static let disappearStages: [DisappearStage] = [
        DisappearStage(duration: 1.00, scale: 0.80, axis: "x"),
        DisappearStage(duration: 0.76, scale: 0.60, axis: "y"),
        DisappearStage(duration: 0.56, scale: 0.40, axis: "x"),
        DisappearStage(duration: 0.36, scale: 0.20, axis: "y"),
        DisappearStage(duration: 0.20, scale: 0.01, axis: "x"),
    ]
    
    static let appearStages: [DisappearStage] = [
        DisappearStage(duration: 0.20, scale: 0.20, axis: "x"),
        DisappearStage(duration: 0.36, scale: 0.40, axis: "y"),
        DisappearStage(duration: 0.56, scale: 0.60, axis: "x"),
        DisappearStage(duration: 0.76, scale: 0.80, axis: "y"),
        DisappearStage(duration: 1.00, scale: 1.00, axis: "x"),
    ]
}
