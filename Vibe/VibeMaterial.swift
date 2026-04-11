import Foundation
import UIKit

enum VibeMaterial: String, CaseIterable {
    case mercury = "Mercury"
    case glass = "Glass"
    case sand = "Sand"
    
    struct Tuning {
        // Physics
        let mass: CGFloat
        let friction: CGFloat
        let restitution: CGFloat
        let linearDamping: CGFloat
        
        // Visuals
        let baseColor: UIColor
        let blendMode: Int // 0: alpha, 1: additive
        let particleSize: ClosedRange<CGFloat>
        let visualStyle: VisualStyle
        
        // Sensory
        let loopName: String
        let impactPower: Float
        let hapticSharpness: Float
        
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
                mass: 1.2,
                friction: 0.05,
                restitution: 0.1,
                linearDamping: 0.9,
                baseColor: UIColor(white: 0.85, alpha: 1.0),
                blendMode: 0,
                particleSize: 12...18,
                visualStyle: .metaball,
                loopName: "mercury_slosh",
                impactPower: 0.8,
                hapticSharpness: 0.4
            )
        case .glass:
            return Tuning(
                mass: 0.2,
                friction: 0.4,
                restitution: 0.45,
                linearDamping: 0.1,
                baseColor: UIColor.cyan.withAlphaComponent(0.3),
                blendMode: 1, // Additive
                particleSize: 6...14,
                visualStyle: .shard,
                loopName: "glass_crumble",
                impactPower: 0.5,
                hapticSharpness: 0.9
            )
        case .sand:
            return Tuning(
                mass: 0.08,
                friction: 1.0,
                restitution: 0.0,
                linearDamping: 0.3,
                baseColor: UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0),
                blendMode: 0,
                particleSize: 2.5...5.0,
                visualStyle: .grain,
                loopName: "sand_shift",
                impactPower: 0.3,
                hapticSharpness: 0.2
            )
        }
    }
}
