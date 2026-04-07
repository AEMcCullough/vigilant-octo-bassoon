import SwiftUI
import SpriteKit
import Combine

struct ContentView: View {
    @StateObject private var haptics = HapticsManager()
    @State private var selectedMaterial: VibeMaterial = .mercury
    @State private var isSandboxMode: Bool = false
    
    // We store the scene as a @State to keep it persistent
    @State private var scene: PhysicsScene = {
        let sc = PhysicsScene(size: CGSize(width: 400, height: 800))
        sc.scaleMode = .resizeFill
        return sc
    }()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.haptics = haptics
                    haptics.prepare()
                }
            
            // UI Overlay
            VStack {
                Text("VIBE 2.0")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 50)
                
                Spacer()
                
                // Material Selector
                HStack(spacing: 25) {
                    ForEach(VibeMaterial.allCases, id: \.self) { material in
                        Button(action: {
                            selectedMaterial = material
                            scene.currentMaterial = material
                        }) {
                            VStack {
                                Circle()
                                    .fill(color(for: material))
                                    .frame(width: 45, height: 45)
                                    .scaleEffect(selectedMaterial == material ? 1.2 : 1.0)
                                    .overlay(Circle().stroke(.white, lineWidth: selectedMaterial == material ? 2 : 0))
                                
                                Text(material.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
                
                // Controls
                HStack(spacing: 30) {
                    Button(action: {
                        isSandboxMode.toggle()
                        if isSandboxMode { scene.fillSandbox() }
                    }) {
                        Image(systemName: isSandboxMode ? "square.grid.3x3.fill" : "square.grid.3x3")
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { scene.reset() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func color(for material: VibeMaterial) -> Color {
        switch material {
        case .mercury: return .gray
        case .glass: return .cyan
        case .sand: return .orange
        }
    }
}
