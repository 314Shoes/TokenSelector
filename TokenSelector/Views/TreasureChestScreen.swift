import SwiftUI

struct TreasureChestScreen: View {
    let onBack: () -> Void
    let onRestart: () -> Void
    
    @State private var depositedTokens: [DepositedToken] = []
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.02),
                    Color(red: 0.2, green: 0.1, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Treasure Chest")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Chest illustration
                ZStack {
                    // Chest body
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.65, green: 0.45, blue: 0.25),
                                    Color(red: 0.45, green: 0.3, blue: 0.18)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 80)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                    
                    // Chest lid
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.2),
                                    Color(red: 0.4, green: 0.25, blue: 0.15)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 25)
                        .offset(y: -40)
                    
                    // Gold coins spilling out
                    VStack(spacing: -5) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.yellow,
                                            Color.orange
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 15 - CGFloat(index * 2), height: 15 - CGFloat(index * 2))
                                .offset(x: CGFloat(index * 8 - 8), y: CGFloat(index * 3))
                        }
                    }
                    .offset(y: -20)
                }
                .padding(.vertical, 10)
                
                // Token count
                Text("\(depositedTokens.count) Tokens")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                // Deposited tokens grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(depositedTokens, id: \.id) { token in
                            VStack(spacing: 4) {
                                // Token shape
                                tokenShapeView(
                                    shape: token.shape,
                                    color: ColorHelper.resolve(color: token.color, shade: token.shade)
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                                
                                // Token ID
                                Text(String(token.id.suffix(4)))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 300)
                
                Spacer()
                
                HStack(spacing: 20) {
                    // Back button
                    Button("Back") {
                        onBack()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(25)
                    
                    // Start Over button
                    Button("Start Over") {
                        onRestart()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.4, green: 0.2, blue: 0.1).opacity(0.8))
                    .cornerRadius(25)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            loadDepositedTokens()
        }
    }
    
    private func tokenShapeView(shape: ShapeChoice, color: Color) -> some View {
        TokenShapeHelper.shapeView(shape: shape, color: color)
    }
    
    private func loadDepositedTokens() {
        depositedTokens = TokenStorage.load()
    }
}

struct DepositedToken: Identifiable, Codable {
    let id: String
    let shade: ShadeChoice
    let color: ColorChoice
    let shape: ShapeChoice
    let depositedAt: Date
}

struct TreasureChestScreen_Previews: PreviewProvider {
    static var previews: some View {
        TreasureChestScreen(onBack: {}, onRestart: {})
    }
}
