import SwiftUI

/// Compact token badge used in CalendarView, TreasureChestScreen, and ColorChannelView.
/// Shows the shape, color, and AIM labels at the given size.
struct TokenBadgeView: View {
    let token: DepositedToken
    let size: CGFloat
    let labelSize: CGFloat

    init(token: DepositedToken, size: CGFloat, labelSize: CGFloat = 7) {
        self.token = token
        self.size = size
        self.labelSize = labelSize
    }

    private var hasFullAIM: Bool {
        token.showALabel && token.showILabel && token.showMLabel
    }

    var body: some View {
        ZStack {
            TokenShapeHelper.shapeView(
                shape: token.shape,
                color: ColorHelper.resolve(color: token.color, shade: token.shade)
            )

            if hasFullAIM {
                TokenShapeHelper.strokeView(
                    shape: token.shape,
                    lineWidth: size > 30 ? 1.5 : 1,
                    color: CoinTokenView.goldDark
                )
                .scaleEffect(0.93)
            }

            VStack(spacing: size > 30 ? 1 : 0) {
                if token.showALabel {
                    Text("A")
                        .font(.system(size: labelSize, weight: .bold, design: .rounded))
                        .foregroundColor(CoinTokenView.goldLabel)
                }
                if token.showILabel {
                    Text("I")
                        .font(.system(size: labelSize, weight: .bold, design: .rounded))
                        .foregroundColor(CoinTokenView.goldLabel)
                }
                if token.showMLabel {
                    Text("M")
                        .font(.system(size: labelSize, weight: .bold, design: .rounded))
                        .foregroundColor(CoinTokenView.goldLabel)
                }
            }
            .offset(y: (TokenShapeHelper.centroidAnchor(for: token.shape).y - 0.5) * size)
        }
        .frame(width: size, height: size)
    }
}
