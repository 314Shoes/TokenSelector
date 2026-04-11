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
                                ZStack {
                                    tokenShapeView(
                                        shape: token.shape,
                                        color: ColorHelper.resolve(color: token.color, shade: token.shade)
                                    )
                                    if token.showALabel && token.showILabel && token.showMLabel {
                                        TokenShapeHelper.strokeView(shape: token.shape, lineWidth: 1.5, color: CoinTokenView.goldDark)
                                            .scaleEffect(0.93)
                                    }
                                    VStack(spacing: 1) {
                                        if token.showALabel {
                                            Text("A")
                                                .font(.system(size: 7, weight: .bold, design: .rounded))
                                                .foregroundColor(CoinTokenView.goldLabel)
                                        }
                                        if token.showILabel {
                                            Text("I")
                                                .font(.system(size: 7, weight: .bold, design: .rounded))
                                                .foregroundColor(CoinTokenView.goldLabel)
                                        }
                                        if token.showMLabel {
                                            Text("M")
                                                .font(.system(size: 7, weight: .bold, design: .rounded))
                                                .foregroundColor(CoinTokenView.goldLabel)
                                        }
                                    }
                                    .offset(y: labelCentroidOffset(for: token.shape, frameSize: 50))
                                }
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
    
    private func labelCentroidOffset(for shape: ShapeChoice, frameSize: CGFloat) -> CGFloat {
        let anchorY = TokenShapeHelper.centroidAnchor(for: shape).y
        return (anchorY - 0.5) * frameSize
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
    var showALabel: Bool
    var showILabel: Bool
    var showMLabel: Bool

    private enum CodingKeys: String, CodingKey {
        case id, shade, color, shape, depositedAt, showALabel, showILabel, showMLabel
    }

    init(id: String, shade: ShadeChoice, color: ColorChoice, shape: ShapeChoice, depositedAt: Date, showALabel: Bool = false, showILabel: Bool = false, showMLabel: Bool = false) {
        self.id = id
        self.shade = shade
        self.color = color
        self.shape = shape
        self.depositedAt = depositedAt
        self.showALabel = showALabel
        self.showILabel = showILabel
        self.showMLabel = showMLabel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        shade = try container.decode(ShadeChoice.self, forKey: .shade)
        color = try container.decode(ColorChoice.self, forKey: .color)
        shape = try container.decode(ShapeChoice.self, forKey: .shape)
        depositedAt = try container.decode(Date.self, forKey: .depositedAt)
        showALabel = try container.decodeIfPresent(Bool.self, forKey: .showALabel) ?? true
        showILabel = try container.decodeIfPresent(Bool.self, forKey: .showILabel) ?? false
        showMLabel = try container.decodeIfPresent(Bool.self, forKey: .showMLabel) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(shade, forKey: .shade)
        try container.encode(color, forKey: .color)
        try container.encode(shape, forKey: .shape)
        try container.encode(depositedAt, forKey: .depositedAt)
        try container.encode(showALabel, forKey: .showALabel)
        try container.encode(showILabel, forKey: .showILabel)
        try container.encode(showMLabel, forKey: .showMLabel)
    }
}

struct TreasureChestScreen_Previews: PreviewProvider {
    static var previews: some View {
        TreasureChestScreen(onBack: {}, onRestart: {})
    }
}
