import SwiftUI

struct CalendarView: View {
    let onBack: () -> Void
    let onTreasureChest: () -> Void
    let onColorChannel: () -> Void
    
    @State private var depositedTokens: [DepositedToken] = []
    
    // Y-axis hours: bottom=02:00 AM, going backward up, top=03:00 AM
    private let yLabels: [String] = {
        // 24 labels from bottom to top:
        // 02, 01, 00, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 09, 08, 07, 06, 05, 04, 03
        var labels: [String] = []
        for i in 0..<24 {
            let hour = (2 - i + 24) % 24
            labels.append(String(format: "%02d:00", hour))
        }
        return labels.reversed() // reversed so index 0 = top (03:00), last = bottom (02:00)
    }()
    
    // X-axis days: Today, Sat, Fri, Thu, Wed, Tue, Mon
    private let xLabels: [String] = ["Today", "Sat", "Fri", "Thu", "Wed", "Tue", "Mon"]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                Spacer().frame(height: 80)
                graphArea
                Spacer()
            }
        }
        .onAppear {
            depositedTokens = TokenStorage.load()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button(action: onTreasureChest) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
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
                        .frame(width: 40, height: 30)
                    RoundedRectangle(cornerRadius: 6)
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
                        .frame(width: 40, height: 10)
                        .offset(y: -15)
                }
            }
            .frame(width: 50, height: 50)
            .offset(y: 40)
            
            Spacer()
            
            Text("Calendar View")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.black)
                .offset(y: 40)
            
            Spacer()
            
            Button("Back") {
                onBack()
            }
            .font(.headline)
            .foregroundColor(Color.black)
            .padding(.trailing, 10)
            
            // Man figure button for ColorChannelView
            Button(action: onColorChannel) {
                Image("A1FF66D0-72A3-4382-B538-9EE37197DEA4_4_5005_c")
                    .resizable()
                    .frame(width: 25, height: 30)
            }
            .frame(width: 40, height: 40)
            .offset(y: 40)
        }
        .padding(.horizontal, 15)
        .padding(.top, 20)
    }
    
    // MARK: - Graph Area
    
    private var graphArea: some View {
        GeometryReader { outer in
            let yLabelW: CGFloat = 55
            let xLabelH: CGFloat = 30
            let graphW: CGFloat = outer.size.width - yLabelW - 60
            let graphH: CGFloat = 600
            let colW: CGFloat = graphW / 7.0
            let rowH: CGFloat = graphH / 24.0
            
            ZStack(alignment: .topLeading) {
                // Y-axis labels - centered vertically on each horizontal line
                ForEach(0..<24, id: \.self) { i in
                    Text(yLabels[i])
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.8))
                        .position(
                            x: yLabelW / 2.0,
                            y: CGFloat(i) * rowH
                        )
                }
                
                // Graph area
                ZStack {
                    // Horizontal grid lines (25 lines for 24 rows)
                    ForEach(0..<25, id: \.self) { i in
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: graphW, height: 1)
                            .position(x: graphW / 2.0, y: CGFloat(i) * rowH)
                    }
                    
                    // Vertical grid lines (8 lines, first one blank)
                    ForEach(1..<8, id: \.self) { i in
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 1, height: graphH)
                            .position(x: CGFloat(i) * colW, y: graphH / 2.0)
                    }
                    
                    // Token dots
                    ForEach(depositedTokens, id: \.id) { token in
                        tokenDot(token: token, geoSize: CGSize(width: graphW, height: graphH))
                    }
                }
                .frame(width: graphW, height: graphH)
                .offset(x: yLabelW)
                
                // X-axis labels - centered under each vertical line (starting from line 1)
                ForEach(0..<7, id: \.self) { i in
                    Text(xLabels[i])
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.black)
                        .position(
                            x: yLabelW + CGFloat(i + 1) * colW,
                            y: graphH + xLabelH / 2.0
                        )
                }
            }
        }
        .frame(height: 640)
        .padding(.leading, 10)
        .padding(.trailing, 10)
    }
    
    // MARK: - Token Dot
    
    @ViewBuilder
    private func tokenDot(token: DepositedToken, geoSize: CGSize) -> some View {
        let pos = tokenPosition(token: token, w: geoSize.width, h: geoSize.height)
        if pos.x >= 0 && pos.x <= geoSize.width && pos.y >= 0 && pos.y <= geoSize.height {
            VStack(spacing: 2) {
                ZStack {
                    TokenShapeHelper.shapeView(
                        shape: token.shape,
                        color: ColorHelper.resolve(color: token.color, shade: token.shade)
                    )
                    if token.showALabel && token.showILabel && token.showMLabel {
                        TokenShapeHelper.strokeView(shape: token.shape, lineWidth: 1, color: CoinTokenView.goldDark)
                            .scaleEffect(0.93)
                    }
                    VStack(spacing: 0) {
                        if token.showALabel {
                            Text("A")
                                .font(.system(size: 2, weight: .bold))
                                .foregroundColor(CoinTokenView.goldLabel)
                        }
                        if token.showILabel {
                            Text("I")
                                .font(.system(size: 2, weight: .bold))
                                .foregroundColor(CoinTokenView.goldLabel)
                        }
                        if token.showMLabel {
                            Text("M")
                                .font(.system(size: 2, weight: .bold))
                                .foregroundColor(CoinTokenView.goldLabel)
                        }
                    }
                }
                .frame(width: 16, height: 16)
                .shadow(color: Color.black.opacity(0.3), radius: 2)
                
                Text(String(token.id.suffix(4)))
                    .font(.system(size: 5))
                    .foregroundColor(Color.black.opacity(0.6))
            }
            .position(x: pos.x, y: pos.y)
        }
    }
    
    // MARK: - Token Position
    
    private func tokenPosition(token: DepositedToken, w: CGFloat, h: CGFloat) -> CGPoint {
        let cal = Calendar.current
        let now = Date()
        
        // X: which day column (0=Today on line 1, 1=Sat on line 2, etc.)
        let daysSinceToday = cal.dateComponents([.day], from: token.depositedAt, to: now).day ?? 0
        let dayIndex = CGFloat(min(max(daysSinceToday, 0), 6))
        let colW = w / 7.0
        let x = (dayIndex + 1) * colW // Position on vertical line (Today on line 1)
        
        // Y: hour position - on the line
        let comps = cal.dateComponents([.hour, .minute], from: token.depositedAt)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        
        // Going backward from 02:00: 02, 01, 00, 23, 22, ..., 03
        // Position from top: 03:00=0, 02:00=1, 01:00=2, 00:00=3, 23:00=4, ..., 03:00=24
        let stepsFromTop = (3 - hour + 24) % 24
        let minuteFraction = CGFloat(minute) / 60.0
        let normalizedY = (CGFloat(stepsFromTop) + minuteFraction) / 24.0
        let y = normalizedY * h
        
        return CGPoint(x: x, y: y)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(onBack: {}, onTreasureChest: {}, onColorChannel: {})
    }
}
