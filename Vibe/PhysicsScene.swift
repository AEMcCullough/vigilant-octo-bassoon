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
    
    // Tilt smoothing parameters
    private var lastGravity: CGVector = .zero
    private let tiltSmoothing: CGFloat = 0.2
    
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
        let tuning = currentMaterial.tuning
        let intensity = min(Float(velocity / 1200.0), 1.0)
        
        if intensity > 0.05 {
            // Adaptive haptics based on material identity
            haptics?.playImpact(intensity: intensity * tuning.impactPower, sharpness: tuning.hapticSharpness)
            
            // Subtle collision audio if it's a hard hit
            if intensity > 0.4 {
                let name = currentMaterial == .glass ? "glass_impact" : (currentMaterial == .mercury ? "mercury_impact" : nil)
                if let sound = name {
                    AudioManager.shared.playSound(named: sound, volume: intensity * 0.3)
                }
            }
        }
    }
    
    func fillSandbox() {
        reset()
        isSandboxMode = true
        let size = self.size
        let tuning = currentMaterial.tuning
        let spacing: CGFloat = currentMaterial == .sand ? 12 : 24
        let cols = Int(size.width / spacing)
        let rows = Int(size.height / spacing / 2.2)
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * spacing + spacing/2 + CGFloat.random(in: -2...2)
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
            
            let strength: CGFloat = self.currentMaterial == .mercury ? 75.0 : (self.currentMaterial == .sand ? 45.0 : 30.0)
            
            let targetGravity = CGVector(
                dx: CGFloat(acceleration.x) * strength,
                dy: CGFloat(acceleration.y) * strength
            )
            
            // Low-pass filter for premium tilt stability
            self.lastGravity = CGVector(
                dx: self.lastGravity.dx * (1.0 - self.tiltSmoothing) + targetGravity.dx * self.tiltSmoothing,
                dy: self.lastGravity.dy * (1.0 - self.tiltSmoothing) + targetGravity.dy * self.tiltSmoothing
            )
            
            self.physicsWorld.gravity = self.lastGravity
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
        AudioManager.shared.updateLoop(named: currentMaterial.tuning.loopName, intensity: 0.0)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        AudioManager.shared.updateLoop(named: currentMaterial.tuning.loopName, intensity: 0.0)
    }
    
    private func handleTouches(_ touches: Set<UITouch>, isMoving: Bool) {
        var totalMotionIntensity: CGFloat = 0.0
        let tuning = currentMaterial.tuning
        
        for touch in touches {
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            let velocity = previousLocation.distance(to: location)
            
            if isMoving {
                totalMotionIntensity += velocity
            }
            
            if isSandboxMode {
                // PREMIUM STIRRING LOGIC: Apply forces to nearby nodes based on agitation
                let affectedNodes = self.nodes(at: location).filter { $0.physicsBody != nil }
                
                for node in affectedNodes {
                    if let pb = node.physicsBody {
                        let dx = (location.x - previousLocation.x) * 4.0
                        let dy = (location.y - previousLocation.y) * 4.0
                        pb.applyImpulse(CGVector(dx: dx, dy: dy))
                        
                        // Glass fracturing: Small chance to spawn a tiny shard if agitated quickly
                        if currentMaterial == .glass && velocity > 20.0 && CGFloat.random(in: 0...1) > 0.95 {
                            spawnGlobule(at: node.position, isTemporary: true)
                            haptics?.playPattern(named: "glass_crack")
                        }
                    }
                }
            } else {
                // PAINTBRUSH MODE
                spawnGlobule(at: location, isTemporary: true)
            }
        }
        
        if isMoving && totalMotionIntensity > 1.0 {
            let intensity = Float(min(totalMotionIntensity / 80.0, 1.0))
            haptics?.playImpact(intensity: intensity * 0.4, sharpness: tuning.hapticSharpness)
            AudioManager.shared.updateLoop(named: tuning.loopName, intensity: intensity)
        }
    }
    
    func spawnGlobule(at point: CGPoint, isTemporary: Bool) {
        let tuning = currentMaterial.tuning
        let radius = CGFloat.random(in: tuning.particleSize)
        let node: SKNode
        
        switch currentMaterial {
        case .mercury:
            let globule = SKShapeNode(circleOfRadius: radius)
            globule.fillColor = tuning.baseColor
            globule.strokeColor = .clear
            node = globule
            metaballContainer.addChild(node)
        case .glass:
            let sprite = SKSpriteNode(imageNamed: "glass_texture.png")
            sprite.size = CGSize(width: radius * 3, height: radius * 1.5)
            sprite.color = tuning.baseColor
            sprite.colorBlendFactor = 0.5
            sprite.blendMode = .add
            sprite.zRotation = CGFloat.random(in: 0...CGFloat.pi*2)
            node = sprite
            addChild(node)
        case .sand:
            let sprite = SKSpriteNode(imageNamed: "sand_texture.png")
            sprite.size = CGSize(width: radius * 2, height: radius * 2)
            let hueVar = CGFloat.random(in: -0.05...0.05)
            sprite.color = tuning.baseColor.modified(hue: hueVar)
            sprite.colorBlendFactor = 0.9
            node = sprite
            addChild(node)
        }
        
        node.position = point
        setupPhysics(for: node, radius: radius, tuning: tuning)
        
        if isTemporary {
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: 3.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func setupPhysics(for node: SKNode, radius: CGFloat, tuning: VibeMaterial.Tuning) {
        if currentMaterial == .glass {
            node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: radius * 3, height: radius * 1.5))
        } else {
            node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        }
        
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.contactTestBitMask = 1
        node.physicsBody?.usesPreciseCollisionDetection = false
        
        node.physicsBody?.mass = tuning.mass
        node.physicsBody?.friction = tuning.friction
        node.physicsBody?.restitution = tuning.restitution
        node.physicsBody?.linearDamping = tuning.linearDamping
    }
}

extension UIColor {
    func modified(hue: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: max(0, min(1, h + hue)), saturation: s, brightness: b, alpha: a)
    }
}
