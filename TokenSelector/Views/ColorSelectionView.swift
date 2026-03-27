import SwiftUI

struct ColorSelectionView: View {
    let shade: ShadeChoice
    let onSelect: (ColorChoice) -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Blue row
                Button {
                    onSelect(.blue)
                } label: {
                    ZStack {
                        resolvedColor(for: .blue)
                    }
                }
                .frame(height: geo.size.height / 3)
                
                // Green row
                Button {
                    onSelect(.green)
                } label: {
                    ZStack {
                        resolvedColor(for: .green)
                    }
                }
                .frame(height: geo.size.height / 3)
                
                // Red row
                Button {
                    onSelect(.red)
                } label: {
                    ZStack {
                        resolvedColor(for: .red)
                    }
                }
                .frame(height: geo.size.height / 3)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func resolvedColor(for color: ColorChoice) -> Color {
        ColorHelper.resolve(color: color, shade: shade)
    }
}

struct ColorSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSelectionView(shade: .black) { color in
            print("Selected: \(color)")
        }
    }
}
