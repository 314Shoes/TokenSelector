import SwiftUI

enum AppScreen {
    case intro
    case shadeSelection
    case colorSelection
    case shapeSelection
    case token
    case useToken
    case calendar
    case colorChannel
    case treasureChestAnimation
    case treasureChest
}

enum ShadeChoice: String, Codable {
    case black, white
}

enum ColorChoice: String, CaseIterable, Codable {
    case blue, green, red
}

enum ShapeChoice: String, CaseIterable, Codable {
    case square, circle, triangleUp, triangleDown
    
    var displayName: String {
        switch self {
        case .square: return "Square"
        case .circle: return "Circle"
        case .triangleUp: return "Triangle Up"
        case .triangleDown: return "Triangle Down"
        }
    }
}

enum ShadeAnimationDirection {
    case whiteToBlack  // Start white, fade in black from left
    case blackToWhite  // Start black, fade in white from right
}

struct ContentView: View {
    @State private var currentScreen: AppScreen = .intro
    @State private var selectedShade: ShadeChoice = .white
    @State private var selectedColor: ColorChoice = .blue
    @State private var selectedShape: ShapeChoice = .square
    @State private var tokenID: String = ""
    @State private var introAnimationDirection: ShadeAnimationDirection = .whiteToBlack
    @State private var showALabel: Bool = false
    @State private var shadePaused: Bool = false
    @State private var colorPaused: Bool = false
    @State private var shapePaused: Bool = false
    @State private var showMLabel: Bool = false

    private var showILabel: Bool {
        shadePaused && colorPaused && shapePaused
    }
    
    var body: some View {
        ZStack {
            // White background to prevent system flash during transitions
            Color.white
                .ignoresSafeArea()
            
            switch currentScreen {
            case .intro:
                IntroScreenView { direction, waited6Pulses in
                    introAnimationDirection = direction
                    if waited6Pulses { showALabel = true }
                    currentScreen = .shadeSelection
                }
                
            case .shadeSelection:
                ShadeSelectionView(
                    onSelect: { shade, paused in
                        selectedShade = shade
                        shadePaused = paused
                        currentScreen = .colorSelection
                    },
                    direction: introAnimationDirection
                )
                
            case .colorSelection:
                ColorSelectionView(shade: selectedShade, direction: introAnimationDirection) { color, paused in
                    selectedColor = color
                    colorPaused = paused
                    currentScreen = .shapeSelection
                }
                
            case .shapeSelection:
                ShapeSelectionView(
                    shade: selectedShade,
                    colorChoice: selectedColor,
                    showILabel: showILabel
                ) { shape, paused, showM in
                    selectedShape = shape
                    shapePaused = paused
                    if showM { showMLabel = true }
                    tokenID = generateTokenID()
                    // Save token to history as soon as it's created
                    TokenStorage.deposit(DepositedToken(
                        id: tokenID,
                        shade: selectedShade,
                        color: selectedColor,
                        shape: shape,
                        depositedAt: Date(),
                        showALabel: showALabel,
                        showILabel: showILabel,
                        showMLabel: showMLabel
                    ))
                    currentScreen = .token
                }
                
            case .token:
                TokenView(
                    shade: selectedShade,
                    colorChoice: selectedColor,
                    shapeChoice: selectedShape,
                    tokenID: tokenID,
                    showALabel: showALabel,
                    showILabel: showILabel,
                    showMLabel: showMLabel,
                    onRestart: {
                        showALabel = false
                        shadePaused = false
                        colorPaused = false
                        shapePaused = false
                        showMLabel = false
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .intro
                        }
                    },
                    onUseToken: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .useToken
                        }
                    }
                )
                .transition(.opacity)

