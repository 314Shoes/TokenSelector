import SwiftUI

struct ColorSelectionView: View {
    let shade: ShadeChoice
    let direction: ShadeAnimationDirection
    let onSelect: (ColorChoice, Bool) -> Void

    @State private var wipeOffset: CGFloat = 0
    @State private var hasAppeared = false
    @State private var selectedColor: ColorChoice? = nil
    @State private var wipeScale: CGFloat = 0.0
    @State private var appearDate: Date = Date()
    
    private var shadeColor: Color {
        shade == .black ? Color.black : Color.white
    }
        
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Split black/white background matching ShadeSelectionView
                ZStack {
                    // Base background - white for whiteToBlack, black for blackToWhite
                    (direction == .whiteToBlack ? Color.white : Color.black)
                        .ignoresSafeArea()
                    
                    // For whiteToBlack: black rectangle on left side
                    if direction == .whiteToBlack {
                        Color.black
                            .ignoresSafeArea()
                            .frame(width: geo.size.width / 2, height: geo.size.height)
                            .position(x: geo.size.width * 0.25, y: geo.size.height / 2)
                    }
                    
                    // For blackToWhite: white rectangle on right side
                    if direction == .blackToWhite {
                        Color.white
                            .ignoresSafeArea()
                            .frame(width: geo.size.width / 2, height: geo.size.height)
                            .position(x: geo.size.width * 0.75, y: geo.size.height / 2)
                    }
                }
                .zIndex(0)
                
                // Color rows - swipe above shade
                VStack(spacing: 0) {
                    // Blue row
                    resolvedColor(for: .blue)
                        .frame(height: geo.size.height / 3)
                        .contentShape(Rectangle())
                        .onTapGesture { selectColor(.blue) }
                    
                    // Green row
                    resolvedColor(for: .green)
                        .frame(height: geo.size.height / 3)
                        .contentShape(Rectangle())
                        .onTapGesture { selectColor(.green) }
                    
                    // Red row
                    resolvedColor(for: .red)
                        .frame(height: geo.size.height / 3)
                        .contentShape(Rectangle())
                        .onTapGesture { selectColor(.red) }
                }
                .offset(x: wipeOffset)
                
                // Wipe overlay: selected color spreads to fill entire screen
                if let picked = selectedColor {
                    directionalWipeOverlay(color: picked, geo: geo)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                appearDate = Date()
                // Dark variants: wipe in from left, Light variants: wipe in from right
                wipeOffset = shade == .black ? -geo.size.width : geo.size.width
                withAnimation(.easeOut(duration: 2.0)) {
                    wipeOffset = 0
                }
            }
        }
    }
    
    @ViewBuilder
    private func directionalWipeOverlay(color: ColorChoice, geo: GeometryProxy) -> some View {
        let colorValue = resolvedColor(for: color)
        
        switch color {
        case .blue:
            // Blue: border line goes straight down from top
            VStack(spacing: 0) {
                colorValue
                    .frame(height: geo.size.height * wipeScale)
                Spacer()
            }
            
        case .green:
            // Green: top border wipes UP from center, bottom border wipes DOWN from center
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geo.size.height * 0.5 * (1 - wipeScale))
                colorValue
                    .frame(height: geo.size.height * 0.5 * wipeScale)
                colorValue
                    .frame(height: geo.size.height * 0.5 * wipeScale)
                Spacer()
                    .frame(height: geo.size.height * 0.5 * (1 - wipeScale))
            }
            
        case .red:
            // Red: border line goes straight up from bottom
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geo.size.height * (1 - wipeScale))
                colorValue
                    .frame(height: geo.size.height * wipeScale)
            }
        }
    }
    
    private func selectColor(_ color: ColorChoice) {
        guard selectedColor == nil else { return }
        let paused = Date().timeIntervalSince(appearDate) >= 3.0
        selectedColor = color

        // Wipe starts immediately, same pace as shade selection wipe (3.5s linear)
        withAnimation(.linear(duration: 3.5)) {
            wipeScale = 1.0
        }

        // Transition after wipe completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            onSelect(color, paused)
        }
    }
    
    private func resolvedColor(for color: ColorChoice) -> Color {
        ColorHelper.resolve(color: color, shade: shade)
    }
}

struct ColorSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSelectionView(shade: .black, direction: .whiteToBlack) { color, paused in
            print("Selected: \(color), paused: \(paused)")
        }
    }
}
