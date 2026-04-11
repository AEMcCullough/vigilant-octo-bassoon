import Foundation
import UIKit

enum VibeMaterial: String, CaseIterable {
    case mercury = "Mercury"
    case glass = "Glass"
    case sand = "Sand"
    
    struct Tuning {
        // Physics Core
        let mass: CGFloat
        let friction: CGFloat
        let restitution: CGFloat
        let linearDamping: CGFloat
        
        // Tilt & Inertia (Adjustments #1)
        let tiltSensitivity: CGFloat
        let tiltSmoothing: CGFloat
        
        // Visuals (Adjustments #2)
        let baseColor: UIColor
        let blendMode: Int // 0: alpha, 1: additive
        let particleSize: ClosedRange<CGFloat>
        let visualStyle: VisualStyle
        let mergeRadius: CGFloat // Mercury pooling
        
        // Sensory
        let loopName: String
        let impactPower: Float
        let hapticSharpness: Float
        let sloshAudioIntensity: Float // Mercury specific
        
        // Interaction & Sandbox (Adjustments #5 & #6)
        let sandboxForceMultiplier: CGFloat
        let sandboxFillDensity: CGFloat // Spacing multiplier
        
        // Persistence (Adjustments #3)
        let nodeCap: Int
        let fadeDuration: TimeInterval
        
        enum VisualStyle {
            case metaball
            case shard
            case grain
        }
    }
    
    var tuning: Tuning {
        switch self {
        case .mercury:
            return Tuning(
                mass: 1.4,
                friction: 0.02,
                restitution: 0.05,
                linearDamping: 1.2, // Heavier fluid drag
                tiltSensitivity: 45.0, // Slower response
                tiltSmoothing: 0.08,  // Higher smoothing
                baseColor: UIColor(white: 0.9, alpha: 1.0),
                blendMode: 0,
                particleSize: 14...20,
                visualStyle: .metaball,
                mergeRadius: 35.0,
                loopName: "mercury_slosh",
                impactPower: 0.9,
                hapticSharpness: 0.3,
                sloshAudioIntensity: 1.2,
                sandboxForceMultiplier: 6.5,
                sandboxFillDensity: 28.0,
                nodeCap: 250,
                fadeDuration: 12.0
            )
        case .glass:
            return Tuning(
                mass: 0.25,
                friction: 0.4,
                restitution: 0.4,
                linearDamping: 0.2,
                tiltSensitivity: 25.0,
                tiltSmoothing: 0.15,
                baseColor: UIColor.cyan.withAlphaComponent(0.4),
                blendMode: 1,
                particleSize: 8...16,
                visualStyle: .shard,
                mergeRadius: 0.0,
                loopName: "glass_crumble",
                impactPower: 0.6,
                hapticSharpness: 0.95,
                sloshAudioIntensity: 0.0,
                sandboxForceMultiplier: 4.5,
                sandboxFillDensity: 22.0,
                nodeCap: 400,
                fadeDuration: 8.0
            )
        case .sand:
            return Tuning(
                mass: 0.1,
                friction: 1.0,
                restitution: 0.0,
                linearDamping: 0.5,
                tiltSensitivity: 35.0,
                tiltSmoothing: 0.12,
                baseColor: UIColor(red: 0.8, green: 0.73, blue: 0.55, alpha: 1.0),
                blendMode: 0,
                particleSize: 3.5...6.0,
                visualStyle: .grain,
                mergeRadius: 0.0,
                loopName: "sand_shift",
                impactPower: 0.4,
                hapticSharpness: 0.2,
                sloshAudioIntensity: 0.0,
                sandboxForceMultiplier: 5.5,
                sandboxFillDensity: 14.0,
                nodeCap: 800,
                fadeDuration: 15.0
            )
        }
    }
}
