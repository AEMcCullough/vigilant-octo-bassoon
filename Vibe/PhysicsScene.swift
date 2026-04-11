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
    
    // Node Capping (Adjustment #3)
    private var materialNodes: [SKNode] = []
    
    // Multi-touch tracking (Adjustment #4)
    private var activeTouches: [UITouch: CGPoint] = [:]
    
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
            haptics?.playImpact(intensity: intensity * tuning.impactPower, sharpness: tuning.hapticSharpness)
            
            if intensity > 0.4 {
                let name = currentMaterial == .glass ? "glass_impact" : (currentMaterial == .mercury ? "mercury_impact" : nil)
                if let sound = name {
                    AudioManager.shared.playSound(named: sound, volume: intensity * 0.3)
                }
            }
        }
    }
    
    // STABLE COHESION & KINETIC AUDIO (Phase 4)
    override func update(_ currentTime: TimeInterval) {
        let tuning = currentMaterial.tuning
        let nodes = currentMaterial == .mercury ? metaballContainer.children : self.children.filter { $0 is SKSpriteNode }
        
        // 1. Mercury Stable Cohesion (Fluid Center-of-Mass Seeking)
        if currentMaterial == .mercury {
            for (index, node) in nodes.enumerated() {
                guard index % 3 == 0 else { continue } // Optimization
                
                let searchRadius = tuning.mergeRadius
                let influenceRect = CGRect(x: node.position.x - searchRadius, 
                                           y: node.position.y - searchRadius, 
                                           width: searchRadius * 2, 
                                           height: searchRadius * 2)
                
                let neighbors = metaballContainer.nodes(in: influenceRect).filter { $0 != node }
                
                if !neighbors.isEmpty {
                    var avgX: CGFloat = 0, avgY: CGFloat = 0
                    for n in neighbors { avgX += n.position.x; avgY += n.position.y }
                    let center = CGPoint(x: avgX / CGFloat(neighbors.count), y: avgY / CGFloat(neighbors.count))
                    
                    let dx = center.x - node.position.x
                    let dy = center.y - node.position.y
                    
                    // Surface tension force toward center of cluster
                    let forceStrength: CGFloat = 8.0
                    node.physicsBody?.applyForce(CGVector(dx: dx * forceStrength, dy: dy * forceStrength))
                }
            }
        }
        
        // 2. Kinetic-Sum Audio Intensity (Phase 5)
        if !activeTouches.isEmpty {
            var totalEnergy: CGFloat = 0
            for node in nodes {
                if let vb = node.physicsBody {
                    totalEnergy += (abs(vb.velocity.dx) + abs(vb.velocity.dy))
                }
            }
            
            let threshold: CGFloat = currentMaterial == .mercury ? 500 : 1200
            let rawIntensity = Float(min(totalEnergy / (threshold * CGFloat(max(1, nodes.count / 10))), 1.0))
            let finalIntensity = rawIntensity * tuning.sloshAudioIntensity
            
            AudioManager.shared.updateLoop(named: tuning.loopName, intensity: finalIntensity)
            
            // Subtle persistent haptic for "Stirring" churn
            if rawIntensity > 0.1 {
                haptics?.playImpact(intensity: rawIntensity * 0.1, sharpness: tuning.hapticSharpness)
            }
        }
    }
    
    func fillSandbox() {
        reset()
        isSandboxMode = true
        let size = self.size
        let tuning = currentMaterial.tuning
        let spacing: CGFloat = tuning.sandboxFillDensity
        
        let cols = Int(size.width / spacing)
        let rows = Int(size.height / spacing) 
        
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
        materialNodes.removeAll()
        addChild(metaballContainer)
        setupContainment()
        isSandboxMode = false
    }
    
    private func setupMotion() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1/60
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let acceleration = data?.acceleration else { return }
            
            let tuning = self.currentMaterial.tuning
            let strength = tuning.tiltSensitivity
            let smoothing = tuning.tiltSmoothing
            
            let targetGravity = CGVector(
                dx: CGFloat(acceleration.x) * strength,
                dy: CGFloat(acceleration.y) * strength
            )
            
            self.lastGravity = CGVector(
                dx: self.lastGravity.dx * (1.0 - smoothing) + targetGravity.dx * smoothing,
                dy: self.lastGravity.dy * (1.0 - smoothing) + targetGravity.dy * smoothing
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
        for touch in touches {
            activeTouches[touch] = touch.location(in: self)
            
            if !isSandboxMode {
                spawnGlobule(at: touch.location(in: self), isTemporary: true)
            }
        }
        handleTouches(touches, isMoving: false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, isMoving: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { activeTouches.removeValue(forKey: touch) }
        if activeTouches.isEmpty {
            AudioManager.shared.updateLoop(named: currentMaterial.tuning.loopName, intensity: 0.0)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { activeTouches.removeValue(forKey: touch) }
        if activeTouches.isEmpty {
            AudioManager.shared.updateLoop(named: currentMaterial.tuning.loopName, intensity: 0.0)
        }
    }
    
    // AREA-OF-INFLUENCE TACTILE MANIPULATION (Phase 3)
    private func handleTouches(_ touches: Set<UITouch>, isMoving: Bool) {
        let tuning = currentMaterial.tuning
        
        for touch in touches {
            let location = touch.location(in: self)
            let previousLocation = activeTouches[touch] ?? location
            let velocity = CGVector(dx: location.x - previousLocation.x, dy: location.y - previousLocation.y)
            let speed = previousLocation.distance(to: location)
            
            activeTouches[touch] = location
            
            if isSandboxMode {
                // Area search instead of point search for "Raking/Stirring" feel
                let radius = tuning.disturbanceRadius
                let searchRect = CGRect(x: location.x - radius, y: location.y - radius, width: radius * 2, height: radius * 2)
                
                // Search both the scene and the metaball container
                let nodesInScene = self.nodes(in: searchRect).filter { $0.physicsBody != nil }
                let nodesInMetaball = metaballContainer.nodes(in: searchRect).filter { $0.physicsBody != nil }
                let affectedNodes = nodesInScene + nodesInMetaball
                
                let multiplier = tuning.sandboxForceMultiplier
                
                for node in affectedNodes {
                    if let pb = node.physicsBody {
                        // Strong velocity injection for direct material displacement
                        let dx = velocity.dx * multiplier
                        let dy = velocity.dy * multiplier
                        
                        // Apply as a combination of impulse and direct velocity for "swatting" feel
                        pb.applyImpulse(CGVector(dx: dx * 0.5, dy: dy * 0.5))
                        pb.velocity = CGVector(dx: pb.velocity.dx + dx * 0.2, dy: pb.velocity.dy + dy * 0.2)
                        
                        // Glass fracturing
                        if currentMaterial == .glass && speed > 20.0 && CGFloat.random(in: 0...1) > 0.90 {
                            spawnGlobule(at: node.position, isTemporary: true)
                            haptics?.playPattern(named: "glass_crack")
                        }
                    }
                }
            } else if isMoving {
                spawnGlobule(at: location, isTemporary: true)
            }
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
        
        materialNodes.append(node)
        cleanupNodes(tuning: tuning)
    }
    
    private func cleanupNodes(tuning: VibeMaterial.Tuning) {
        while materialNodes.count > tuning.nodeCap {
            let oldest = materialNodes.removeFirst()
            oldest.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: tuning.fadeDuration),
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

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

extension UIColor {
    func modified(hue: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: max(0, min(1, h + hue)), saturation: s, brightness: b, alpha: a)
    }
}
