import SwiftUI

struct ShapeSelectionView: View {
    let shade: ShadeChoice
    let colorChoice: ColorChoice
    let showILabel: Bool
    let onSelect: (ShapeChoice, Bool, Bool) -> Void  // (shape, paused3s, showMLabel)

    @State private var crossScale: CGFloat = 0
    @State private var shapesOpacity: Double = 0.0
    @State private var wipeOffset: CGFloat = 0
    @State private var hasAppeared = false
    @State private var appearDate: Date = Date()

    // Hold gesture state
    @State private var heldShape: ShapeChoice? = nil
    @State private var pressStartDate: Date? = nil
    @State private var cartwheelInPlaceStart: Date? = nil
    @State private var viewSize: CGSize = .zero

    // Post-selection animation state
    @State private var pickedShape: ShapeChoice? = nil
    @State private var tokenX: CGFloat = 0
    @State private var tokenY: CGFloat = 0
    @State private var tokenSize: CGFloat = 0
    @State private var tokenRotation: Double = 0
    @State private var fadeWhite: Double = 0
    @State private var showMLabel: Bool = false

    private var bgColor: Color {
        ColorHelper.resolve(color: colorChoice, shade: shade)
    }

    private var outlineColor: Color {
        shade == .black ? .white : .black
    }

    private var crossColor: Color {
        shade == .black ? .black : .white
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width / 2
            let h = geo.size.height / 2

            ZStack {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // Upper-left: Square
                        ZStack {
                            bgColor
                            SquareShape()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.72, height: min(w, h) * 0.72)
                                .opacity(shapesOpacity)
                                .overlay(
                                    SquareShape()
                                        .stroke(outlineColor, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.72, height: min(w, h) * 0.72)
                                        .opacity(shapesOpacity)
                                )
                                .offset(y: 40)
                                .contentShape(SquareShape())
                                .gesture(holdGesture(for: .square))
                        }
                        .frame(width: w, height: h)

                        // Upper-right: Triangle Down
                        ZStack {
                            bgColor
                            TriangleDown()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                .opacity(shapesOpacity)
                                .overlay(
                                    TriangleDown()
                                        .stroke(outlineColor, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                        .opacity(shapesOpacity)
                                )
                                .offset(y: 60)
                                .contentShape(TriangleDown())
                                .gesture(holdGesture(for: .triangleDown))
                        }
                        .frame(width: w, height: h)
                    }

                    HStack(spacing: 0) {
                        // Lower-left: Triangle Up
                        ZStack {
                            bgColor
                            TriangleUp()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                .opacity(shapesOpacity)
                                .overlay(
                                    TriangleUp()
                                        .stroke(outlineColor, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.88, height: min(w, h) * 0.88)
                                        .opacity(shapesOpacity)
                                )
                                .offset(y: -60)
                                .contentShape(TriangleUp())
                                .gesture(holdGesture(for: .triangleUp))
                        }
                        .frame(width: w, height: h)

                        // Lower-right: Circle
                        ZStack {
                            bgColor
                            Circle()
                                .fill(bgColor)
                                .frame(width: min(w, h) * 0.72, height: min(w, h) * 0.72)
                                .opacity(shapesOpacity)
                                .overlay(
                                    Circle()
                                        .stroke(outlineColor, lineWidth: 3)
                                        .frame(width: min(w, h) * 0.72, height: min(w, h) * 0.72)
                                        .opacity(shapesOpacity)
                                )
                                .offset(y: -50)
                                .contentShape(Circle())
                                .gesture(holdGesture(for: .circle))
                        }
                        .frame(width: w, height: h)
                    }
                }

                // Solid color overlay — fades out to reveal shapes underneath
                bgColor
                    .ignoresSafeArea()
                    .opacity(1.0 - wipeOffset)
                    .allowsHitTesting(false)

                // Black cross — expands from center dot
                CrossShape()
                    .stroke(crossColor, lineWidth: 2)
                    .frame(width: geo.size.width * crossScale, height: geo.size.height * crossScale)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .allowsHitTesting(false)

                // Fade to white overlay
                Color.white
                    .ignoresSafeArea()
                    .opacity(fadeWhite)
                    .allowsHitTesting(false)

