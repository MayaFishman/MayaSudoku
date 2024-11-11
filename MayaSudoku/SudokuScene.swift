import SpriteKit
import GameKit

let CellSelectionColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0)
let CellSelectionErrorColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)

class SudokuScene: SKScene, ScoreDelegate {
    public var difficulty: SudokuBoard.Difficulty = SudokuBoard.Difficulty.beginner
    let score = Score()

    // Variable to keep track of the currently selected cell
    private var selectedCell: SKShapeNode?
    private var gridSize: CGFloat = 0.0
    private var timerLabel: SKLabelNode!
    private var mistakesLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var timer: Timer?
    private var elapsedTime: Int = 0
    private var quitButton: SKSpriteNode!
    private var quitLabel: SKLabelNode! // Quit label
    private var cells: [SKNode?] = Array(repeating: nil, count: 81)
    private var playersNode: SKShapeNode!
    private var gridOrigin: CGPoint!
    private var myScore: Int = 0
    private var gameCompleted: Bool = false

    var board: SudokuBoard?
    var isMultiplayer: Bool = false
    var isMultiplayerHost: Bool = false

    override func didMove(to view: SKView) {
        // Adjust grid size based on device type
        gridSize = min(size.width, size.height) * (UIDevice.current.userInterfaceIdiom == .pad ? 0.85 : 1)

        // Add a white background node
        let backgroundNode = SKSpriteNode(color: .white, size: self.size)
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -1
        addChild(backgroundNode)

        // Conditionally add waiting animation if multiplayer host
        if !isMultiplayer || isMultiplayerHost {
            let waitingAnimation = WaitingAnimationNode(fontColor: .black)
            waitingAnimation.position = CGPoint(x: size.width / 2, y: size.height / 2)
            waitingAnimation.name = "waitingAnimation"
            addChild(waitingAnimation)
        } else {
            self.setup()
            return
        }

        // Generate Sudoku board asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = Date() // Record start time

            if !self.isMultiplayer || self.isMultiplayerHost {
                self.board = SudokuBoard()
                self.board?.generate(difficulty: self.difficulty)
            }

            // Calculate elapsed time and required wait time
            let elapsedTime = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, 2.0 - elapsedTime) // Ensure at least 2 seconds

