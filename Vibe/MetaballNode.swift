import SpriteKit

class MetaballNode: SKEffectNode {
    override init() {
        super.init()
        
        // Blur creates the "fusion" area
        let blur = CIFilter(name: "CIGaussianBlur")!
        blur.setValue(12.0, forKey: kCIInputRadiusKey)
        self.filter = blur
        self.shouldEnableEffects = true
        
        // Shader handles the "Thresholding" and "Metallic shading"
        let shader = SKShader(fileNamed: "Metaball.fsh")
        self.shader = shader
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
