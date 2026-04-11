import SpriteKit

class MetaballNode: SKEffectNode {
    override init() {
        super.init()
        
        // Massive blur for high-fidelity liquid fusion
        let blur = CIFilter(name: "CIGaussianBlur")!
        blur.setValue(25.0, forKey: kCIInputRadiusKey)
        self.filter = blur
        self.shouldEnableEffects = true
        
        let shader = SKShader(fileNamed: "Metaball.fsh")
        self.shader = shader
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
