import SpriteKit
import UIKit
import CoreMotion
import Combine

class PhysicsScene: SKScene, SKPhysicsContactDelegate {
    var haptics: HapticsManager?
    @Published var currentMaterial: VibeMaterial = .mercury
    
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
            AudioManager.shared.playSound(named: currentMaterial.rawValue.lowercased() + "_impact", volume: intensity)
        }
    }
    
    func fillSandbox() {
        reset()
        let size = self.size
        let spacing: CGFloat = currentMaterial == .sand ? 12 : 25
        let cols = Int(size.width / spacing)
        let rows = Int(size.height / spacing / 2) // Fill bottom half
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * spacing + spacing/2
                let y = CGFloat(r) * spacing + spacing/2
                spawnGlobule(at: CGPoint(x: x, y: y), isTemporary: false)
            }
        }
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
            spawnGlobule(at: location, isTemporary: true)
            
            let velocity = touch.previousLocation(in: self).distance(to: location)
            if velocity > 5 {
                haptics?.playImpact(intensity: Float(min(velocity / 50.0, 0.4)), sharpness: 0.2)
                if currentMaterial == .sand {
                    AudioManager.shared.playSound(named: "sand_grind", volume: 0.2)
                }
            }
        }
    }
    
    func spawnGlobule(at point: CGPoint, isTemporary: Bool) {
        let radius: CGFloat
        switch currentMaterial {
        case .mercury: radius = CGFloat.random(in: 10...18)
        case .glass: radius = CGFloat.random(in: 8...14)
        case .sand: radius = CGFloat.random(in: 3...6)
        }
        
        let globule = SKShapeNode(circleOfRadius: radius)
        globule.position = point
        
        setupPhysics(for: globule)
        
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
    
    private func setupPhysics(for node: SKShapeNode) {
        let radius = node.frame.size.width / 2
        node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.contactTestBitMask = 1
        
        node.strokeColor = .white.withAlphaComponent(0.2)
        node.lineWidth = 0.5
        
        switch currentMaterial {
        case .mercury:
            node.fillColor = .gray
            node.physicsBody?.restitution = 0.1
            node.physicsBody?.friction = 0.01
            node.physicsBody?.mass = 0.5
            node.alpha = 0.9
        case .glass:
            node.fillColor = .cyan.withAlphaComponent(0.15)
            node.physicsBody?.restitution = 0.6
            node.physicsBody?.friction = 0.2
            node.physicsBody?.mass = 0.1
        case .sand:
            let colors: [UIColor] = [.brown, .orange, .yellow, .gray]
            node.fillColor = colors.randomElement()?.withAlphaComponent(0.8) ?? .orange
            node.physicsBody?.restitution = 0.0
            node.physicsBody?.friction = 1.0
            node.physicsBody?.mass = 0.02
        }
    }
    
    func reset() {
        removeAllChildren()
        metaballContainer.removeAllChildren()
        addChild(metaballContainer)
        setupContainment()
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
