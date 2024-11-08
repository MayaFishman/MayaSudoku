import SpriteKit

let CellSelectionColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0)
let CellSelectionErrorColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)

class SudokuScene: SKScene {
    public var difficulty: SudokuBoard.Difficulty = SudokuBoard.Difficulty.beginner

    // Variable to keep track of the currently selected cell
    private var selectedCell: SKShapeNode?
    private var gridSize: CGFloat = 0.0
    private var board: SudokuBoard?
    private var timerLabel: SKLabelNode!
    private var mistakesLabel: SKLabelNode!
    private var timer: Timer?
    private var elapsedTime: Int = 0
    private var mistakes: Int = 0
    private var quitButton: SKSpriteNode!
    private var quitLabel: SKLabelNode! // Quit label

    private var cells: [SKNode?] = Array(repeating: nil, count: 81)


    override func didMove(to view: SKView) {
        //gridSize = min(size.width, size.height) * 1
        if UIDevice.current.userInterfaceIdiom == .pad {
            // For iPad, use 85% of the screen width to add padding
            gridSize = min(size.width, size.height) * 0.85
        } else {
            // For iPhone, use the full screen width
            gridSize = min(size.width, size.height) * 1
        }

        // Create a white background node and add it at the lowest zPosition
        let backgroundNode = SKSpriteNode(color: .white, size: self.size)
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -1
        addChild(backgroundNode)

        // Create and add WaitingAnimationNode as an overlay
        let waitingAnimation = WaitingAnimationNode()
        waitingAnimation.position = CGPoint(x: size.width / 2, y: size.height / 2)
        waitingAnimation.name = "waitingAnimation" // Set a name for easy removal
        addChild(waitingAnimation)

        // Generate the Sudoku board asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            self.board = SudokuBoard()
            self.board?.generate(difficulty: self.difficulty)

            // Return to the main thread to handle the fade-out and UI update
            DispatchQueue.main.async {
                if let waitingAnimation = self.childNode(withName: "waitingAnimation") {
                    // Create the fade-out and remove actions
                    let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                    let minimumDisplayTime = SKAction.wait(forDuration: 2.0)
                    let remove = SKAction.removeFromParent()

                    // Sequence that fades out and removes the waiting animation, then draws the board
                    let fadeOutAndRemove = SKAction.sequence([
                        minimumDisplayTime,
                        fadeOut,
                        remove,
                        SKAction.run { [weak self] in
                            guard let self = self else { return }
                            // Draw the grid, number cells, and the Sudoku board after fade-out completes
                            self.drawSudokuGrid()
                            self.drawNumberCells()
                            self.drawSudokuBoard()
                            self.checkAndRemoveNumbersCells()

                            // Calculate positions for the timer and mistakes labels based on screen width
                            let gridOrigin = CGPoint(x: (size.width - gridSize) / 2, y: (size.height - gridSize) / 2)

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

                            // Start timer
                            startTimer()
                        }
                    ])

                    // Run the fade-out and remove sequence
                    waitingAnimation.run(fadeOutAndRemove)
                }
            }
        }
    }
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    @objc private func updateTimer() {
        elapsedTime += 1
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        timerLabel.text = String(format: "Time: %02d:%02d", minutes, seconds)
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
        let gridOrigin = CGPoint(x: (size.width - gridSize) / 2, y: (size.height - gridSize) / 2)

        // Draw grid lines
        for row in 0...9 {
            let linePositionY = gridOrigin.y + CGFloat(row) * cellSize
            let linePositionX = gridOrigin.x + CGFloat(row) * cellSize

            // Horizontal line
            let horizontalLine = SKShapeNode(rectOf: CGSize(width: gridSize, height: row % 3 == 0 ? 2 : 1))
            horizontalLine.position = CGPoint(x: size.width / 2, y: linePositionY)
            if row % 3 == 0 {
                horizontalLine.fillColor = row % 3 == 0 ? .black : .lightGray
                horizontalLine.zPosition = 2
                addChild(horizontalLine)
            }

            // Vertical line
            let verticalLine = SKShapeNode(rectOf: CGSize(width: row % 3 == 0 ? 2 : 1, height: gridSize))
            verticalLine.position = CGPoint(x: linePositionX, y: size.height / 2)
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
        let gridOrigin = CGPoint(x: (size.width - gridSize) / 2, y: (size.height - gridSize) / 2 + gridSize / 6)
        let bottomOffset = gridOrigin.y - cellSize * 3 // Space below the grid for number cells

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
            timer?.invalidate()
            print("Game Completed!")
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
                        mistakes += 1
                        mistakesLabel.text = "Mistakes: \(mistakes)"

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
}