                // Token (appears after 0.75s hold, cartwheels in place or to destination)
                if let shape = pickedShape {
                    CoinTokenView(
                        shade: shade,
                        colorChoice: colorChoice,
                        shapeChoice: shape,
                        xAngle: 0,
                        yAngle: 0,
                        showALabel: false,
                        showILabel: false,
                        showMLabel: false
                    )
                        .frame(width: tokenSize, height: tokenSize)
                        .rotationEffect(.degrees(tokenRotation), anchor: TokenShapeHelper.centroidAnchor(for: shape))
                        .position(x: tokenX, y: tokenY)
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                appearDate = Date()
                viewSize = geo.size
                withAnimation(.easeInOut(duration: 4.0)) {
                    wipeOffset = 1.0
                }
                // Cross expands from center (0.5s after wipe starts)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        crossScale = 1.0
                    }
                }
                // Shapes fade in after cross expansion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    withAnimation(.easeIn(duration: 0.6)) {
                        shapesOpacity = 1.0
                    }
                }
            }
            .onChange(of: geo.size) { newSize in
                viewSize = newSize
            }
        }
    }

    // MARK: - Hold Gesture

    private func holdGesture(for shape: ShapeChoice) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                beginHold(shape)
            }
            .onEnded { _ in
                endHold()
            }
    }

    private func beginHold(_ shape: ShapeChoice) {
        guard heldShape == nil && pickedShape == nil else { return }
        heldShape = shape
        pressStartDate = Date()

        // At 0.75s: show the token (confirm hold)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            guard heldShape == shape else { return }
            showToken(shape)
        }

        // At 1.0s: start cartwheeling in place
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard heldShape == shape else { return }
            cartwheelInPlaceStart = Date()
            startInPlaceCartwheel()
        }

        // At 4.0s (1.0s hold + 3.0s cartwheel): auto-trigger M selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard heldShape == shape else { return }
            autoTriggerM()
        }
    }

    private func shapeScale(for shape: ShapeChoice) -> CGFloat {
        switch shape {
        case .square, .circle: return 0.72
        case .triangleUp, .triangleDown: return 0.88
        }
    }

    private func shapeOffset(for shape: ShapeChoice) -> CGFloat {
        switch shape {
        case .square:       return 40
        case .triangleDown: return 60
        case .triangleUp:   return -60
        case .circle:       return -50
        }
    }

    private func showToken(_ shape: ShapeChoice) {
        pickedShape = shape
        let w = viewSize.width / 2
        let h = viewSize.height / 2
        let origin = quadrantOrigin(for: shape)
        let shapeSize = min(w, h) * shapeScale(for: shape)

        tokenX = origin.x
        tokenY = origin.y + shapeOffset(for: shape)
        tokenSize = shapeSize
        tokenRotation = 0

        // Fade background to white
        withAnimation(.easeIn(duration: 1.0)) {
            fadeWhite = 1.0
        }
    }

    private func startInPlaceCartwheel() {
        // Animate to a large rotation value — 1 rotation per second over 100 seconds
        withAnimation(.linear(duration: 100.0)) {
            tokenRotation = 36000
        }
    }

    private func endHold() {
        guard let shape = heldShape, let pressStart = pressStartDate else { return }
        let holdDuration = Date().timeIntervalSince(pressStart)

        if holdDuration < 0.75 {
            // Not held long enough — cancel
            heldShape = nil
            pressStartDate = nil
            cartwheelInPlaceStart = nil
            return
        }

        let paused = Date().timeIntervalSince(appearDate) >= 3.0

        if holdDuration < 1.0 {
            // Normal selection — no in-place cartwheel happened
            heldShape = nil
            pressStartDate = nil
            cartwheelToDestination(shape: shape, paused: paused, addM: false)
        } else {
            // Was cartwheeling in place — released before auto-trigger
            let cartwheelDuration = Date().timeIntervalSince(cartwheelInPlaceStart ?? Date())

            // Estimate current rotation from elapsed time (1 rotation/sec = 360 deg/sec)
            let estimatedRotation = cartwheelDuration * 360.0

            // Snap to current rotation (cancel ongoing animation)
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                tokenRotation = estimatedRotation
            }

            heldShape = nil
            pressStartDate = nil
            cartwheelInPlaceStart = nil

            // Released before 3s of cartwheeling — normal selection (no M)
            DispatchQueue.main.async {
                cartwheelToDestination(shape: shape, paused: paused, addM: false, startRotation: estimatedRotation)
            }
        }
    }

    private func autoTriggerM() {
        guard let shape = heldShape else { return }
        let paused = Date().timeIntervalSince(appearDate) >= 3.0

        // 3 seconds of in-place cartwheeling = 3 * 360 = 1080 degrees
        let estimatedRotation = 1080.0

        // Snap to current rotation (cancel ongoing animation)
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            tokenRotation = estimatedRotation
        }

        heldShape = nil
        pressStartDate = nil
        cartwheelInPlaceStart = nil

        // Add M and cartwheel to destination
        DispatchQueue.main.async {
            showMLabel = true
            cartwheelToDestination(shape: shape, paused: paused, addM: true, startRotation: estimatedRotation)
        }
    }

    // MARK: - Cartwheel to Destination

    private func cartwheelToDestination(shape: ShapeChoice, paused: Bool, addM: Bool, startRotation: Double = 0) {
        let destX = viewSize.width / 2
        let destY = viewSize.height / 6

        // Token dwells for 0.75s then cartwheels to destination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.easeInOut(duration: 2.5)) {
                tokenX = destX
                tokenY = destY
                tokenSize = 124
                tokenRotation = startRotation + 1080  // 3 full cartwheels
            }
        }

        // Transition to next screen after cartwheel completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            onSelect(shape, paused, addM)
        }
    }

    private func quadrantOrigin(for shape: ShapeChoice) -> CGPoint {
        let w = viewSize.width / 2
        let h = viewSize.height / 2
        switch shape {
        case .square:       return CGPoint(x: w / 2, y: h / 2)
        case .triangleDown: return CGPoint(x: w + w / 2, y: h / 2)
        case .triangleUp:   return CGPoint(x: w / 2, y: h + h / 2)
        case .circle:       return CGPoint(x: w + w / 2, y: h + h / 2)
        }
    }
}

// MARK: - Cross Shape

struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        let cy = h / 2

        // Horizontal line
        path.move(to: CGPoint(x: 0, y: cy))
        path.addLine(to: CGPoint(x: w, y: cy))

        // Vertical line
        path.move(to: CGPoint(x: cx, y: 0))
        path.addLine(to: CGPoint(x: cx, y: h))

        return path
    }
}

struct ShapeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ShapeSelectionView(shade: .white, colorChoice: .blue, showILabel: false) { shape, paused, showM in
            print("Selected: \(shape), paused: \(paused), showM: \(showM)")
        }
    }
}
