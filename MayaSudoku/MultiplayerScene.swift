import SpriteKit
import GameKit

class MultiplayerScene: SKScene {
    let gameSession = GameSessionManager.shared
    private var createGameButton: ButtonNode!
    private var joinGameButton: ButtonNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 1.0)

        gameSession.authenticatePlayer { [weak self] success in
            guard let self = self else { return }
            if success {
                self.createGameButton.enable()
                self.joinGameButton.enable()
            } else {
                print("Authentication failed or was canceled.")
            }
        }

        // Add Title Label with Shadow
        let titleLabel = SKLabelNode(text: "Multiplayer")
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

        // Create "Create Game" button with an onTap action
        createGameButton = ButtonNode(text: "Create Game", position: CGPoint(x: screenCenter.x, y: screenCenter.y + 50))
        createGameButton.onTap = { [weak self] in
            self?.createGame()
        }
        if !GKLocalPlayer.local.isAuthenticated {
            createGameButton.disable()
        }
        addChild(createGameButton)

        // Create "Join Game" button with an onTap action
        joinGameButton = ButtonNode(text: "Join Game", position: CGPoint(x: screenCenter.x, y: screenCenter.y - 50))
        joinGameButton.onTap = { [weak self] in
            self?.joinGame()
        }
        if !GKLocalPlayer.local.isAuthenticated {
            joinGameButton.disable()
        }
        addChild(joinGameButton)

        let backButton = ButtonNode(text: "Back", position: CGPoint(x: screenCenter.x, y: size.height * 0.1))
        backButton.onTap = { [weak self] in self?.onBack()}
        addChild(backButton)
    }

    private func onBack() {
        let menu = MainMenuScene(size: self.size)
        menu.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(menu, transition: transition)
    }

    // Create game session
    private func createGame() {
        print("Creating game")

        let gameScene = MultiplayerNewScene(size: self.size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }

    // Join game session
    private func joinGame() {
        print("Joining game")

        let gameScene = MultiplayerJoinScene(size: self.size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
}
