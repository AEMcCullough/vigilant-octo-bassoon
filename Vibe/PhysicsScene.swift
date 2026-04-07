import SpriteKit
import UIKit
import CoreMotion
import Combine

class PhysicsScene: SKScene, SKPhysicsContactDelegate {
    var haptics: HapticsManager?
    @Published var currentMaterial: VibeMaterial = .mercury
    var isSandboxMode: Bool = false
    
    private let motionManager = CMMotionManager()
    private var metaballContainer = MetaballNode()
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        addChild(metaballContainer)
        setupMotion()
        setupContainment()
        
        NotificationCenter.default.addObserver(forName: .deviceDidShake, object: nil, queue: .main) { [weak self] _ in
            self?.reset()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let velocity = contact.collisionImpulse
        let intensity = min(Float(velocity / 800.0), 1.0)
        
        if intensity > 0.1 {
            // Keep a very slight haptic feel for hard physics collisions, but NO clunky audio.
            let sharpness: Float = currentMaterial == .glass ? 0.9 : (currentMaterial == .sand ? 0.3 : 0.5)
            haptics?.playImpact(intensity: intensity * 0.2, sharpness: sharpness)
        }
    }
    
    func fillSandbox() {
        reset()
        isSandboxMode = true
        let size = self.size
        let spacing: CGFloat = currentMaterial == .sand ? 15 : 25
        let cols = Int(size.width / spacing)
        let rows = Int(size.height / spacing / 2.5) // Fill bottom portion
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * spacing + spacing/2
                let y = CGFloat(r) * spacing + spacing/2
                spawnGlobule(at: CGPoint(x: x, y: y), isTemporary: false)
            }
        }
    }
    
    func reset() {
        removeAllChildren()
        metaballContainer.removeAllChildren()
        addChild(metaballContainer)
        setupContainment()
        isSandboxMode = false
    }
    
    private func setupMotion() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1/60
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let acceleration = data?.acceleration else { return }
            
            // Adjust the gravitational pull multiplier based on the material's real-world density
            let strength: CGFloat
            switch self.currentMaterial {
            case .mercury: strength = 60.0 // Very heavy, reacts strongly to tilt
            case .glass: strength = 25.0  // Lighter
            case .sand: strength = 35.0   // Standard
            }
            
            self.physicsWorld.gravity = CGVector(
                dx: CGFloat(acceleration.x) * strength,
                dy: CGFloat(acceleration.y) * strength
            )
        }
    }
    
    private func setupContainment() {
        let frameBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody = frameBody
        physicsBody?.categoryBitMask = 1
        physicsBody?.contactTestBitMask = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, isMoving: false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, isMoving: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        AudioManager.shared.updateLoop(named: getLoopName(), intensity: 0.0)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        AudioManager.shared.updateLoop(named: getLoopName(), intensity: 0.0)
    }
    
    private func handleTouches(_ touches: Set<UITouch>, isMoving: Bool) {
        var totalVelocity: CGFloat = 0.0
        
        for touch in touches {
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            
            if isMoving {
                totalVelocity += previousLocation.distance(to: location)
            }
            
            if isSandboxMode {
                // Manipulate existing materials (apply force to nodes near touch)
                let nodesNearTouch = self.nodes(at: location)
                for node in nodesNearTouch {
                    if let physicsBody = node.physicsBody {
                        let dx = location.x - previousLocation.x
                        let dy = location.y - previousLocation.y
                        physicsBody.applyForce(CGVector(dx: dx * 2.0, dy: dy * 2.0))
                    }
                }
            } else {
                // Classic mode: paintbrush spawn
                spawnGlobule(at: location, isTemporary: true)
            }
        }
        
        if isMoving && totalVelocity > 2 {
            let intensity = Float(min(totalVelocity / 100.0, 1.0))
            haptics?.playImpact(intensity: intensity * 0.5, sharpness: 0.1)
            AudioManager.shared.updateLoop(named: getLoopName(), intensity: intensity)
        }
    }
    
    private func getLoopName() -> String {
        switch currentMaterial {
        case .mercury: return "mercury_slosh"
        case .glass: return "glass_crumble"
        case .sand: return "sand_shift"
        }
    }
    
    func spawnGlobule(at point: CGPoint, isTemporary: Bool) {
        let radius: CGFloat
        let globule: SKShapeNode
        
        switch currentMaterial {
        case .mercury: 
            radius = CGFloat.random(in: 12...16)
            globule = SKShapeNode(circleOfRadius: radius)
            // Metallic silver styling
            globule.fillColor = UIColor(white: 0.85, alpha: 1.0)
            globule.strokeColor = .clear
        case .glass: 
            // Procedural "shard" aesthetics using varying sizes and additive blending
            radius = CGFloat.random(in: 6...12)
            globule = SKShapeNode(rectOf: CGSize(width: radius * 2, height: radius))
            globule.fillColor = .cyan.withAlphaComponent(0.25)
            globule.strokeColor = .white.withAlphaComponent(0.6)
            globule.lineWidth = 1.0
            globule.blendMode = .add // Gives a sparkling, refractive look when overlapping
            globule.zRotation = CGFloat.random(in: 0...CGFloat.pi*2)
        case .sand: 
            // Dense, organic granular clusters
            radius = CGFloat.random(in: 2...4.5)
            globule = SKShapeNode(circleOfRadius: radius)
            let colors: [UIColor] = [
                UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0), // Tan
                UIColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 1.0), // Brown
                UIColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)  // Light Sand
            ]
            globule.fillColor = colors.randomElement()!
            globule.strokeColor = .clear
        }
        
        globule.position = point
        setupPhysics(for: globule, radius: radius)
        
        if currentMaterial == .mercury {
            metaballContainer.addChild(globule)
        } else {
            addChild(globule)
        }

        
        if isTemporary {
            globule.run(SKAction.sequence([
                SKAction.wait(forDuration: isTemporary ? 4.0 : 1000),
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func setupPhysics(for node: SKNode, radius: CGFloat) {
        if currentMaterial == .glass {
            // Box physics for shards
            node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: radius * 2, height: radius))
        } else {
            node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        }
        
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.contactTestBitMask = 1
        // Performance optimization: prevent continuous precise collision checks for huge particle counts
        node.physicsBody?.usesPreciseCollisionDetection = false
        
        switch currentMaterial {
        case .mercury:
            node.physicsBody?.restitution = 0.05 // Heavy, viscous, doesn't bounce much
            node.physicsBody?.friction = 0.05    // Slippery
            node.physicsBody?.linearDamping = 0.8 // Sludge-like drag
            node.physicsBody?.mass = 1.0         // High density
        case .glass:
            node.physicsBody?.restitution = 0.4  // Crisp bounce
            node.physicsBody?.friction = 0.3     // Somewhat sharp
            node.physicsBody?.mass = 0.15        // Light shards
        case .sand:
            node.physicsBody?.restitution = 0.0  // No bounce
            node.physicsBody?.friction = 1.0     // Very high friction to pile up
            node.physicsBody?.linearDamping = 0.2
            node.physicsBody?.mass = 0.05        // Very light
        }
    }
    
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
