import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var haptics = HapticsManager()
    
    var body: some View {
        ZStack {
            // Background Gradient
            Color.black.ignoresSafeArea()
            
            // The Physics Canvas
            SpriteView(scene: makeScene())
                .ignoresSafeArea()
            
            // Minimal Overlay
            VStack {
                Text("VIBE")
                    .font(.system(size: 12, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 40)
                
                Spacer()
                
                // Material Selector (Hidden by default, shows on swipe)
                HStack(spacing: 20) {
                    MaterialIcon(name: "Mercury", color: .gray)
                    MaterialIcon(name: "Sand", color: .orange)
                    MaterialIcon(name: "Glass", color: .blue)
                }
                .padding(.bottom, 30)
                .opacity(0.5)
            }
        }
        .onAppear {
            haptics.prepare()
        }
    }
    
    private func makeScene() -> SKScene {
        // Use a safe default size; scaleMode handles the rest
        let scene = PhysicsScene(size: CGSize(width: 400, height: 800))
        scene.scaleMode = .resizeFill
        scene.haptics = haptics
        return scene
    }
}

struct MaterialIcon: View {
    let name: String
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(Circle().stroke(color.opacity(0.5), lineWidth: 1))
    }
}
