import SpriteKit
import UIKit

class PhysicsScene: SKScene {
    var haptics: HapticsManager?
    private var emitter: SKEmitterNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Initial setup for Mercury simulation
        setupMercury()
    }
    
    private func setupMercury() {
        // Create a containment field
        let field = SKFieldNode.radialGravityField()
        field.strength = 1.0
        addChild(field)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Dynamic Haptic Feedback based on speed
        let velocity = touch.previousLocation(in: self).distance(to: location)
        let intensity = min(Float(velocity / 50.0), 1.0)
        
        haptics?.playPattern(named: "mercury_slosh")
        
        // Spawn Mercury globules
        spawnGlobule(at: location)
    }
    
    private func spawnGlobule(at point: CGPoint) {
        let globule = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...15))
        globule.position = point
        globule.fillColor = .lightGray
        globule.strokeColor = .white
        globule.lineWidth = 1
        globule.alpha = 0.8
        
        globule.physicsBody = SKPhysicsBody(circleOfRadius: globule.frame.size.width / 2)
        globule.physicsBody?.restitution = 0.5
        globule.physicsBody?.friction = 0.01
        globule.physicsBody?.linearDamping = 0.1
        
        addChild(globule)
        
        // Auto-cleanup for performance
        globule.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
