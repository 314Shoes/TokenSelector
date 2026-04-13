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
    
    // X-axis days: Today, then previous 6 days by weekday name
    private let xLabels: [String] = {
        let cal = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, etc.
        var labels = ["Today"]
        for i in 1...6 {
            let date = cal.date(byAdding: .day, value: -i, to: today)!
            labels.append(formatter.string(from: date))
        }
        return labels
    }()
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                Spacer().frame(height: 40)
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
        VStack(spacing: 0) {
            // Title centered under dynamic island
            Text("Calendar View")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            // Treasure chest and man icon row
            HStack {
                Button(action: onTreasureChest) {
                    ZStack {
                        // Chest body
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.35, blue: 0.18),
                                        Color(red: 0.35, green: 0.20, blue: 0.10)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 44, height: 28)
                        // Chest body outline
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.3, green: 0.18, blue: 0.08), lineWidth: 1.5)
                            .frame(width: 44, height: 28)
                        // Horizontal band
                        Rectangle()
                            .fill(Color(red: 0.70, green: 0.55, blue: 0.25))
                            .frame(width: 44, height: 4)
                        // Lid
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.65, green: 0.45, blue: 0.22),
                                        Color(red: 0.50, green: 0.32, blue: 0.15)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 46, height: 14)
                            .offset(y: -16)
                        // Lid outline
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(red: 0.3, green: 0.18, blue: 0.08), lineWidth: 1.5)
                            .frame(width: 46, height: 14)
                            .offset(y: -16)
                        // Lid band
                        Rectangle()
                            .fill(Color(red: 0.70, green: 0.55, blue: 0.25))
                            .frame(width: 46, height: 3)
                            .offset(y: -16)
                        // Keyhole clasp
                        Circle()
                            .fill(Color(red: 0.80, green: 0.65, blue: 0.20))
                            .frame(width: 8, height: 8)
                            .offset(y: -8)
                        Circle()
                            .fill(Color(red: 0.35, green: 0.22, blue: 0.10))
                            .frame(width: 4, height: 4)
                            .offset(y: -8)
                        // Corner studs
                        Circle()
                            .fill(Color(red: 0.80, green: 0.65, blue: 0.20))
                            .frame(width: 4, height: 4)
                            .offset(x: -18, y: -10)
                        Circle()
                            .fill(Color(red: 0.80, green: 0.65, blue: 0.20))
                            .frame(width: 4, height: 4)
                            .offset(x: 18, y: -10)
                        Circle()
                            .fill(Color(red: 0.80, green: 0.65, blue: 0.20))
                            .frame(width: 4, height: 4)
                            .offset(x: -18, y: 10)
                        Circle()
                            .fill(Color(red: 0.80, green: 0.65, blue: 0.20))
                            .frame(width: 4, height: 4)
                            .offset(x: 18, y: 10)
                    }
                }
                .frame(width: 55, height: 50)

                Spacer()

                // Man figure button for ColorChannelView
                Button(action: onColorChannel) {
                    Image("A1FF66D0-72A3-4382-B538-9EE37197DEA4_4_5005_c")
                        .resizable()
                        .frame(width: 25, height: 30)
                }
                .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 15)
            .padding(.top, 8)
        }
        .padding(.top, 50)
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
        .padding(.leading, 25)
        .padding(.trailing, 10)
    }
    
    // MARK: - Token Dot
    
    @ViewBuilder
    private func tokenDot(token: DepositedToken, geoSize: CGSize) -> some View {
        let pos = tokenPosition(token: token, w: geoSize.width, h: geoSize.height)
        if pos.x >= 0 && pos.x <= geoSize.width && pos.y >= 0 && pos.y <= geoSize.height {
            VStack(spacing: 2) {
                TokenBadgeView(token: token, size: 16, labelSize: 2)
                    .shadow(color: .black.opacity(0.3), radius: 2)

                Text(String(token.id.suffix(4)))
                    .font(.system(size: 5))
                    .foregroundColor(.black.opacity(0.6))
            }
            .position(x: pos.x, y: pos.y)
        }
    }
    
    // MARK: - Token Position
    
    private func tokenPosition(token: DepositedToken, w: CGFloat, h: CGFloat) -> CGPoint {
        let cal = Calendar.current
        let now = Date()

        // X: which day column — compare calendar dates (startOfDay), not elapsed time
        let todayStart = cal.startOfDay(for: now)
        let tokenStart = cal.startOfDay(for: token.depositedAt)
        let daysSinceToday = cal.dateComponents([.day], from: tokenStart, to: todayStart).day ?? 0
        let dayIndex = CGFloat(min(max(daysSinceToday, 0), 6))
        let colW = w / 7.0
        let x = (dayIndex + 1) * colW // Position on vertical line (Today on line 1)
        
        // Y: hour position - on the line
        let comps = cal.dateComponents([.hour, .minute], from: token.depositedAt)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        
        // Position from top: 03:00=0, 04:00=1, ..., 23:00=20, 00:00=21, 01:00=22, 02:00=23
        let stepsFromTop = (hour - 3 + 24) % 24
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
