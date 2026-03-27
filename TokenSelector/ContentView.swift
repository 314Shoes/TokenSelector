import SwiftUI

enum AppScreen {
    case shadeSelection
    case colorSelection
    case shapeSelection
    case token
    case useToken
}

enum ShadeChoice {
    case black, white
}

enum ColorChoice: String, CaseIterable {
    case blue, green, red
}

enum ShapeChoice: String, CaseIterable {
    case square, circle, triangleUp, triangleDown
    
    var displayName: String {
        switch self {
        case .square: return "Square"
        case .circle: return "Circle"
        case .triangleUp: return "Triangle Up"
        case .triangleDown: return "Triangle Down"
        }
    }
}

struct ContentView: View {
    @State private var currentScreen: AppScreen = .shadeSelection
    @State private var selectedShade: ShadeChoice = .white
    @State private var selectedColor: ColorChoice = .blue
    @State private var selectedShape: ShapeChoice = .square
    @State private var tokenID: String = ""
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .shadeSelection:
                ShadeSelectionView { shade in
                    selectedShade = shade
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .colorSelection
                    }
                }
                .transition(.opacity)
                
            case .colorSelection:
                ColorSelectionView(shade: selectedShade) { color in
                    selectedColor = color
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .shapeSelection
                    }
                }
                .transition(.opacity)
                
            case .shapeSelection:
                ShapeSelectionView(
                    shade: selectedShade,
                    colorChoice: selectedColor
                ) { shape in
                    selectedShape = shape
                    tokenID = generateTokenID()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .token
                    }
                }
                .transition(.opacity)
                
            case .token:
                TokenView(
                    shade: selectedShade,
                    colorChoice: selectedColor,
                    shapeChoice: selectedShape,
                    tokenID: tokenID,
                    onRestart: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen = .shadeSelection
                        }
                    },
                    onUseToken: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen = .useToken
                        }
                    }
                )
                .transition(.opacity)
                
            case .useToken:
                UseTokenView(
                    shade: selectedShade,
                    colorChoice: selectedColor,
                    shapeChoice: selectedShape,
                    tokenID: tokenID,
                    onDeposit: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen = .shadeSelection
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateTokenID() -> String {
        let chars = "ABCDEF0123456789"
        let id = String((0..<8).map { _ in chars.randomElement()! })
        return "TOKEN-\(id)"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
