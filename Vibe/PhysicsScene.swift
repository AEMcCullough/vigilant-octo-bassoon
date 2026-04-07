class PhysicsScene: SKScene, SKPhysicsContactDelegate {
    var haptics: HapticsManager?
    @Published var currentMaterial: VibeMaterial = .mercury
    
    private let motionManager = CMMotionManager()
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        setupMotion()
        setupContainment()
        
        NotificationCenter.default.addObserver(forName: .deviceDidShake, object: nil, queue: .main) { [weak self] _ in
            self?.reset()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let velocity = contact.collisionImpulse
        let intensity = min(Float(velocity / 500.0), 1.0)
        
        if intensity > 0.1 {
            haptics?.playImpact(intensity: intensity, sharpness: currentMaterial == .glass ? 0.9 : 0.4)
            AudioManager.shared.playSound(named: currentMaterial.rawValue.lowercased() + "_impact", volume: intensity)
        }
    }
    
    func fillSandbox() {
        let rows = 20
        let cols = 15
        let spacing: CGFloat = 20
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * spacing + 40
                let y = CGFloat(r) * spacing + 100
                spawnGlobule(at: CGPoint(x: x, y: y), isTemporary: false)
            }
        }
    }
    
    private func setupMotion() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1/60
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let acceleration = data?.acceleration else { return }
            let strength: CGFloat = 30.0
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let velocity = touch.previousLocation(in: self).distance(to: location)
        haptics?.playImpact(intensity: Float(min(velocity / 40.0, 1.0)), sharpness: 0.5)
        
        spawnGlobule(at: location, isTemporary: true)
    }
    
    func spawnGlobule(at point: CGPoint, isTemporary: Bool) {
        let radius = currentMaterial == .sand ? CGFloat.random(in: 3...6) : CGFloat.random(in: 8...16)
        let globule = SKShapeNode(circleOfRadius: radius)
        globule.position = point
        
        setupPhysics(for: globule)
        addChild(globule)
        
        if isTemporary {
            globule.run(SKAction.sequence([
                SKAction.wait(forDuration: 4.0),
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
        
        node.strokeColor = .white.withAlphaComponent(0.4)
        node.lineWidth = 0.5
        
        switch currentMaterial {
        case .mercury:
            node.fillColor = .lightGray
            node.physicsBody?.restitution = 0.2
            node.physicsBody?.friction = 0.01
            node.physicsBody?.mass = 0.3
        case .glass:
            node.fillColor = .cyan.withAlphaComponent(0.2)
            node.physicsBody?.restitution = 0.7
            node.physicsBody?.friction = 0.05
            node.physicsBody?.mass = 0.15
        case .sand:
            node.fillColor = .orange.withAlphaComponent(0.6)
            node.physicsBody?.restitution = 0.0
            node.physicsBody?.friction = 0.9
            node.physicsBody?.mass = 0.05
        }
    }
    
    func reset() {
        removeAllChildren()
        setupContainment()
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