            // Update UI on the main thread
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                self.removeWaitingAnimationAndSetup()
            }
        }
    }

    private func removeWaitingAnimationAndSetup() {
        if let waitingAnimation = childNode(withName: "waitingAnimation") {
            let fadeOutAndRemove = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent(),
                SKAction.run { [weak self] in self?.setup() }
            ])
            waitingAnimation.run(fadeOutAndRemove)
        }
    }

    private func setup() {
        gridOrigin = CGPoint(x: (size.width - gridSize) / 2, y: (size.height - gridSize) / 2)
        if isMultiplayer {
            gridOrigin.y -= 50
        }

        myScore = score.score
        if isMultiplayerHost {
            GameSessionManager.shared.startMatch(board: self.board!, initialScore: score.score)
        } else if isMultiplayer {
            GameSessionManager.shared.sendScore(score: score.score, mistakes: score.mistakes, isComplete: false)
        }

        score.delegate = self

        drawSudokuGrid()
        drawNumberCells()
        drawSudokuBoard()
        checkAndRemoveNumbersCells()

        // Calculate left and right positions for the labels
        let leftPosition = CGPoint(x: gridOrigin.x + 10, y: gridOrigin.y + gridSize + 20)
        let rightPosition = CGPoint(x: gridOrigin.x + gridSize - 10, y: gridOrigin.y + gridSize + 20)

        // Initialize and position timer label on the left side of the screen
        timerLabel = SKLabelNode(text: "Time: 00:00")
        timerLabel.fontName = "AvenirNext-Regular"
        timerLabel.fontSize = 20
        timerLabel.fontColor = .blue
        timerLabel.position = leftPosition // Set to left half
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.zPosition = 10
        addChild(timerLabel)

        // Initialize and position mistakes label on the right side of the screen
        mistakesLabel = SKLabelNode(text: "Mistakes: 0")
        mistakesLabel.fontName = "AvenirNext-Regular"
        mistakesLabel.fontSize = 20
        mistakesLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        mistakesLabel.position = rightPosition // Set to right half
        mistakesLabel.horizontalAlignmentMode = .right
        mistakesLabel.zPosition = 10
        addChild(mistakesLabel)

        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 40
        quitButton = SKSpriteNode(color: .magenta, size: CGSize(width: buttonWidth, height: buttonHeight))
        quitButton.position = CGPoint(x: leftPosition.x + buttonWidth / 2, y: leftPosition.y + 50) // Above timer
        if isMultiplayer {
            quitButton.position = CGPoint(x: leftPosition.x + buttonWidth / 2, y: leftPosition.y + 150) // Above timer
        }
        quitButton.zPosition = 10
        quitButton.name = "quitButton" // Name for touch detection
        addChild(quitButton)

        // Quit label setup
        quitLabel = SKLabelNode(text: "Quit")
        quitLabel.fontName = "AvenirNext-Regular"
        quitLabel.fontSize = 20
        quitLabel.fontColor = .white
        quitLabel.verticalAlignmentMode = .center
        quitLabel.horizontalAlignmentMode = .center
        //quitLabel.position = CGPoint(x: 0, y: 0) // Centered within the button
        quitLabel.name = "quitButton"
        quitButton.addChild(quitLabel)

        // Quit label setup
        scoreLabel = SKLabelNode()
        scoreLabel.fontName = "AvenirNext-Regular"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .blue
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.text = "Score: \(score.score)"
        scoreLabel.zPosition = 10
        scoreLabel.position =  CGPoint(x: (rightPosition.x+leftPosition.x)/2, y: rightPosition.y)
        addChild(scoreLabel)

        // Start timer
        startTimer()
        score.start()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    @objc private func updateTimer() {
        elapsedTime += 1
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        timerLabel.text = String(format: "Time: %02d:%02d", minutes, seconds)

        if isMultiplayer {
            drawMultiplayerScore()
            checkForMultiplayerGameOver()
        }
    }

    private func drawMultiplayerScore() {
        let players = GameSessionManager.shared.sortedPlayersByScore()
        let leftPosition = CGPoint(x: gridOrigin.x + 10, y: gridOrigin.y + gridSize + 20)
        let rightPosition = CGPoint(x: gridOrigin.x + gridSize - 10, y: gridOrigin.y + gridSize + 20)
        let playersNodeRect = CGRect(x: leftPosition.x, y: leftPosition.y + 20,
                        width: rightPosition.x - leftPosition.x, height: 110)

        if playersNode == nil {
            playersNode = SKShapeNode(rect: playersNodeRect)
            addChild(playersNode)
        } else {
            playersNode.removeAllChildren()
        }

        let labelFontSize: CGFloat = 20
        let totalAvailableHeight = playersNodeRect.height
        let verticalSpacing = totalAvailableHeight / CGFloat(players.count + 1) // Divide space evenly

        for (index, (player, (score, mistakes, completed))) in players.enumerated() {
            let labelNode = SKLabelNode(text: "\(index + 1). \(player.displayName)")
            labelNode.fontSize = labelFontSize
            labelNode.fontName = "AvenirNext-Regular"
            labelNode.fontColor = player == GKLocalPlayer.local ? .blue : .black
            if completed {
                labelNode.fontColor = .gray
            }
            labelNode.verticalAlignmentMode = .center
            labelNode.horizontalAlignmentMode = .left

            // Calculate y-position for each player, evenly spaced vertically
            let yPosition = playersNodeRect.maxY - verticalSpacing * CGFloat(index + 1)
            labelNode.position = CGPoint(x: playersNodeRect.minX, y: yPosition)

            let scoreLabelNode = SKLabelNode()
            scoreLabelNode.text = score != 0 ? "\(score) / \(mistakes)": "FAIL / \(mistakes)"
            scoreLabelNode.fontSize = 18
            scoreLabelNode.fontName = "AvenirNext-Regular"
            scoreLabelNode.fontColor = .blue
            scoreLabelNode.horizontalAlignmentMode = .right
            scoreLabelNode.verticalAlignmentMode = .center
            scoreLabelNode.position = CGPoint(x: playersNodeRect.maxX, y: yPosition)

            // Add the label node directly to the parent (e.g., the scene)
            playersNode.addChild(labelNode)
            playersNode.addChild(scoreLabelNode)
        }
    }

    private func drawSudokuBoardCell(index: Int, value: Int) {
        let cell = cells[index]

        // If the cell contains a non-zero value, display it
        if value != 0 {
            let numberLabel = SKLabelNode(text: "\(value)")
            numberLabel.fontName = "AvenirNext-Regular"
            numberLabel.fontSize = 32
            numberLabel.fontColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            numberLabel.verticalAlignmentMode = .center
            numberLabel.horizontalAlignmentMode = .center
            numberLabel.position = CGPoint(x:0, y:0)
            numberLabel.zPosition = 2 // Above the cell background

            cell!.addChild(numberLabel)
        }
    }


    private func drawSudokuBoard() {
        guard let boardValues = board?.getUnsolved() else { return }

        for (index, value) in boardValues.enumerated() {
            drawSudokuBoardCell(index: index, value: value)
        }
    }


    private func drawSudokuGrid() {
        // Size and position of the grid
        let cellSize = gridSize / 9.0

        // Draw grid lines
        for row in 0...9 {
            let linePositionY = gridOrigin.y + CGFloat(row) * cellSize
            let linePositionX = gridOrigin.x + CGFloat(row) * cellSize

            // Horizontal line
            let horizontalLine = SKShapeNode(rectOf: CGSize(width: gridSize, height: row % 3 == 0 ? 2 : 1))
            horizontalLine.position = CGPoint(x: gridOrigin.x + gridSize / 2, y: linePositionY)
            if row % 3 == 0 {
                horizontalLine.fillColor = row % 3 == 0 ? .black : .lightGray
                horizontalLine.zPosition = 2
                addChild(horizontalLine)
            }

            // Vertical line
            let verticalLine = SKShapeNode(rectOf: CGSize(width: row % 3 == 0 ? 2 : 1, height: gridSize))
            verticalLine.position = CGPoint(x: linePositionX, y: gridOrigin.y + gridSize / 2)
            if row % 3 == 0 {
                verticalLine.fillColor = row % 3 == 0 ? .black : .lightGray
                verticalLine.zPosition = 2
                addChild(verticalLine)
            }
        }

        // Draw individual cells (for future interactive functionality)
        for row in 0..<9 {
            for col in 0..<9 {
                let cellPosition = CGPoint(x: gridOrigin.x + CGFloat(col) * cellSize + cellSize / 2,
                                           y: gridOrigin.y + CGFloat(row) * cellSize + cellSize / 2)

                let cell = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize) /*cornerRadius: 4*/)
                cell.position = cellPosition
                cell.strokeColor = .lightGray
                cell.fillColor = .white
                cell.zPosition = 1
                cell.name = "cell_\(row)_\(col)" // Name cells uniquely if interactive functionality is added
                addChild(cell)
                cells[row * 9 + col] = cell
            }
        }
    }

    private func drawNumberCells() {
        // Size and spacing of the number cells
        let cellSize = gridSize / 9.0
        let bottomOffset = gridOrigin.y / 2 // Space below the grid for number cells

        let startX = (size.width - gridSize) / 2 + cellSize / 2

        // Create number cells from 1 to 9
        for i in 1...9 {
            let numberCell = SKShapeNode(rectOf: CGSize(width: cellSize - 3, height: cellSize - 3), cornerRadius: 4)
            numberCell.position = CGPoint(x: startX + CGFloat(i - 1) * cellSize, y: bottomOffset)
            numberCell.fillColor = SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0)
            numberCell.strokeColor = .gray
            numberCell.zPosition = 1
            numberCell.name = "numberCell_\(i)" // Name for identification

            // Add label with number
            let numberLabel = SKLabelNode(text: "\(i)")
            numberLabel.fontName = "AvenirNext-Regular"
            numberLabel.fontSize = 32
            numberLabel.fontColor = .black
            numberLabel.verticalAlignmentMode = .center
            numberLabel.horizontalAlignmentMode = .center
            numberLabel.position = CGPoint(x: 0, y: 0) // Center the label within the cell
            numberCell.addChild(numberLabel)

            addChild(numberCell)
        }
    }

    func removeNumberCell(i: Int) {
        for child in children {
            if let cell = child as? SKShapeNode, cell.name?.starts(with: "numberCell_\(i)") == true {
                removeChildren(in: [cell])
                break
            }
        }
    }

    func checkAndRemoveNumbersCells() {
        for i in [1,2,3,4,5,6,7,8,9] {
            if ((board!.isSolvedForVal(val: i))) {
                removeNumberCell(i: i)
            }
        }
    }

    func clearCells() {
        // Clear any previous highlights
        for child in children {
            if let cell = child as? SKShapeNode, cell.name?.starts(with: "cell_") == true {
                cell.fillColor = .white // Reset color to default
            }
        }
    }

    func highlightCellsWithVal(val: Int) {
        // Highlight cells with the specified value
        for child in children {
            if let cell = child as? SKShapeNode, cell.name?.starts(with: "cell_") == true {
                // Check if the cell contains the specified value
                if let label = cell.children.first as? SKLabelNode, label.text == "\(val)" {
                    cell.fillColor = CellSelectionColor
                }
            }
        }
    }
    private func checkIfGameCompleted() {
        if board!.isSolved() {
            score.setComplete()
        }
    }

    func cellToIndex(cell: SKShapeNode) -> Int {
        let parts = cell.name!.components(separatedBy: "_")
        if parts.count == 3, let row = Int(parts[1]), let col = Int(parts[2]) {
            return row * 9 + col
        }
        return -1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let location = touch.location(in: self)
        var touchedNode = atPoint(location)

        if touchedNode.name == "quitButton" {
            handleQuitButton()
            return
        }

        if gameCompleted {
            return
        }

        // Traverse up to find the top-level cell node
        while let parentNode = touchedNode.parent, !(touchedNode is SKShapeNode && touchedNode.name?.starts(with: "cell_") == true || touchedNode.name?.starts(with: "numberCell_") == true ) {
            touchedNode = parentNode
        }

        guard let boardValues = board?.getUnsolved() else { return }

        // Check if the touched node is a cell
        if let cell = touchedNode as? SKShapeNode, cell.name?.starts(with: "cell_") == true {

            clearCells()

            let index = cellToIndex(cell: cell)
            if index == -1 {
                return
            }
            if boardValues[index] == 0 {
                // Select the new cell and change its color to blue
                cell.fillColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // Light pastel blue color
                selectedCell = cell
                print(cell.name!)
            } else {
                selectedCell = nil
                highlightCellsWithVal(val: boardValues[index])
            }
        }

        if let cell = touchedNode as? SKShapeNode, let name = cell.name, name.starts(with: "numberCell_") {
            print(name)
            let parts = cell.name!.components(separatedBy: "_")
            if parts.count == 2, let val = Int(parts[1]) {
                if selectedCell != nil {
                    let index = cellToIndex(cell: selectedCell!)
                    if index == -1 || boardValues[index] != 0 {
                        return
                    }

                    if board!.setValue(index: index, val: val) {
                        print("great success!")
                        score.addPointsForCorrectPlacement()

                        // shake visual effect
                        selectedCell?.zPosition = 3
                        let shake = SKAction.sequence([
                            SKAction.run {
                                self.drawSudokuBoardCell(index: index, value: val)
                                self.highlightCellsWithVal(val: val)
                            },
                            SKAction.scale(to: 1.2, duration: 0.15),
                            SKAction.scale(to: 1.0, duration: 0.15),
                            SKAction.run {
                                self.selectedCell?.zPosition = 1
                                self.selectedCell = nil
                                //self.highlightCellsWithVal(val: val)
                            }]
                        )
                        selectedCell?.run(shake)
                        checkAndRemoveNumbersCells()
                        checkIfGameCompleted()

                    } else {
                        // If incorrect, increment mistakes
                        score.registerMistake()
                        mistakesLabel.text = "Mistakes: \(score.mistakes)"
                        checkIfGameCompleted()

                        // shake visual effect
                        selectedCell?.fillColor = CellSelectionErrorColor
                        selectedCell?.zPosition = 3
                        let shake = SKAction.sequence([
                            SKAction.scale(to: 1.1, duration: 0.15),
                            SKAction.scale(to: 1.0, duration: 0.15),
                            SKAction.run {
                                self.selectedCell?.fillColor = CellSelectionColor
                                self.selectedCell?.zPosition = 1
                            }
                        ])
                        selectedCell?.run(shake)

                    }
                }
            }
        }
    }

    private func handleQuitButton() {
        // Logic to handle quit action, e.g., transitioning to a main menu scene
        print("Quit button pressed.")

        let transition = SKTransition.fade(withDuration: 0.5)
        let mainMenuScene = MainMenuScene(size: self.size)
        self.view?.presentScene(mainMenuScene, transition: transition)
    }

    func scoreDidUpdate(newScore: Int, mistakes: Int, completed: Bool) {
        if gameCompleted {
            return
        }
        myScore = newScore
        gameCompleted = completed

        if newScore == 0 {
            scoreLabel.text = "Score: FAIL"
        } else {
            scoreLabel.text = "Score: \(newScore)"
        }

        if isMultiplayer {
            GameSessionManager.shared.sendScore(score: newScore, mistakes: mistakes, isComplete: completed)
        }

        if completed {
            timer?.invalidate()
            print("Game Completed!")

            if myScore > 0 {
                showGameOver(won: true)
            } else {
                showGameOver(won: false)
            }
        }
    }

    private func showGameOver(won: Bool) {
        if won {
            let alert = UIAlertController(title: "Game Over", message: "You won", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default))

            if let viewController = view?.window?.rootViewController {
                viewController.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Game Over", message: "You lost", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default))

            if let viewController = view?.window?.rootViewController {
                viewController.present(alert, animated: true, completion: nil)
            }
        }
    }

    func checkForMultiplayerGameOver() {
        if gameCompleted == true {
            return
        }
        let players = GameSessionManager.shared.sortedPlayersByScore()
        if players.count != GameSessionManager.shared.matchPlayers.count {
            return
        }

        var active = 0
        for (_, (player, (score, _, completed))) in players.enumerated() {
            if completed && player != GKLocalPlayer.local && score > 0 {
                // lost
                gameCompleted = true
                self.score.setComplete()
                showGameOver(won: false)
                break
            }
            if !completed && player != GKLocalPlayer.local {
                active += 1
            }
        }

        if !gameCompleted && active == 0 {
            // i'm the last standing player
            gameCompleted = true
            self.score.setComplete()
            showGameOver(won: true)
        }
    }
}
