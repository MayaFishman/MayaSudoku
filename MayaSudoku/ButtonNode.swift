import SpriteKit

class ButtonNode: SKShapeNode {
    private let shadowNode: SKShapeNode
    private var label: SKLabelNode!

    // Closure to handle button tap action
    var onTap: (() -> Void)?

    // Property to track whether the button is enabled
    private(set) var isEnabled: Bool = true {
        didSet {
            updateAppearanceForState()
        }
    }

    init(text: String, position: CGPoint, buttonSize: CGSize = CGSize(width: 240, height: 70)) {
        // Initialize shadow node
        shadowNode = SKShapeNode(rectOf: buttonSize, cornerRadius: 15)
        shadowNode.position = CGPoint(x: 3, y: -3) // Slight offset for shadow within the button
        shadowNode.fillColor = .black.withAlphaComponent(0.3)
        shadowNode.zPosition = -1

        // Initialize main button
        super.init()
        self.path = CGPath(roundedRect: CGRect(origin: CGPoint(x: -buttonSize.width / 2, y: -buttonSize.height / 2), size: buttonSize), cornerWidth: 15, cornerHeight: 15, transform: nil)
        self.position = position
        self.fillColor = SKColor(red: 0.25, green: 0.5, blue: 0.85, alpha: 1.0)
        self.strokeColor = .clear
        self.glowWidth = 3.0
        self.zPosition = 1

        // Add shadow as a child to ensure alignment
        addChild(shadowNode)

        // Initialize label
        label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 26
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint.zero
        label.zPosition = 2

        addChild(label)
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Method to enable the button
    func enable() {
        isEnabled = true
    }

    // Method to disable the button
    func disable() {
        isEnabled = false
    }

    // Update the appearance based on the button's enabled state
    private func updateAppearanceForState() {
        if isEnabled {
            fillColor = SKColor(red: 0.25, green: 0.5, blue: 0.85, alpha: 1.0)
            label.fontColor = .white
        } else {
            fillColor = SKColor(red: 0.25, green: 0.5, blue: 0.85, alpha: 0.5) // Dimmed color for disabled state
            label.fontColor = .gray
        }
    }

    func setHighlighted(_ highlighted: Bool) {
        if isEnabled {
            fillColor = highlighted ? SKColor(red: 0.2, green: 0.45, blue: 0.75, alpha: 1.0) : SKColor(red: 0.25, green: 0.5, blue: 0.85, alpha: 1.0)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else { return }

        setHighlighted(true)

        let buttonMoveDown = SKAction.moveBy(x: 2, y: -2, duration: 0.1)
        let buttonPressAnimation = SKAction.group([buttonMoveDown])
        self.run(buttonPressAnimation)

        // Shadow: Move up to simulate depth
        let shadowMoveUp = SKAction.moveBy(x: -2, y: 2, duration: 0.1)
        shadowNode.run(shadowMoveUp)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled else { return }
        setHighlighted(false)

        // Button: Move back up and scale back to original size
        let buttonMoveUp = SKAction.moveBy(x: -2, y: 2, duration: 0.1)
        let buttonReleaseAnimation = SKAction.group([buttonMoveUp])
        self.run(buttonReleaseAnimation)

        // Shadow: Move back down to original position
        let shadowMoveDown = SKAction.moveBy(x: 2, y: -2, duration: 0.1)
        shadowNode.run(shadowMoveDown) {[weak self] in
            self?.onTap?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setHighlighted(false)
    }
}
