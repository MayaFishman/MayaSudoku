import SpriteKit

class TextureButtonNode: SKSpriteNode {
    var unpressedTexture: SKTexture
    var pressedTexture: SKTexture
    var action: (() -> Void)?

    enum ButtonState {
        case unpressed
        case pressed
    }

    enum ButtonMode {
        case regular
        case toggle
    }

    var mode: ButtonMode
    private var currentState: ButtonState = .unpressed

    // Initialize with size and mode
    init(size: CGSize, unpressed: String, pressed: String, mode: ButtonMode = .regular) {
        self.unpressedTexture = SKTexture(imageNamed: unpressed)
        self.pressedTexture = SKTexture(imageNamed: pressed)
        self.mode = mode

        super.init(texture: unpressedTexture, color: .clear, size: size)

        self.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Method to change the button state
    func setState(_ state: ButtonState) {
        self.currentState = state
        switch state {
        case .unpressed:
            self.texture = unpressedTexture
        case .pressed:
            self.texture = pressedTexture
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode == .regular {
            setState(.pressed)
        } else if mode == .toggle {
            // Toggle between pressed and unpressed states
            let newState: ButtonState = (currentState == .pressed) ? .unpressed : .pressed
            setState(newState)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode == .regular {
            setState(.unpressed)
        }

        // Trigger the action if touch ends within button bounds
        if let touch = touches.first, self.contains(touch.location(in: self.parent!)) {
            action?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode == .regular {
            setState(.unpressed)
        }
    }
}