            case .useToken:
                UseTokenView(
                    shade: selectedShade,
                    colorChoice: selectedColor,
                    shapeChoice: selectedShape,
                    tokenID: tokenID,
                    showALabel: showALabel,
                    showILabel: showILabel,
                    showMLabel: showMLabel,
                    onDeposit: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .treasureChestAnimation
                        }
                    },
                    onCalendar: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .calendar
                        }
                    }
                )
                .transition(.opacity)
                
            case .calendar:
                CalendarView(
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .useToken
                        }
                    },
                    onTreasureChest: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .treasureChestAnimation
                        }
                    },
                    onColorChannel: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .colorChannel
                        }
                    }
                )
                .transition(.opacity)
                
            case .colorChannel:
                ColorChannelView(
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .calendar
                        }
                    }
                )
                .transition(.opacity)
                
            case .treasureChestAnimation:
                TreasureChestView(
                    shade: selectedShade,
                    colorChoice: selectedColor,
                    shapeChoice: selectedShape,
                    tokenID: tokenID,
                    showALabel: showALabel,
                    showILabel: showILabel,
                    showMLabel: showMLabel,
                    onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .treasureChest
                        }
                    }
                )
                .transition(.opacity)
                
            case .treasureChest:
                TreasureChestScreen(
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .useToken
                        }
                    },
                    onRestart: {
                        showALabel = false
                        shadePaused = false
                        colorPaused = false
                        shapePaused = false
                        showMLabel = false
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentScreen = .intro
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateTokenID() -> String {
        let chars = "ABCDEF0123456789"
        let id = String((0..<8).map { _ in chars.randomElement()! })
        return "TOKEN-\(id)"
    }
}

// MARK: - Intro Screen View

struct IntroScreenView: View {
    let onComplete: (ShadeAnimationDirection, Bool) -> Void  // (direction, waited6Pulses)

    @State private var showStars = false
    @State private var showCenterStar = false
    @State private var centerStarScale: CGFloat = 0.001
    @State private var starOpacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var screenTapped = false
    @State private var pulseStartDate: Date? = nil
    // Three consolidation waves — stars move at different times
    @State private var wave1 = false
    @State private var wave2 = false
    @State private var wave3 = false
    @State private var wavesStarted = false
    // Black circle wipe for non-star taps
    @State private var showBlackCircleWipe = false
    @State private var blackCircleRadius: CGFloat = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.6
    
