import SwiftUI

// MARK: - 3D Chest Face Shapes

// Front face of the chest body
struct ChestFrontFace: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// Top face parallelogram (receding to top-right)
struct ChestTopFace: Shape {
    var depth: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + depth, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX + depth, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// Right face parallelogram (receding to top-right)
struct ChestRightFace: Shape {
    var depth: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY - depth))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - depth))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Treasure Chest View

struct TreasureChestView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let shapeChoice: ShapeChoice
    let tokenID: String
    var showALabel: Bool = false
    var showILabel: Bool = false
    var showMLabel: Bool = false
    let onComplete: () -> Void

    // Chest geometry constants
    private let cw: CGFloat = 180       // chest front width
    private let ch: CGFloat = 110       // chest front height
    private let depth: CGFloat = 50     // 3-D depth offset
    private let lidH: CGFloat = 50      // lid front height (increased from 35)
    private let wallT: CGFloat = 18     // wall thickness (10% of cw)

    // Animation state
    @State private var lidOpen: Double = 0        // 0 = closed, 1 = fully open
    @State private var tokenX: CGFloat = -80
    @State private var tokenY: CGFloat = 0
    @State private var tokenScale: CGFloat = 1.0
    @State private var tokenOpacity: Double = 0
    @State private var tokenXAngle: Double = 0     // 3D rotation X
    @State private var tokenYAngle: Double = 0     // 3D rotation Y
    @State private var showSparkles = false
    @State private var glowAmount: Double = 0
    @State private var showToken = false
    @State private var tokenInsideChest = false    // true = behind front face

    private var tokenColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }

    private var tokenCoinView: some View {
        CoinTokenView(
            shade: shade,
            colorChoice: colorChoice,
            shapeChoice: shapeChoice,
            xAngle: tokenXAngle,
            yAngle: tokenYAngle,
            showALabel: showALabel,
            showILabel: showILabel,
            showMLabel: showMLabel,
            showGoldRim: showALabel && showILabel && showMLabel
        )
    }

    // Lid animation derived values
    private var lidYShift: CGFloat { -CGFloat(lidOpen) * (lidH * 3.0 + depth) }

    // Colors for each face
    private let frontColor = LinearGradient(
        colors: [Color(red: 0.62, green: 0.42, blue: 0.22),
                 Color(red: 0.44, green: 0.28, blue: 0.14)],
        startPoint: .top, endPoint: .bottom)
    private let topColor = LinearGradient(
        colors: [Color(red: 0.72, green: 0.52, blue: 0.30),
                 Color(red: 0.56, green: 0.38, blue: 0.20)],
        startPoint: .leading, endPoint: .trailing)
    private let sideColor = LinearGradient(
        colors: [Color(red: 0.50, green: 0.32, blue: 0.16),
                 Color(red: 0.34, green: 0.22, blue: 0.10)],
        startPoint: .top, endPoint: .bottom)
    private let lidFrontColor = LinearGradient(
        colors: [Color(red: 0.58, green: 0.38, blue: 0.20),
                 Color(red: 0.40, green: 0.24, blue: 0.12)],
        startPoint: .top, endPoint: .bottom)
    private let lidTopColor = LinearGradient(
        colors: [Color(red: 0.68, green: 0.48, blue: 0.28),
                 Color(red: 0.52, green: 0.34, blue: 0.18)],
        startPoint: .leading, endPoint: .trailing)
    private let lidSideColor = LinearGradient(
        colors: [Color(red: 0.46, green: 0.28, blue: 0.14),
                 Color(red: 0.30, green: 0.18, blue: 0.08)],
        startPoint: .top, endPoint: .bottom)

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2 - cw / 2   // chest left x
            let cy = geo.size.height / 2 - 20       // chest top y

            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.04, blue: 0.02),
                             Color(red: 0.18, green: 0.10, blue: 0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                // Shadow under chest
                Ellipse()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: cw + 40, height: 30)
                    .blur(radius: 15)
                    .position(x: cx + cw / 2, y: cy + ch + 25)

                // ── SPARKLES + GLOW (behind the chest) ──────────
                if showSparkles {
                    ForEach(0..<24, id: \.self) { i in
                        let angle = Double(i) * 15.0
                        let rad = CGFloat(angle * .pi / 180)
                        let dist: CGFloat = 60 + CGFloat(i % 4) * 50
                        let sx = cx + cw / 2 + CGFloat(cos(Double(rad))) * dist
                        let sy = cy + CGFloat(sin(Double(rad))) * dist * 0.6
                        let size = CGFloat(3 + i % 4) * 1.5
                        Circle()
                            .fill(i % 3 == 0 ? Color.white : Color.yellow)
                            .frame(width: size, height: size)
                            .position(x: sx, y: sy)
                            .opacity(Double(1 + i % 2) * 0.5)
                            .shadow(color: .yellow.opacity(0.8), radius: 4)
                            .animation(
                                .easeInOut(duration: 0.5 + Double(i % 3) * 0.3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.05),
                                value: showSparkles)
                    }
                }

                if glowAmount > 0 {
                    RadialGradient(
                        colors: [Color.yellow.opacity(glowAmount * 0.5),
                                 Color.orange.opacity(glowAmount * 0.35),
                                 Color.yellow.opacity(glowAmount * 0.2),
                                 Color.orange.opacity(glowAmount * 0.1),
                                 Color.clear],
                        center: UnitPoint(x: 0.5, y: 0.45),
                        startRadius: 20, endRadius: 500)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .blendMode(.screen)

                    RadialGradient(
                        colors: [Color.white.opacity(glowAmount * 0.4),
                                 Color.yellow.opacity(glowAmount * 0.6),
                                 Color.orange.opacity(glowAmount * 0.3),
                                 Color.clear],
                        center: .center, startRadius: 5, endRadius: 200)
                    .frame(width: geo.size.width, height: geo.size.width)
                    .position(x: cx + cw / 2, y: cy + ch / 2 - 20)
                    .allowsHitTesting(false)
                    .blendMode(.screen)

                    ForEach(0..<8, id: \.self) { i in
                        let rayAngle = CGFloat(Double(i) * 45.0 * .pi / 180)
                        let rayLen: CGFloat = geo.size.width * 0.6
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(glowAmount * 0.3),
                                             Color.clear],
                                    startPoint: .leading, endPoint: .trailing))
                            .frame(width: rayLen, height: 3)
                            .rotationEffect(.radians(Double(rayAngle)))
                            .position(x: cx + cw / 2, y: cy + ch / 2 - 20)
                            .allowsHitTesting(false)
                            .blendMode(.screen)
                    }
                }

                // ── CHEST INTERIOR (very dark, visible when lid opens) ──
                // Interior back wall (smaller than outer to show 8% wall thickness)
                let chestWallT: CGFloat = cw * 0.08  // 8% of chest width
                ChestFrontFace()
                    .fill(Color(red: 0.02, green: 0.01, blue: 0.005))
                    .frame(width: cw - chestWallT * 2, height: ch - chestWallT * 2)
                    .position(x: cx + cw / 2, y: cy + ch / 2)
                    .offset(x: 0, y: chestWallT / 2)  // Shift down to show top wall
                    .opacity(lidOpen)
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 0)

                // Interior bottom (smaller to show wall thickness)
                ChestTopFace(depth: depth - chestWallT)
                    .fill(Color(red: 0.015, green: 0.01, blue: 0.005))
                    .frame(width: cw - chestWallT * 2, height: depth - chestWallT)
                    .position(x: cx + cw / 2, y: cy - depth / 2 + chestWallT)
                    .opacity(lidOpen)

                // Interior right side wall (smaller to show wall thickness)
                ChestRightFace(depth: depth - chestWallT)
                    .fill(Color(red: 0.015, green: 0.01, blue: 0.005))
                    .frame(width: depth - chestWallT, height: ch - chestWallT * 2)
                    .position(x: cx + cw + depth / 2 - chestWallT / 2, y: cy + ch / 2)
                    .offset(x: -chestWallT / 2, y: 0)  // Shift left to show left wall
                    .opacity(lidOpen)

                // ── CHEST BODY (outer walls) ──────────────────
                // Right side face
                ChestRightFace(depth: depth)
                    .fill(sideColor)
                    .frame(width: depth, height: ch)
                    .position(x: cx + cw + depth / 2, y: cy + ch / 2)

                // Top face
                ChestTopFace(depth: depth)
                    .fill(topColor)
                    .frame(width: cw, height: depth)
                    .position(x: cx + cw / 2, y: cy - depth / 2)

                // ── TOKEN INSIDE CHEST (behind front face, shown via zIndex) ─────────
                if showToken && tokenInsideChest {
                    tokenCoinView
                        .frame(width: 100, height: 100)
                        .scaleEffect(tokenScale)
                        .position(x: cx + cw / 2 + tokenX,
                                  y: cy + ch / 2 + tokenY)
                        .shadow(color: tokenColor.opacity(0.6), radius: 10, y: 5)
                        .opacity(tokenOpacity)
                }

                // Front face
                ChestFrontFace()
                    .fill(frontColor)
                    .frame(width: cw, height: ch)
                    .position(x: cx + cw / 2, y: cy + ch / 2)

                // ── DARKER BROWN THICKNESS BORDER ON FRONT FACE ──
                // Top border
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.18, blue: 0.08))
                    .frame(width: cw, height: wallT)
                    .position(x: cx + cw / 2, y: cy + wallT / 2)
                // Bottom border
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.18, blue: 0.08))
                    .frame(width: cw, height: wallT)
                    .position(x: cx + cw / 2, y: cy + ch - wallT / 2)
                // Left border
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.18, blue: 0.08))
                    .frame(width: wallT, height: ch)
                    .position(x: cx + wallT / 2, y: cy + ch / 2)
                // Right border
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.18, blue: 0.08))
                    .frame(width: wallT, height: ch)
                    .position(x: cx + cw - wallT / 2, y: cy + ch / 2)

                // ── WALL THICKNESS ON TOP OF LOWER CHEST ──
                // These are always present; the lid hides them when closed.
                // Front wall top rim — same color as front face
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.62, green: 0.42, blue: 0.22),
                                 Color(red: 0.52, green: 0.34, blue: 0.18)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: cw, height: wallT * 0.6)
                    .position(x: cx + cw / 2, y: cy + wallT * 0.3)
                // Right wall top rim — same color as side face
                ChestRightFace(depth: depth)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.50, green: 0.32, blue: 0.16),
                                 Color(red: 0.40, green: 0.26, blue: 0.12)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: depth, height: wallT * 0.6)
                    .position(x: cx + cw + depth / 2, y: cy + wallT * 0.3)
                // Top face front rim — same color as top face
                ChestTopFace(depth: wallT * 0.6)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.72, green: 0.52, blue: 0.30),
                                 Color(red: 0.56, green: 0.38, blue: 0.20)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: cw, height: wallT * 0.6)
                    .position(x: cx + cw / 2, y: cy - wallT * 0.3)

                // Edge outlines for definition
                ChestFrontFace()
                    .stroke(Color.black.opacity(0.5), lineWidth: 2)
                    .frame(width: cw, height: ch)
                    .position(x: cx + cw / 2, y: cy + ch / 2)
                ChestTopFace(depth: depth)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                    .frame(width: cw, height: depth)
                    .position(x: cx + cw / 2, y: cy - depth / 2)
                ChestRightFace(depth: depth)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                    .frame(width: depth, height: ch)
                    .position(x: cx + cw + depth / 2, y: cy + ch / 2)

                // ── WOOD GRAIN ON ALL FACES ──────────────
                // Front face grain
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.25))
                        .frame(width: cw - wallT * 2 - 10, height: 1.5)
                        .position(x: cx + cw / 2, y: cy + wallT + 12 + CGFloat(i) * 20)
                }
                // Right side face grain
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(Color(red: 0.25, green: 0.15, blue: 0.08).opacity(0.25))
                        .frame(width: depth - 10, height: 1.5)
                        .rotationEffect(.degrees(-45))
                        .position(x: cx + cw + depth / 2, y: cy + 20 + CGFloat(i) * 26)
                }
                // Top face grain
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(Color(red: 0.35, green: 0.25, blue: 0.13).opacity(0.2))
                        .frame(width: cw - 20, height: 1.5)
                        .rotationEffect(.degrees(-25))
                        .position(x: cx + cw / 2 + depth / 4, y: cy - depth / 2 + 8 + CGFloat(i) * 16)
                }

                // ── BRASS CORNER REINFORCEMENTS (8 on lower chest outside) ──
                let brassColor = LinearGradient(
                    colors: [Color(red: 0.80, green: 0.68, blue: 0.35),
                             Color(red: 0.65, green: 0.55, blue: 0.28)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                let brassSize: CGFloat = 18
                let brassW: CGFloat = 4

                // ── Front face: 4 outside corners ──
                // Front top-left
                Rectangle().fill(brassColor).frame(width: brassSize, height: brassW)
                    .position(x: cx + brassSize / 2, y: cy + brassW / 2)
                Rectangle().fill(brassColor).frame(width: brassW, height: brassSize)
                    .position(x: cx + brassW / 2, y: cy + brassSize / 2)
                // Front top-right
                Rectangle().fill(brassColor).frame(width: brassSize, height: brassW)
                    .position(x: cx + cw - brassSize / 2, y: cy + brassW / 2)
                Rectangle().fill(brassColor).frame(width: brassW, height: brassSize)
                    .position(x: cx + cw - brassW / 2, y: cy + brassSize / 2)
                // Front bottom-left
                Rectangle().fill(brassColor).frame(width: brassSize, height: brassW)
                    .position(x: cx + brassSize / 2, y: cy + ch - brassW / 2)
                Rectangle().fill(brassColor).frame(width: brassW, height: brassSize)
                    .position(x: cx + brassW / 2, y: cy + ch - brassSize / 2)
                // Front bottom-right
                Rectangle().fill(brassColor).frame(width: brassSize, height: brassW)
                    .position(x: cx + cw - brassSize / 2, y: cy + ch - brassW / 2)
                Rectangle().fill(brassColor).frame(width: brassW, height: brassSize)
                    .position(x: cx + cw - brassW / 2, y: cy + ch - brassSize / 2)

                // ── Right side face: 4 outside corners ──
                // Right top-near (front edge, top)
                Rectangle().fill(brassColor).frame(width: brassW, height: brassSize)
                    .position(x: cx + cw + brassW / 2, y: cy + brassSize / 2)
                // Right top-far (back edge, top — diagonal)
                Rectangle().fill(brassColor).frame(width: brassSize * 0.7, height: brassW)
                    .rotationEffect(.degrees(-45))
                    .position(x: cx + cw + depth - 8, y: cy - depth + 8)
                // Right bottom-near (front edge, bottom)
                Rectangle().fill(brassColor).frame(width: brassW, height: brassSize)
                    .position(x: cx + cw + brassW / 2, y: cy + ch - brassSize / 2)
                // Right bottom-far (back edge, bottom — diagonal)
                Rectangle().fill(brassColor).frame(width: brassSize * 0.7, height: brassW)
                    .rotationEffect(.degrees(-45))
                    .position(x: cx + cw + depth - 8, y: cy + ch - depth + 6)

                // ── METAL HINGES (on front face) ──
                let hingeColor = LinearGradient(
                    colors: [Color(red: 0.5, green: 0.5, blue: 0.55),
                             Color(red: 0.3, green: 0.3, blue: 0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                // Left hinge
                Rectangle().fill(hingeColor).frame(width: 12, height: 25)
                    .position(x: cx + 8, y: cy + ch / 2)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                // Right hinge
                Rectangle().fill(hingeColor).frame(width: 12, height: 25)
                    .position(x: cx + cw - 8, y: cy + ch / 2)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                // ── LOCK (center of front face) ──
                ZStack {
                    // Lock body
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.6, green: 0.55, blue: 0.5),
                                     Color(red: 0.4, green: 0.35, blue: 0.3)],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: 28, height: 36)
                        .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                    // Lock shackle (arc)
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: 14, y: -8),
                            radius: 10,
                            startAngle: .degrees(0),
                            endAngle: .degrees(180),
                            clockwise: false
                        )
                    }
                    .stroke(LinearGradient(
                        colors: [Color(red: 0.7, green: 0.65, blue: 0.6),
                                 Color(red: 0.5, green: 0.45, blue: 0.4)],
                        startPoint: .leading, endPoint: .trailing),
                        lineWidth: 4)
                    .frame(width: 28, height: 20)
                    .position(x: cx + cw / 2, y: cy + ch / 2 - 10)
                    // Keyhole
                    Circle()
                        .fill(Color.black)
                        .frame(width: 6, height: 6)
                        .position(x: cx + cw / 2, y: cy + ch / 2 + 2)
                }
                .frame(width: 28, height: 36)
                .position(x: cx + cw / 2, y: cy + ch / 2)

                // ── CHEST LID ───────────────────────────
                // The lid pivots on its back edge (top-right of chest)
                // We simulate the 3D open by shrinking lid height + moving up

                // Lid right side face (constant height - never shrinks)
                ChestRightFace(depth: depth)
                    .fill(lidSideColor)
                    .frame(width: depth, height: lidH)
                    .position(x: cx + cw + depth / 2,
                              y: cy - lidH / 2 + lidYShift)

                // Lid top face
                ChestTopFace(depth: depth)
                    .fill(lidTopColor)
                    .frame(width: cw, height: depth)
                    .position(x: cx + cw / 2,
                              y: cy - lidH - depth / 2 + lidYShift)

                // Lid front face
                ChestFrontFace()
                    .fill(lidFrontColor)
                    .frame(width: cw, height: lidH)
                    .position(x: cx + cw / 2,
                              y: cy - lidH + lidH / 2 + lidYShift)

                // ── DARKER BROWN THICKNESS BORDER ON LID FRONT ──
                let lidBorderT: CGFloat = wallT * 0.7
                let lidFY = cy - lidH + lidH / 2 + lidYShift
                // Top border
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.18, blue: 0.09))
                    .frame(width: cw, height: lidBorderT)
                    .position(x: cx + cw / 2, y: lidFY - lidH / 2 + lidBorderT / 2)
                // Bottom border
                Rectangle()
                    .fill(Color(red: 0.28, green: 0.16, blue: 0.07))
                    .frame(width: cw, height: lidBorderT)
                    .position(x: cx + cw / 2, y: lidFY + lidH / 2 - lidBorderT / 2)
                // Left border
                Rectangle()
                    .fill(Color(red: 0.28, green: 0.16, blue: 0.07))
                    .frame(width: lidBorderT, height: lidH)
                    .position(x: cx + lidBorderT / 2, y: lidFY)
                // Right border
                Rectangle()
                    .fill(Color(red: 0.30, green: 0.18, blue: 0.09))
                    .frame(width: lidBorderT, height: lidH)
                    .position(x: cx + cw - lidBorderT / 2, y: lidFY)

                // Lid outlines
                ChestFrontFace()
                    .stroke(Color.black.opacity(0.5), lineWidth: 2)
                    .frame(width: cw, height: lidH)
                    .position(x: cx + cw / 2,
                              y: cy - lidH + lidH / 2 + lidYShift)
                ChestTopFace(depth: depth)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                    .frame(width: cw, height: depth)
                    .position(x: cx + cw / 2,
                              y: cy - lidH - depth / 2 + lidYShift)
                ChestRightFace(depth: depth)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                    .frame(width: depth, height: lidH)
                    .position(x: cx + cw + depth / 2,
                              y: cy - lidH / 2 + lidYShift)

                // Metal clasp on lid front
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.9, green: 0.8, blue: 0.5),
                                 Color(red: 0.6, green: 0.5, blue: 0.3)],
                        center: .topLeading, startRadius: 1, endRadius: 10))
                    .frame(width: 16, height: 16)
                    .position(x: cx + cw / 2,
                              y: cy - lidH + lidH / 2 + lidYShift)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)

                // ── TOKEN IN FRONT (flying in phase) ─────────
                if showToken && !tokenInsideChest {
                    tokenCoinView
                        .frame(width: 100, height: 100)
                        .scaleEffect(tokenScale)
                        .position(x: cx + cw / 2 + tokenX,
                                  y: cy + ch / 2 + tokenY)
                        .shadow(color: tokenColor.opacity(0.6), radius: 10, y: 5)
                        .opacity(tokenOpacity)
                }

                // No UI overlay - auto-navigates after animation
            }
        }
        .onAppear { startAnimation() }
    }

    // MARK: - Animation Sequence
    private func startAnimation() {
        // Phase 1 — Lid swings open with bounce (1.5 s)
        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 1.5)) {
            lidOpen = 0.9
        }
        // Small bounce at the end
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                lidOpen = 1.0
            }
        }

        // Phase 2 — Subtle glow appears as lid opens (starts at 0.3 s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.6)) {
                glowAmount = 0.8
            }
        }
        // Fade out glow (before Phase 3 starts)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                glowAmount = 0
            }
        }

        // Phase 3 — Token enters from left, slides to front of chest (starts at 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showToken = true
            tokenOpacity = 1.0
            tokenScale = 0.6
            tokenX = -280
            tokenY = 0
            tokenXAngle = 0
            tokenYAngle = 0

            // Slide to front of chest (face-up, no spinning)
            withAnimation(.easeOut(duration: 1.2)) {
                tokenX = 0
                tokenY = 0
                tokenScale = 0.5
            }
        }

        // Phase 4 — Brief pause in front of chest showing letters (2.7s–4.0s)
        // (token is stationary and face-up for 1.3s)

        // Phase 5 — Flip and rise up+right into the lifted lid (starts at 4.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 1.5)) {
                tokenX = 25     // Slight shift right (toward 3D depth)
                tokenY = -200   // Rise higher into lid area
                tokenScale = 0.35 // Shrink slightly (further back into depth)
            }
            withAnimation(.linear(duration: 1.5)) {
                tokenXAngle = 720
                tokenYAngle = 360
            }
        }

        // Phase 6 — Brief pause at top inside lid (5.5s–6.5s)
        // (token holds position for 1.0s)

        // Phase 7 — Drop down into chest (starts at 6.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
            tokenInsideChest = true
            withAnimation(.easeIn(duration: 1.0)) {
                tokenY = ch / 16 - 10
                tokenScale = 0.35
            }
            withAnimation(.linear(duration: 1.0)) {
                tokenXAngle = 0
                tokenYAngle = 0
            }
        }

        // Phase 8 — Token fades as it drops (starts at 7.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            withAnimation(.easeIn(duration: 0.8)) {
                tokenOpacity = 0
                tokenScale = 0.25
            }
        }

        // Phase 9 — Lid closes (starts at 8.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.5)) {
                lidOpen = 0
            }
        }

        // Phase 10 — Auto-navigate (starts at 9.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.8) {
            onComplete()
        }
    }
}

struct TreasureChestView_Previews: PreviewProvider {
    static var previews: some View {
        TreasureChestView(
            shade: .black, colorChoice: .blue, shapeChoice: .circle,
            tokenID: "TOKEN-A3F2B1C9", onComplete: {})
    }
}
