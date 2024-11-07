import SpriteKit

class MainMenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 1.0)

        // Add Title Label with Shadow
        let titleLabel = SKLabelNode(text: "Game Menu")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(titleLabel)

        let shadowLabel = titleLabel.copy() as! SKLabelNode
        shadowLabel.position = CGPoint(x: titleLabel.position.x + 3, y: titleLabel.position.y - 3)
        shadowLabel.fontColor = .black.withAlphaComponent(0.3)
        shadowLabel.zPosition = titleLabel.zPosition - 1
        addChild(shadowLabel)

        // Center position for buttons
        let screenCenter = CGPoint(x: size.width / 2, y: size.height / 2)

        // Create "Single Player" button with an onTap action
        let singlePlayerButton = ButtonNode(text: "Single Player", position: CGPoint(x: screenCenter.x, y: screenCenter.y + 50))
        singlePlayerButton.onTap = { [weak self] in
            self?.startSinglePlayerGame()
        }
        addChild(singlePlayerButton)

        // Create "Multi Player" button with an onTap action
        let multiPlayerButton = ButtonNode(text: "Multi Player", position: CGPoint(x: screenCenter.x, y: screenCenter.y - 50))
        multiPlayerButton.onTap = { [weak self] in
            self?.startMultiPlayerGame()
        }
        addChild(multiPlayerButton)
    }

    // Start Single Player Game
    private func startSinglePlayerGame() {
        print("Single Player Game Started!")
        let menu = DifficultyLevelScene(size: self.size)
        menu.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(menu, transition: transition)
    }

    // Start Multi Player Game
    private func startMultiPlayerGame() {
        print("Multi Player Game Started!")
        let multiScene = MultiplayerScene(size: self.size)
        multiScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(multiScene, transition: transition)
    }
}
