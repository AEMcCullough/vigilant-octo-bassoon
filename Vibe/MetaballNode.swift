import SpriteKit

class MetaballNode: SKEffectNode {
    override init() {
        super.init()
        
        let blur = CIFilter(name: "CIGaussianBlur")!
        blur.setValue(12.0, forKey: kCIInputRadiusKey)
        self.filter = blur
        self.shouldEnableEffects = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
