import SpriteKit
import GameKit

class MultiplayerNewScene: SKScene {
    private var playerNames: [String] = [GKLocalPlayer.local.displayName]
    private var playerSlots: [SKShapeNode] = [] // Store player labels for redrawing
    private let gameSession = GameSessionManager.shared
    private var partyCode: String = ""
    private var partyCodeValueLabel: SKLabelNode! = nil
    private var startButton: ButtonNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 1.0)

        let partyCode = String(format: "%04d", Int.random(in: 1000...9999))
        gameSession.hostGameSession(code: partyCode) { result in
            switch result {
            case .success(_):
                print("Successfully created game with party code: \(partyCode)")
                // Proceed to next steps, such as presenting the game scene
            case .failure(let error):
                print("Failed to create game session: \(error.localizedDescription)")
                self.showErrorAndClose(message: error.localizedDescription)
            }
        }

        // Title
        let titleLabel = SKLabelNode(text: "Players")
        titleLabel.fontName = "AvenirNext-Regular"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        addChild(titleLabel)

        // Party Code Label ("Party Code:" in white)
        let partyCodeTextLabel = SKLabelNode(text: "Party Code:")
        partyCodeTextLabel.fontName = "AvenirNext-Regular"
        partyCodeTextLabel.fontSize = 32
        partyCodeTextLabel.fontColor = .white
        partyCodeTextLabel.position = CGPoint(x: size.width / 2 - 10, y: titleLabel.position.y - 80)
        partyCodeTextLabel.horizontalAlignmentMode = .right

        // Party Code Value (actual code in yellow)
        partyCodeValueLabel = SKLabelNode(text: partyCode)
        partyCodeValueLabel.fontName = "AvenirNext-Regular"
        partyCodeValueLabel.fontSize = 32
        partyCodeValueLabel.fontColor = SKColor(red: 0.85, green: 0.85, blue: 0.3, alpha: 1.0) // Yellow color for code
        partyCodeValueLabel.position = CGPoint(x: size.width / 2 + 10, y: partyCodeTextLabel.position.y)
        partyCodeValueLabel.horizontalAlignmentMode = .left

        // Calculate total width of both labels
        let combinedWidth = partyCodeTextLabel.frame.width + 20 + partyCodeValueLabel.frame.width
        // Calculate starting position to center both labels together
        let startX = (size.width - combinedWidth) / 2
        // Position labels relative to startX to center the group horizontally
        partyCodeTextLabel.position = CGPoint(x: startX + partyCodeTextLabel.frame.width, y: titleLabel.position.y - 80)
        partyCodeValueLabel.position = CGPoint(x: startX + partyCodeTextLabel.frame.width + 20, y: partyCodeTextLabel.position.y)

        addChild(partyCodeTextLabel)
        addChild(partyCodeValueLabel)

        drawPlayerPlaceholders()

        // Back Button at the bottom of the screen
        let backButton = ButtonNode(text: "Back", position: CGPoint(x: size.width / 2, y: size.height * 0.2))
        backButton.onTap = { [weak self] in
            self?.goBack()
        }
        addChild(backButton)

        // Start Button positioned below the player list
        startButton = ButtonNode(text: "Start", position: CGPoint(x: size.width / 2, y: size.height * 0.75 - 350))
        startButton.onTap = { [weak self] in
            self?.startGame()
        }
        addChild(startButton)
        startButton.disable()
        updatePlayerList()

        NotificationCenter.default.addObserver(self, selector: #selector(handleConnectedPlayersChanged(notification:)), name: .connectedPlayersDidChange, object: nil)
    }

    @objc private func handleConnectedPlayersChanged(notification: Notification) {
        playerNames.removeAll()
        playerNames.append(GKLocalPlayer.local.displayName)
        if let connectedPlayers = notification.userInfo?["connectedPlayers"] as? [GKPlayer] {
            print("Updated connected players: \(connectedPlayers.map { $0.displayName })")
            // Update UI with the new list of players
            for player in connectedPlayers {
                playerNames.append(player.displayName)
            }
        }
        DispatchQueue.main.async {
            self.updatePlayerList()
        }
    }

    // Function to draw 4 placeholder slots for players
    private func drawPlayerPlaceholders() {
        for i in 0..<4 {
            let placeholderSlot = SKShapeNode(rectOf: CGSize(width: 300, height: 40), cornerRadius: 10)
            placeholderSlot.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // Gray color for vacant slots
            placeholderSlot.strokeColor = .clear
            placeholderSlot.position = CGPoint(x: size.width / 2, y: size.height * 0.75 - 100 - CGFloat(i * 50))
            placeholderSlot.zPosition = 1
            addChild(placeholderSlot)
            playerSlots.append(placeholderSlot)
        }
    }

    func createThreeDotsLoadingAnimation() -> SKNode {
        let loadingNode = SKNode()
        let dotRadius: CGFloat = 3.0
        let dotSpacing: CGFloat = 18.0
        let scaleUp = 1.4
        let scaleDown = 0.6
        let animationDuration = 0.8

        // Create 3 dots with independent scaling animations, centered around (0, 0)
        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = .white
            dot.position = CGPoint(x: CGFloat(i - 1) * dotSpacing, y: 0) // Center the dots around (0, 0)
            loadingNode.addChild(dot)

            // Create the scaling animation
            let scaleUpAction = SKAction.scale(to: scaleUp, duration: animationDuration)
            let scaleDownAction = SKAction.scale(to: scaleDown, duration: animationDuration)
            let scaleSequence = SKAction.sequence([scaleUpAction, scaleDownAction])

            // Repeat the scaling sequence forever with a delay for each dot
            let initialDelay = SKAction.wait(forDuration: 0.4 * Double(i))
            let delayedScale = SKAction.sequence([initialDelay, SKAction.repeatForever(scaleSequence)])
            dot.run(delayedScale)
        }

        return loadingNode
    }

    private func updatePlayerList() {
        // Clear previous player names
        playerSlots.forEach { $0.removeAllChildren() }

        for i in 0..<playerNames.count {
            // Add player name label if slot is occupied
            let playerNameLabel = SKLabelNode(text: playerNames[i])
            playerNameLabel.fontName = "AvenirNext-Regular"
            playerNameLabel.fontSize = 20
            playerNameLabel.fontColor = .white
            playerNameLabel.position = CGPoint(x: 0, y: 0) // Centered in the slot
            playerNameLabel.verticalAlignmentMode = .center
            playerSlots[i].addChild(playerNameLabel)
        }

        for i in playerNames.count..<4 {
            let rotatingDots = createThreeDotsLoadingAnimation()
            rotatingDots.position = CGPoint(x: 0, y: 0)
            playerSlots[i].addChild(rotatingDots)
        }

        if playerNames.count < 2 {
            startButton.disable()
        } else {
            startButton.enable()
        }
    }

    // Simulate a player joining for demonstration purposes
    func addPlayer(name: String) {
        guard playerNames.count < 4 else { return }
        playerNames.append(name)
        updatePlayerList()
    }

    private func goBack() {
        gameSession.cancelSession()
        let mainMenuScene = MainMenuScene(size: self.size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenuScene, transition: transition)
    }

    private func startGame() {
        // Code to start the game; replace with actual game start logic
        print("Game Started!")

        let sudokuScene = SudokuScene(size: self.size)
        sudokuScene.scaleMode = .aspectFill
        sudokuScene.difficulty = SudokuBoard.Difficulty.veryHard
        sudokuScene.isMultiplayer = true
        sudokuScene.isMultiplayerHost = true
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(sudokuScene, transition: transition)
    }

    private func returnToPreviousScene() {
        gameSession.cancelSession()
        // Transition back to the main menu or previous scene
        let mainMenuScene = MainMenuScene(size: self.size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenuScene, transition: transition)
    }

    private func showErrorAndClose(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
            self?.returnToPreviousScene()
        })

        if let viewController = view?.window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
