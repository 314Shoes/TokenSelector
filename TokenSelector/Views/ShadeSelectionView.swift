import SwiftUI

struct ShadeSelectionView: View {
    let onSelect: (ShadeChoice, Bool) -> Void
    let direction: ShadeAnimationDirection

    @State private var whiteOpacity: Double = 0.0
    @State private var selectedShade: ShadeChoice? = nil
    @State private var appearDate: Date = Date()

    init(onSelect: @escaping (ShadeChoice, Bool) -> Void, direction: ShadeAnimationDirection = .whiteToBlack) {
        self.onSelect = onSelect
        self.direction = direction
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base background - white for whiteToBlack, black for blackToWhite
                (direction == .whiteToBlack ? Color.white : Color.black)
                    .ignoresSafeArea()
                
                // For whiteToBlack: black rectangle on left side fades in
                if direction == .whiteToBlack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: geo.size.width / 2 + 2, height: geo.size.height + 200)
                        .position(x: geo.size.width * 0.25, y: geo.size.height / 2)
                        .opacity(whiteOpacity)
                }
                
                // White rectangle on right side fades in after dwell
                if direction == .blackToWhite {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geo.size.width / 2 + 2, height: geo.size.height + 200)
                        .position(x: geo.size.width * 0.75, y: geo.size.height / 2)
                        .opacity(whiteOpacity)
                }
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    guard selectedShade == nil else { return }
                    let paused = Date().timeIntervalSince(appearDate) >= 3.0
                    let location = value.location
                    let screenWidth = UIScreen.main.bounds.width
                    if location.x < screenWidth / 2 {
                        selectedShade = .black
                        onSelect(.black, paused)
                    } else {
                        selectedShade = .white
                        onSelect(.white, paused)
                    }
                }
        )
        .onAppear {
            appearDate = Date()
            // 0.3s dwell, then fade in the rectangle over 0.8s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.linear(duration: 0.8)) {
                    whiteOpacity = 1.0
                }
            }
        }
    }
}

struct ShadeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ShadeSelectionView(onSelect: { shade, paused in
            print("Selected: \(shade), paused: \(paused)")
        }, direction: .whiteToBlack)
    }
}
