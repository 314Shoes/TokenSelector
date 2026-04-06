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
                
                // Token count
                Text("\(depositedTokens.count) Tokens")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                // Deposited tokens grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 20) {
                        ForEach(depositedTokens, id: \.id) { token in
                            VStack(spacing: 6) {
                                // Token shape
                                tokenShapeView(
                                    shape: token.shape,
                                    color: ColorHelper.resolve(color: token.color, shade: token.shade)
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                                
                                // Token ID
                                Text(String(token.id.suffix(4)))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                // Date/Time stamp
                                Text(formatDate(token.depositedAt))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 350)
                
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
        depositedTokens = TokenStorage.load().sorted { $0.depositedAt > $1.depositedAt }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
