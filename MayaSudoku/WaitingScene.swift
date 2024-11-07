import SpriteKit

class WaitingAnimationNode: SKNode {
    private var crunchLabel: SKLabelNode!
    private var fontColor: UIColor = .black

    convenience init(fontColor: UIColor = .black) {
        self.init()
        self.fontColor = fontColor

        // Set up the label
        crunchLabel = SKLabelNode(fontNamed: "Courier-Bold")
        crunchLabel.fontSize = 50
        crunchLabel.position = CGPoint(x: 0, y: 0)
        crunchLabel.fontColor = fontColor
        addChild(crunchLabel)

        // Start the crunching animation
        startCrunchingAnimation()
    }

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startCrunchingAnimation() {
        let crunchAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.crunchLabel.text = self.generateRandomNumberString()
                },
                SKAction.wait(forDuration: 0.1)
            ])
        )
        crunchLabel.run(crunchAction)
    }

    private func generateRandomNumberString() -> String {
        var randomString = ""
        for _ in 1...10 {
            randomString += "\(Int.random(in: 0...9))"
        }
        return randomString
    }
}
