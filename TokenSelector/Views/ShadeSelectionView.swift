import SwiftUI

struct ShadeSelectionView: View {
    let onSelect: (ShadeChoice) -> Void
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Black side
                Button {
                    onSelect(.black)
                } label: {
                    ZStack {
                        Color.black
                    }
                }
                .frame(width: geo.size.width / 2, height: geo.size.height)
                
                // White side
                Button {
                    onSelect(.white)
                } label: {
                    ZStack {
                        Color.white
                    }
                }
                .frame(width: geo.size.width / 2, height: geo.size.height)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ShadeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ShadeSelectionView { shade in
            print("Selected: \(shade)")
        }
    }
}
