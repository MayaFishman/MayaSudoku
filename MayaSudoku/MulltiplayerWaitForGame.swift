import SpriteKit
import GameKit

class MultiplayerWaitForHostScene: SKScene {
    private var cancelButton: SKLabelNode!
    private var animationLayer: WaitingAnimationNode!
    var partyCode: String?
    private var statusLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        NotificationCenter.default.addObserver(self, selector: #selector(handleConnectedPlayersChanged(notification:)), name: .connectedPlayersDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleGameStarted(notification:)), name: .gameStarted, object: nil)

        backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 1.0)

        statusLabel = SKLabelNode(text: "Looking for the match")
        statusLabel.fontName = "AvenirNext-Regular"
        statusLabel.fontSize = 26
        statusLabel.fontColor = .white
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(statusLabel)

        // Set up the "Cancel" button
        let cancelButton = ButtonNode(text: "Cancel", position: CGPoint(x: size.width / 2, y: size.height * 0.2))
        cancelButton.onTap = { [weak self] in
            self?.cancelAction()
        }
        addChild(cancelButton)

        // Set up the animation layer with WaitingAnimationNode
        animationLayer =  WaitingAnimationNode(fontColor: .white)
        animationLayer.position = CGPoint(x: size.width / 2, y: size.height / 2) // Center of the screen
        addChild(animationLayer)

        GameSessionManager.shared.joinGameSession(with: partyCode!) { result in
            switch result {
            case .success(let partyCode):
                print("Successfully created game with party code: \(partyCode)")
                // Proceed to next steps, such as presenting the game scene
            case .failure(let error):
                print("Failed to create game session: \(error.localizedDescription)")
                self.showErrorAndClose(message: error.localizedDescription)
            }
        }
    }

    // Detect touches for the Cancel button
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)

        if touchedNode.name == "cancelButton" {
            // Handle the cancel action
            cancelAction()
        }
    }

    // Action to perform when "Cancel" is pressed
    private func cancelAction() {
        GameSessionManager.shared.cancelSession()

        print("Cancel button pressed. Returning to previous scene.")
        // Transition back to the previous scene (e.g., main menu)
        let mainMenuScene = MainMenuScene(size: self.size)
        mainMenuScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenuScene, transition: transition)
    }

    private func showErrorAndClose(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
            self?.cancelAction()
        })

        if let viewController = view?.window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    @objc private func handleConnectedPlayersChanged(notification: Notification) {
        let connectedPlayers = notification.userInfo?["connectedPlayers"] as? [GKPlayer]
        if connectedPlayers?.count ?? 0 > 0 {
            statusLabel.text = "Waiting for the host to start"
        } else {
            statusLabel.text = "Looking for the match"
        }
    }

    @objc private func handleGameStarted(notification: Notification) {
        let board = SudokuBoard(solvedBoard: (notification.userInfo?["solvedBoard"] as? [Int])!,
                                unsolvedBoard: (notification.userInfo?["unsolvedBoard"] as? [Int])!)

        let sudokuScene = SudokuScene(size: self.size)
        sudokuScene.scaleMode = .aspectFill
        sudokuScene.difficulty = SudokuBoard.Difficulty.veryHard
        sudokuScene.isMultiplayer = true
        sudokuScene.isMultiplayerHost = false
        sudokuScene.board = board
        sudokuScene.score.setInitialScore(score: (notification.userInfo?["initialScore"] as? Int)!)
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(sudokuScene, transition: transition)
    }
}
