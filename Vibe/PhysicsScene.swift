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
            let sharpness: Float = currentMaterial == .glass ? 0.9 : (currentMaterial == .sand ? 0.3 : 0.5)
            haptics?.playImpact(intensity: intensity, sharpness: sharpness)
            
            let soundName: String
            switch currentMaterial {
            case .mercury: soundName = "mercury_slosh"
            case .glass: soundName = "glass_impact"
            case .sand: soundName = "sand_shift"
            }
            AudioManager.shared.playSound(named: soundName, volume: intensity * 0.5)
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
            let strength: CGFloat = 35.0
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            let velocity = previousLocation.distance(to: location)
            
            if isSandboxMode {
                // Manipulate existing materials (apply force to nodes near touch)
                let touchRadius: CGFloat = 40.0
                let nodesNearTouch = self.nodes(at: location)
                
                for node in nodesNearTouch {
                    if let physicsBody = node.physicsBody {
                        let dx = location.x - previousLocation.x
                        let dy = location.y - previousLocation.y
                        physicsBody.applyForce(CGVector(dx: dx * 2.0, dy: dy * 2.0))
                    }
                }
            } else {
                // Classic mode: spawn new material
                spawnGlobule(at: location, isTemporary: true)
            }
            
            if velocity > 5 {
                haptics?.playImpact(intensity: Float(min(velocity / 50.0, 0.3)), sharpness: 0.1)
                
                let soundName = currentMaterial == .glass ? "glass_crumble" : (currentMaterial == .mercury ? "mercury_slosh" : "sand_shift")
                AudioManager.shared.playSound(named: soundName, volume: 0.1)
            }
        }
    }
    
    func spawnGlobule(at point: CGPoint, isTemporary: Bool) {
        let radius: CGFloat
        let textureName: String
        
        switch currentMaterial {
        case .mercury: 
            radius = CGFloat.random(in: 10...18)
            textureName = "mercury_texture"
        case .glass: 
            radius = CGFloat.random(in: 8...14)
            textureName = "glass_texture"
        case .sand: 
            radius = CGFloat.random(in: 3...6)
            textureName = "sand_texture"
        }
        
        let globule = SKSpriteNode(imageNamed: textureName)
        globule.size = CGSize(width: radius * 2, height: radius * 2)
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
    
    private func setupPhysics(for node: SKSpriteNode, radius: CGFloat) {
        node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.contactTestBitMask = 1
        // Performance optimization: prevent continuous precise collision checks for huge particle counts
        node.physicsBody?.usesPreciseCollisionDetection = false
        
        switch currentMaterial {
        case .mercury:
            node.physicsBody?.restitution = 0.1
            node.physicsBody?.friction = 0.01
            node.physicsBody?.mass = 0.5
            // High alpha to ensure metaball threshold works
            node.alpha = 1.0
        case .glass:
            node.physicsBody?.restitution = 0.6
            node.physicsBody?.friction = 0.2
            node.physicsBody?.mass = 0.1
            node.alpha = 0.8 // slight translucency
        case .sand:
            node.physicsBody?.restitution = 0.0
            node.physicsBody?.friction = 1.0
            node.physicsBody?.mass = 0.02
        }
    }
    
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