    // Star data: (x, y, size, brightness, wave)
    // Coordinates in 0-400 x 0-800 virtual space, scaled to device.
    // Truly random positions with clusters, gaps, and many tiny faint stars.
    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, brightness: Double, wave: Int)] = [
        // ── Extra small dim stars (added at beginning) ──
        (45, 12, 0.6, 0.85, 1), (98, 28, 0.8, 0.9, 2), (156, 8, 0.5, 0.88, 3),
        (203, 35, 0.7, 0.92, 1), (267, 19, 0.6, 0.88, 2), (334, 42, 0.8, 1.0, 3),
        (12, 67, 0.5, 0.85, 1), (67, 89, 0.7, 0.92, 2), (123, 112, 0.6, 0.88, 3),
        (178, 78, 0.8, 0.95, 1), (234, 95, 0.5, 0.88, 2), (289, 67, 0.7, 0.92, 3),
        (345, 103, 0.6, 0.88, 1), (389, 128, 0.8, 0.92, 2), (28, 147, 0.5, 0.85, 3),
        (84, 172, 0.7, 0.92, 1), (139, 198, 0.6, 0.88, 2), (195, 156, 0.8, 1.0, 3),
        (251, 183, 0.5, 0.88, 1), (306, 211, 0.7, 0.92, 2), (362, 167, 0.6, 0.88, 3),
        (18, 228, 0.8, 0.95, 1), (73, 256, 0.5, 0.85, 2), (129, 289, 0.7, 0.92, 3),
        (184, 267, 0.6, 0.88, 1), (240, 312, 0.8, 0.95, 2), (296, 278, 0.5, 0.88, 3),
        (351, 334, 0.7, 0.92, 1), (8, 356, 0.6, 0.88, 2), (63, 389, 0.8, 1.0, 3),
        (118, 423, 0.5, 0.85, 1), (174, 456, 0.7, 0.92, 2), (229, 489, 0.6, 0.88, 3),
        (285, 512, 0.8, 0.95, 1), (340, 478, 0.5, 0.88, 2), (395, 534, 0.7, 0.92, 3),
        (22, 567, 0.6, 0.88, 1), (77, 601, 0.8, 0.95, 2), (133, 634, 0.5, 0.85, 3),
        (188, 678, 0.7, 0.92, 1), (244, 712, 0.6, 0.88, 2), (299, 689, 0.8, 1.0, 3),
        (355, 756, 0.5, 0.88, 1), (6, 789, 0.7, 0.92, 2), (61, 723, 0.6, 0.88, 3),
        (117, 767, 0.8, 0.95, 1), (172, 734, 0.5, 0.85, 2), (228, 801, 0.7, 0.92, 3),
        // ── More extra tiny stars ──
        (51, 19, 0.4, 0.7, 1), (134, 33, 0.5, 0.75, 2), (217, 15, 0.4, 0.7, 3),
        (312, 27, 0.5, 0.75, 1), (376, 51, 0.4, 0.7, 2), (39, 78, 0.5, 0.75, 3),
        (112, 93, 0.4, 0.7, 1), (198, 119, 0.5, 0.75, 2), (287, 84, 0.4, 0.7, 3),
        (358, 137, 0.5, 0.75, 1), (73, 163, 0.4, 0.7, 2), (156, 189, 0.5, 0.75, 3),
        (241, 172, 0.4, 0.7, 1), (329, 208, 0.5, 0.75, 2), (382, 234, 0.4, 0.7, 3),
        (48, 267, 0.5, 0.75, 1), (129, 293, 0.4, 0.7, 2), (213, 318, 0.5, 0.75, 3),
        (298, 287, 0.4, 0.7, 1), (371, 342, 0.5, 0.75, 2), (84, 378, 0.4, 0.7, 3),
        (167, 413, 0.5, 0.75, 1), (252, 439, 0.4, 0.7, 2), (346, 464, 0.5, 0.75, 3),
        (389, 498, 0.4, 0.7, 1), (61, 534, 0.5, 0.75, 2), (148, 559, 0.4, 0.7, 3),
        (234, 584, 0.5, 0.75, 1), (319, 609, 0.4, 0.7, 2), (376, 635, 0.5, 0.75, 3),
        (92, 671, 0.4, 0.7, 1), (178, 696, 0.5, 0.75, 2), (267, 722, 0.4, 0.7, 3),
        (351, 747, 0.5, 0.75, 1), (27, 773, 0.4, 0.7, 2), (119, 798, 0.5, 0.75, 3),
        // ── Bright feature stars (random positions) ──
        (23, 41, 5, 1.0, 1), (371, 19, 4.5, 1.0, 2), (189, 97, 6, 1.0, 3),
        (94, 203, 5.5, 1.0, 1), (337, 167, 4, 1.0, 2), (261, 311, 5, 1.0, 3),
        (47, 489, 4.5, 1.0, 1), (386, 422, 5, 1.0, 2), (152, 577, 6, 1.0, 3),
        (309, 631, 4.5, 1.0, 1), (78, 712, 5, 1.0, 2), (228, 753, 4, 1.0, 3),
        (391, 285, 5.5, 1.0, 1), (16, 358, 4.5, 1.0, 2), (274, 82, 5, 1.0, 3),
        // ── Medium stars (scattered randomly) ──
        (132, 14, 2.5, 0.8, 1), (389, 73, 2, 0.7, 2), (57, 131, 2.5, 0.9, 3),
        (298, 52, 2, 0.8, 1), (174, 189, 2.5, 0.7, 2), (367, 231, 2, 0.9, 3),
        (11, 267, 2.5, 0.8, 1), (224, 198, 2, 0.7, 2), (143, 347, 2.5, 0.8, 3),
        (352, 373, 2, 0.9, 1), (82, 428, 2.5, 0.7, 2), (263, 456, 2, 0.8, 3),
        (197, 518, 2.5, 0.9, 1), (39, 563, 2, 0.7, 2), (321, 541, 2.5, 0.8, 3),
        (115, 649, 2, 0.9, 1), (278, 687, 2.5, 0.7, 2), (383, 598, 2, 0.8, 3),
        (61, 773, 2.5, 0.8, 1), (346, 732, 2, 0.9, 2), (168, 691, 2.5, 0.7, 3),
        // ── Small dim stars (bulk of the field) ──
        (7, 3, 1, 0.3, 1), (53, 22, 0.8, 0.25, 2), (119, 47, 1, 0.35, 3),
        (241, 11, 0.7, 0.2, 1), (328, 38, 1, 0.3, 2), (394, 8, 0.8, 0.25, 3),
        (36, 68, 0.7, 0.3, 1), (156, 59, 1, 0.2, 2), (213, 44, 0.8, 0.35, 3),
        (287, 78, 0.7, 0.25, 1), (361, 92, 1, 0.3, 2), (78, 108, 0.8, 0.2, 3),
        (199, 123, 0.7, 0.35, 1), (146, 156, 1, 0.25, 2), (312, 139, 0.8, 0.3, 3),
        (24, 181, 0.7, 0.2, 1), (256, 172, 1, 0.3, 2), (389, 197, 0.8, 0.25, 3),
        (68, 218, 0.7, 0.35, 1), (318, 208, 1, 0.2, 2), (141, 244, 0.8, 0.3, 3),
        (237, 229, 0.7, 0.25, 1), (381, 262, 1, 0.3, 2), (48, 283, 0.8, 0.2, 3),
        (174, 271, 0.7, 0.35, 1), (296, 293, 1, 0.25, 2), (109, 308, 0.8, 0.3, 3),
        (362, 318, 0.7, 0.2, 1), (19, 337, 1, 0.3, 2), (223, 349, 0.8, 0.25, 3),
        (87, 369, 0.7, 0.35, 1), (308, 359, 1, 0.2, 2), (182, 392, 0.8, 0.3, 3),
        (396, 403, 0.7, 0.25, 1), (52, 412, 1, 0.3, 2), (266, 431, 0.8, 0.2, 3),
        (128, 448, 0.7, 0.35, 1), (347, 442, 1, 0.25, 2), (14, 472, 0.8, 0.3, 3),
        (211, 467, 0.7, 0.2, 1), (374, 488, 1, 0.3, 2), (91, 503, 0.8, 0.25, 3),
        (283, 497, 0.7, 0.35, 1), (159, 527, 1, 0.2, 2), (38, 538, 0.8, 0.3, 3),
        (332, 522, 0.7, 0.25, 1), (246, 553, 1, 0.3, 2), (102, 561, 0.8, 0.2, 3),
        (387, 547, 0.7, 0.35, 1), (67, 582, 1, 0.25, 2), (196, 593, 0.8, 0.3, 3),
        (298, 571, 0.7, 0.2, 1), (141, 612, 1, 0.3, 2), (359, 617, 0.8, 0.25, 3),
        (28, 632, 0.7, 0.35, 1), (233, 641, 1, 0.2, 2), (314, 659, 0.8, 0.3, 3),
        (73, 668, 0.7, 0.25, 1), (181, 678, 1, 0.3, 2), (392, 671, 0.8, 0.2, 3),
        (43, 702, 0.7, 0.35, 1), (253, 718, 1, 0.25, 2), (138, 729, 0.8, 0.3, 3),
        (367, 741, 0.7, 0.2, 1), (87, 757, 1, 0.3, 2), (209, 768, 0.8, 0.25, 3),
        (322, 779, 0.7, 0.35, 1), (15, 791, 1, 0.2, 2), (176, 783, 0.8, 0.3, 3),
        // ── Even tinier dust stars ──
        (117, 7, 0.5, 0.15, 1), (269, 29, 0.5, 0.18, 2), (348, 56, 0.5, 0.15, 3),
        (42, 88, 0.5, 0.18, 1), (198, 107, 0.5, 0.15, 2), (381, 143, 0.5, 0.18, 3),
        (73, 162, 0.5, 0.15, 1), (291, 191, 0.5, 0.18, 2), (163, 223, 0.5, 0.15, 3),
        (24, 259, 0.5, 0.18, 1), (356, 278, 0.5, 0.15, 2), (112, 301, 0.5, 0.18, 3),
        (243, 332, 0.5, 0.15, 1), (388, 351, 0.5, 0.18, 2), (57, 383, 0.5, 0.15, 3),
        (187, 407, 0.5, 0.18, 1), (329, 429, 0.5, 0.15, 2), (98, 462, 0.5, 0.18, 3),
        (271, 483, 0.5, 0.15, 1), (12, 512, 0.5, 0.18, 2), (201, 541, 0.5, 0.15, 3),
        (362, 568, 0.5, 0.18, 1), (79, 592, 0.5, 0.15, 2), (148, 621, 0.5, 0.18, 3),
        (307, 647, 0.5, 0.15, 1), (38, 673, 0.5, 0.18, 2), (222, 701, 0.5, 0.15, 3),
        (391, 723, 0.5, 0.18, 1), (128, 751, 0.5, 0.15, 2), (283, 772, 0.5, 0.18, 3),
        // ── Cluster near top-left (natural grouping) ──
        (31, 47, 1.5, 0.5, 1), (38, 52, 0.8, 0.3, 1), (26, 58, 1, 0.4, 2),
        (44, 43, 0.7, 0.25, 2), (35, 63, 1.2, 0.45, 3),
        // ── Cluster near center-right ──
        (341, 383, 1.5, 0.5, 2), (348, 389, 0.8, 0.3, 3), (335, 377, 1, 0.4, 1),
        (353, 392, 0.7, 0.25, 1), (339, 396, 1.2, 0.45, 2),
        // ── Cluster near bottom ──
        (187, 721, 1.5, 0.5, 3), (193, 727, 0.8, 0.3, 1), (181, 715, 1, 0.4, 2),
        (199, 731, 0.7, 0.25, 2), (185, 735, 1.2, 0.45, 3),
        // ── Edge stars from OUTSIDE the screen — streak inward ──
        (-60, 127, 3, 1.0, 1), (-45, 389, 2.5, 1.0, 2), (-80, 561, 3.5, 1.0, 3),
        (-35, 714, 2.5, 1.0, 1), (-70, 43, 3, 1.0, 2),
        (458, 89, 3, 1.0, 2), (443, 341, 3.5, 1.0, 3), (472, 523, 2.5, 1.0, 1),
        (451, 697, 3, 1.0, 2), (467, 411, 2.5, 1.0, 3),
        (87, -55, 2.5, 1.0, 1), (263, -42, 3.5, 1.0, 2), (358, -67, 3, 1.0, 3),
        (41, -73, 2.5, 1.0, 1), (179, -48, 3, 1.0, 3),
        (73, 863, 3, 1.0, 2), (214, 857, 3.5, 1.0, 3), (331, 871, 2.5, 1.0, 1),
        (382, 859, 3, 1.0, 2), (147, 867, 2.5, 1.0, 3),
    ]
    
    private func isWaveActive(_ wave: Int) -> Bool {
        switch wave {
        case 1: return wave1
        case 2: return wave2
        case 3: return wave3
        default: return false
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            let scaleX = geo.size.width / 400
            let scaleY = geo.size.height / 800
            
            ZStack {
                // Black background with perimeter glow effect
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.02),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.12)
                            ],
                            center: .center,
                            startRadius: 200,
                            endRadius: 450
                        )
                        .blendMode(.screen)
                        .ignoresSafeArea()
                    )
                
                if showStars {
                    ZStack {
                        ForEach(0..<stars.count, id: \.self) { i in
                            let s = stars[i]
                            let posX = s.x * scaleX
                            let posY = s.y * scaleY
                            let active = isWaveActive(s.wave)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: s.size, height: s.size)
                                .shadow(color: s.brightness >= 0.9 ? .white.opacity(0.8) : .clear, radius: s.brightness >= 0.9 ? 6 : 0)
                                .position(x: active ? cx : posX,
                                          y: active ? cy : posY)
                                .opacity(starOpacity * s.brightness)
                        }
                    }
                }
                
                // Black circle wipe overlay (for non-star taps)
                // Black covers the whole screen; a clear circular hole shrinks to reveal blackness closing in
                if showBlackCircleWipe {
                    ZStack {
                        Color.black
                            .ignoresSafeArea()
                        Circle()
                            .fill(Color.white)
                            .frame(width: blackCircleRadius * 2, height: blackCircleRadius * 2)
                            .position(x: cx, y: cy)
                            .blur(radius: 30)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    .ignoresSafeArea()
                }
                
                if showCenterStar {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .scaleEffect(centerStarScale)
                        .scaleEffect(pulseScale)
                        .shadow(color: .white, radius: screenTapped ? 80 : 15)
                        .shadow(color: .white.opacity(screenTapped ? 1.0 : 0.5), radius: screenTapped ? 120 : 30)
                        .overlay(
                            // Invisible tap target for the star
                            Circle()
                                .fill(Color.clear)
                                .contentShape(Circle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in handleTap(onStar: true) }
                                )
                        )
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in handleTap(onStar: false) }
        )
        .onAppear {
            startIntroSequence()
        }
    }
    
    private func handleTap(onStar: Bool) {
        guard !screenTapped else { return }
        screenTapped = true

        let direction: ShadeAnimationDirection = onStar ? .whiteToBlack : .blackToWhite

        // Check if 6 full pulse cycles completed (6 * 4.4s = 26.4s after pulse start)
        let waited6Pulses: Bool
        if let pulseStart = pulseStartDate {
            waited6Pulses = Date().timeIntervalSince(pulseStart) >= 26.4
        } else {
            waited6Pulses = false
        }

        if onStar {
            withAnimation(.easeOut(duration: 4.0)) {
                centerStarScale = 30
                starOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
                self.onComplete(direction, waited6Pulses)
            }
        } else {
            showBlackCircleWipe = true
            withAnimation(.easeInOut(duration: 4.0)) {
                blackCircleRadius = 0
                centerStarScale = 0.001
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
                self.onComplete(direction, waited6Pulses)
            }
        }
    }
    
    private func startPulseCycle() {
        guard !screenTapped else { return }
        // Pause pulsing while the center star is growing during waves
        if wavesStarted { return }
        // Expand to large
        withAnimation(.easeInOut(duration: 2.2)) {
            pulseScale = 1.8
        }
        // Immediately shrink (no pause)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            guard !self.screenTapped else { return }
            if self.wavesStarted { return }
            withAnimation(.easeInOut(duration: 2.2)) {
                self.pulseScale = 1.0
            }
            // Immediately expand again (no pause)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                self.startPulseCycle()
            }
        }
    }
    
    private func startIntroSequence() {
        // Show stars after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 8.0)) {
                showStars = true
                starOpacity = 1.0
            }
        }
        
        // Start pulse cycle sooner (will affect center star once it appears)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.pulseStartDate = Date()
            self.startPulseCycle()
        }
        
        // Show center star BEFORE waves start (small seed) - grows faster
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            showCenterStar = true
            centerStarScale = 0.15
            withAnimation(.easeOut(duration: 1.0)) {
                centerStarScale = 0.2
            }
        }
        
        // Wave 1 — first batch of stars consolidate inward, center grows faster
        // Pause the pulse so the growing star doesn't visually shrink
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
            wavesStarted = true
            withAnimation(.easeInOut(duration: 1.0)) {
                pulseScale = 1.0
            }
            withAnimation(.linear(duration: 5.0)) {
                wave1 = true
            }
            withAnimation(.easeOut(duration: 3.0)) {
                centerStarScale = 0.35
            }
        }
        
        // Wave 2 — second batch consolidates, center grows faster
        DispatchQueue.main.asyncAfter(deadline: .now() + 11.0) {
            withAnimation(.linear(duration: 6.0)) {
                wave2 = true
            }
            withAnimation(.easeOut(duration: 3.0)) {
                centerStarScale = 0.55
            }
        }
        
        // Wave 3 — outermost + edge stars consolidate last, center reaches full size faster
        DispatchQueue.main.asyncAfter(deadline: .now() + 13.5) {
            withAnimation(.linear(duration: 7.0)) {
                wave3 = true
            }
            withAnimation(.easeOut(duration: 4.0)) {
                centerStarScale = 1.0
            }
            // Resume pulsing after center star finishes growing
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.wavesStarted = false
                self.startPulseCycle()
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
