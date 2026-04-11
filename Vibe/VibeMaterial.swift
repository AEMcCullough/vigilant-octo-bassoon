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
        
        // Tilt & Inertia
        let tiltSensitivity: CGFloat
        let tiltSmoothing: CGFloat
        
        // Visuals
        let baseColor: UIColor
        let blendMode: Int // 0: alpha, 1: additive
        let particleSize: ClosedRange<CGFloat>
        let visualStyle: VisualStyle
        let mergeRadius: CGFloat 
        
        // Sensory
        let loopName: String
        let impactPower: Float
        let hapticSharpness: Float
        let sloshAudioIntensity: Float
        
        // Interaction & Sandbox (Corrective Adjustments)
        let sandboxForceMultiplier: CGFloat
        let disturbanceRadius: CGFloat // New: Area-of-influence
        let sandboxFillDensity: CGFloat 
        
        // Persistence
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
                mass: 3.8,              // Extreme density
                friction: 0.01,         // Very slippery
                restitution: 0.0,       // No bounce - "splats" and pools
                linearDamping: 6.5,     // Heavy viscous drag to kill jitter
                tiltSensitivity: 35.0,  // Slowest response
                tiltSmoothing: 0.04,    // Max inertia
                baseColor: UIColor(white: 0.95, alpha: 1.0),
                blendMode: 0,
                particleSize: 16...24,  // Larger blobs for pooling
                visualStyle: .metaball,
                mergeRadius: 65.0,      // Wider cohesion reach
                loopName: "mercury_slosh",
                impactPower: 1.0,
                hapticSharpness: 0.2,
                sloshAudioIntensity: 2.2, // Buffed audio scaling
                sandboxForceMultiplier: 25.0, // Massive buff for "Stirring" feel
                disturbanceRadius: 60.0,    // Wide area of influence
                sandboxFillDensity: 32.0,
                nodeCap: 200,                // Fewer, larger blobs
                fadeDuration: 20.0
            )
        case .glass:
            return Tuning(
                mass: 0.6,
                friction: 0.3,
                restitution: 0.3,
                linearDamping: 1.2,
                tiltSensitivity: 30.0,
                tiltSmoothing: 0.1,
                baseColor: UIColor.cyan.withAlphaComponent(0.5),
                blendMode: 1,
                particleSize: 10...20,
                visualStyle: .shard,
                mergeRadius: 0.0,
                loopName: "glass_crumble",
                impactPower: 0.7,
                hapticSharpness: 0.9,
                sloshAudioIntensity: 1.0,
                sandboxForceMultiplier: 15.0,
                disturbanceRadius: 45.0,
                sandboxFillDensity: 20.0,
                nodeCap: 350,
                fadeDuration: 12.0
            )
        case .sand:
            return Tuning(
                mass: 0.15,
                friction: 1.0,
                restitution: 0.0,
                linearDamping: 2.5,     // Damped "avalanche" feel
                tiltSensitivity: 40.0,
                tiltSmoothing: 0.08,
                baseColor: UIColor(red: 0.85, green: 0.78, blue: 0.6, alpha: 1.0),
                blendMode: 0,
                particleSize: 4.5...8.0,
                visualStyle: .grain,
                mergeRadius: 0.0,
                loopName: "sand_shift",
                impactPower: 0.5,
                hapticSharpness: 0.3,
                sloshAudioIntensity: 1.0,
                sandboxForceMultiplier: 18.0,
                disturbanceRadius: 50.0,
                sandboxFillDensity: 12.0,
                nodeCap: 700,
                fadeDuration: 30.0
            )
        }
    }
}
