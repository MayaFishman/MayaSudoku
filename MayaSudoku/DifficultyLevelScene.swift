import SpriteKit

class DifficultyLevelScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 1.0)

        // Add Title Label with Shadow
        let titleLabel = SKLabelNode(text: "Difficulty")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        addChild(titleLabel)

        let shadowLabel = titleLabel.copy() as! SKLabelNode
        shadowLabel.position = CGPoint(x: titleLabel.position.x + 3, y: titleLabel.position.y - 3)
        shadowLabel.fontColor = .black.withAlphaComponent(0.3)
        shadowLabel.zPosition = titleLabel.zPosition - 1
        addChild(shadowLabel)

        // Center position for buttons
        let screenCenter = CGPoint(x: size.width / 2, y: size.height / 2)

        // Create difficulty buttons
        createDifficultyButton(text: "Easy", position: CGPoint(x: screenCenter.x, y: screenCenter.y + 150), difficulty: .beginner)
        createDifficultyButton(text: "Medium", position: CGPoint(x: screenCenter.x, y: screenCenter.y + 50), difficulty: .intermediate)
        createDifficultyButton(text: "Hard", position: CGPoint(x: screenCenter.x, y: screenCenter.y - 50), difficulty: .hard)
        createDifficultyButton(text: "Very Hard", position: CGPoint(x: screenCenter.x, y: screenCenter.y - 150), difficulty: .veryHard)

        let backButton = ButtonNode(text: "Back", position: CGPoint(x: screenCenter.x, y: size.height * 0.1))
        backButton.onTap = { [weak self] in self?.onBack()}
        addChild(backButton)
    }

    private func createDifficultyButton(text: String, position: CGPoint, difficulty: SudokuBoard.Difficulty) {
        let button = ButtonNode(text: text, position: position)
        button.onTap = { [weak self] in
            self?.startSinglePlayerGame(difficulty: difficulty)
        }
        addChild(button)
    }

    private func onBack() {
        let menu = MainMenuScene(size: self.size)
        menu.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(menu, transition: transition)
    }

    // Start Single Player Game with selected difficulty
    private func startSinglePlayerGame(difficulty: SudokuBoard.Difficulty) {
        print("Single Player Game Started!")
        let sudokuScene = SudokuScene(size: self.size)
        sudokuScene.scaleMode = .aspectFill
        sudokuScene.difficulty = difficulty
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(sudokuScene, transition: transition)
    }
}
