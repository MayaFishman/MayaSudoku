import SpriteKit
import GameKit

let CellSelectionColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0)
let CellSelectionErrorColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
let bonusTime = 600 // 10 min

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
    private var cells: [SKShapeNode?] = Array(repeating: nil, count: 81)
    private var playersNode: SKShapeNode!
    private var gridOrigin: CGPoint!
    private var myScore: Int = 0
    private var gameCompleted: Bool = false
    private var isNotes: Bool = false
    private var notes: [Int:[Int]] = [:]
    private var notesButton: TextureButtonNode? = nil
    private var fireworksHost: UIView? = nil
    private var isTimerPaused: Bool = false

    var board: SudokuBoard?
    var isMultiplayer: Bool = false
    var isMultiplayerHost: Bool = false

    deinit {
        timer?.invalidate()
        score.delegate = nil
        score.setComplete()
        fireworksHost?.removeFromSuperview()
        fireworksHost = nil
        if isMultiplayer {
            GameSessionManager.shared.cancelSession()
        }
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        GKAccessPoint.shared.isActive = GKLocalPlayer.local.isAuthenticated
        print("deinit")
    }

    override func didMove(to view: SKView) {
        GKAccessPoint.shared.isActive = false

        NotificationCenter.default.addObserver(self, selector: #selector(pauseTimer), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeTimer), name: UIApplication.didBecomeActiveNotification, object: nil)

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
            gridOrigin.y -= 20
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

        // Calculate constrained left and right positions for labels
        var leftPosition = CGPoint(x: gridOrigin.x + 10, y: gridOrigin.y + gridSize + 20)
        var rightPosition = CGPoint(x: gridOrigin.x + gridSize - 10, y: leftPosition.y)

        timerLabel = SKLabelNode(text: "00:00")
        let difficultyLabel = SKLabelNode(text: "\(self.difficulty.rawValue)")
        scoreLabel =  SKLabelNode(text: "\(score.score)")
        mistakesLabel = SKLabelNode(text:  "0/\(score.maxMistakes)")
        // Define the labels and their initial text
        let labelData = [
            ("Time", timerLabel),
            ("Difficulty", difficultyLabel),
            ("Score",  scoreLabel),
            ("Mistakes", mistakesLabel)
        ]

        // Calculate spacing considering label width
        let sampleLabel = SKLabelNode(text: labelData[0].0)
        sampleLabel.fontName = "AvenirNext-Bold"
        sampleLabel.fontSize = 17
        leftPosition.x += sampleLabel.frame.width/2

        sampleLabel.text = labelData[3].0
        rightPosition.x -= sampleLabel.frame.width/2

        let totalSpacing = (rightPosition.x - leftPosition.x)
        let labelSpacing = totalSpacing / CGFloat(labelData.count - 1)

        for (index, (labelText, valueLabel)) in labelData.enumerated() {
            let label = SKLabelNode(text: labelText)
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 17
            label.fontColor = .black
            label.horizontalAlignmentMode = .center
            label.zPosition = 10

            // Calculate the x position dynamically
            let xPosition = leftPosition.x + CGFloat(index) * labelSpacing
            label.position = CGPoint(x: xPosition, y: leftPosition.y + 30)
            addChild(label)

            // Create and configure the corresponding value label
            valueLabel!.fontName = "AvenirNext-Regular"
            valueLabel!.fontSize = 17
            valueLabel!.fontColor = (labelText == "Mistakes") ? SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0) : .black
            valueLabel!.horizontalAlignmentMode = .center
            valueLabel!.zPosition = 10

            // Position value labels below their respective titles
            valueLabel!.position = CGPoint(x: xPosition, y: leftPosition.y)
            addChild(valueLabel!)
        }


        let bottomColor = UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0)
        let topColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0)
        let bar = createGradientNode(size: CGSize(width: gridSize, height: 80), topColor: topColor, bottomColor: bottomColor)
        bar.position = CGPoint(x:frame.midX, y:60)
        bar.position = CGPoint(x:frame.midX, y:60)
        addChild(bar)

        let buttonSize: CGFloat = 45
        let cellSize = gridSize / 9.0
        let startX = gridOrigin.x + cellSize / 2
        let buttonPositionLeft = CGPoint(x: (gridOrigin.x > 0 ? startX : startX + cellSize/2), y: 60)
        let buttonPositionRight = CGPoint(x: (gridOrigin.x > 0 ? startX + CGFloat(8) * cellSize : startX + CGFloat(8) * cellSize - cellSize/2), y: 60)

        notesButton = TextureButtonNode(size: CGSize(width: buttonSize, height: buttonSize),
                                        unpressed: "notes_black", pressed: "notes_blue",
                                        mode: .toggle)
        notesButton!.position = CGPoint(x: buttonPositionLeft.x, y: buttonPositionLeft.y)
        notesButton!.action = { [weak self] in self?.handleModeButton() }
        addChild(notesButton!)

        let quitButton = TextureButtonNode(size: CGSize(width: buttonSize, height: buttonSize),
                                           unpressed: "exit_black", pressed: "exit_blue")
        quitButton.position = CGPoint(x: buttonPositionRight.x, y: buttonPositionRight.y)
        quitButton.action = { [weak self] in self?.handleQuitButton() }
        addChild(quitButton)

        // Start timer
        startTimer()
        score.start()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    @objc private func updateTimer() {
        elapsedTime += 1
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)

        if isMultiplayer {
            drawMultiplayerScore()
            checkForMultiplayerGameOver()
        }
    }

    private func drawMultiplayerScore() {
        let players = GameSessionManager.shared.sortedPlayersByScore()
        let leftPosition = CGPoint(x: gridOrigin.x + 10, y: gridOrigin.y + gridSize + 50)
        let rightPosition = CGPoint(x: gridOrigin.x + gridSize - 10, y: gridOrigin.y + gridSize + 50)
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
        cell!.removeAllChildren()

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
        } else {
            if let numbers = notes[index] {
                for num in numbers {
                    let noteLabel = SKLabelNode(text: "\(num)")
                    noteLabel.fontName = "AvenirNext-Regular"
                    noteLabel.fontSize = 16
                    noteLabel.fontColor = .gray
                    noteLabel.verticalAlignmentMode = .center
                    noteLabel.horizontalAlignmentMode = .center
                    let x = gridSize / 27.0 * (CGFloat((num-1)%3) - 1)
                    let y = gridSize / 27.0 * (CGFloat((9-num)/3) - 1)
                    noteLabel.position = CGPoint(x: x, y: y)
                    noteLabel.zPosition = 2 // Above the cell background
                    cell!.addChild(noteLabel)
                }
            }
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
        let bottomOffset = gridOrigin.y - 55

        let startX = (size.width - gridSize) / 2 + cellSize / 2

        // Create number cells from 1 to 9
        for i in 1...9 {
            let numberCell = SKShapeNode(rectOf: CGSize(width: cellSize - 3, height: cellSize - 3), cornerRadius: 4)
            numberCell.position = CGPoint(x: startX + CGFloat(i - 1) * cellSize, y: bottomOffset)
            numberCell.zPosition = 1
            numberCell.name = "numberCell_\(i)" // Name for identification

            // Add label with number
            let numberLabel = SKLabelNode(text: "\(i)")
            numberLabel.fontName = "AvenirNext-Regular"
            numberLabel.fontSize = 36
            numberLabel.fontColor = SKColor(red: 0.20, green: 0.4, blue: 0.90, alpha: 1.0)
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
        for cell in cells {
            cell!.fillColor = .white
        }
    }

    func highlightCellsWithVal(val: Int) {
        guard let boardValues = board?.getUnsolved() else { return }
        for cell in cells {
            let index = cellToIndex(cell: cell!)
            if boardValues[index] == val {
                cell!.fillColor = CellSelectionColor
            }
        }
    }
    private func checkIfGameCompleted() {
        if board!.isSolved() {
            score.setComplete(bonus: elapsedTime < bonusTime ? bonusTime - elapsedTime : 0)
            GameSessionManager.shared.reportScore(score.score, forLevel: self.difficulty)
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
                print("unselect cell", cell.name!)
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

                    if isNotes && boardValues[index] == 0 {
                        if var numbers = notes[index], numbers.contains(val) {
                            numbers.removeAll { $0 == val }
                            notes[index] = numbers
                        } else {
                            if var numbers = notes[index] {
                                numbers.append(val)
                                notes[index] = numbers
                            } else {
                                notes[index] = [val]
                            }
                        }
                        drawSudokuBoardCell(index: index, value: 0)
                    } else if board!.setValue(index: index, val: val) {
                        print("great success!")
                        score.addPointsForCorrectPlacement()

                        // remove notes for val
                        for c in SudokuBoard.getCellsToCheck(index: index) {
                            if var numbers = self.notes[c], numbers.contains(val) {
                                numbers.removeAll { $0 == val }
                                self.notes[c] = numbers
                                self.drawSudokuBoardCell(index: c, value: boardValues[c])
                            }
                        }

                        // shake visual effect
                        let cell = selectedCell
                        cell?.zPosition = 3
                        selectedCell = nil
                        print("unselect cell2", cell?.name ?? "")

                        let shake = SKAction.sequence([
                            SKAction.run {
                                self.drawSudokuBoardCell(index: index, value: val)
                                self.highlightCellsWithVal(val: val)
                            },
                            SKAction.scale(to: 1.2, duration: 0.15),
                            SKAction.scale(to: 1.0, duration: 0.15),
                            SKAction.run {
                                cell?.zPosition = 1
                                //self.highlightCellsWithVal(val: val)
                            }]
                        )
                        cell?.run(shake)
                        checkAndRemoveNumbersCells()
                        checkIfGameCompleted()

                    } else {
                        // If incorrect, increment mistakes
                        score.registerMistake()
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
        if isMultiplayer {
            GameSessionManager.shared.disconnect()
        }

        let transition = SKTransition.fade(withDuration: 0.5)
        let mainMenuScene = MainMenuScene(size: self.size)
        self.view?.presentScene(mainMenuScene, transition: transition)
    }

    private func handleModeButton() {
        if gameCompleted {
            return
        }
        isNotes = notesButton?.getState() ?? false
    }

    func scoreDidUpdate(newScore: Int, mistakes: Int, completed: Bool) {
        if gameCompleted {
            return
        }
        myScore = newScore
        gameCompleted = completed

        if mistakes <= score.maxMistakes {
            mistakesLabel.text = "\(mistakes)/\(score.maxMistakes)"
        } else {
            mistakesLabel.text = "\(mistakes)"
        }

        if newScore == 0 {
            scoreLabel.text = "FAIL"
        } else {
            scoreLabel.text = "\(newScore)"
        }

        if isMultiplayer {
            GameSessionManager.shared.sendScore(score: newScore, mistakes: mistakes, isComplete: completed)
        }

        if completed {
            timer?.invalidate()
            notesButton?.disable()
            print("Game Completed!")

            if myScore > 0 {
                createFireworks()
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
            self.score.setComplete(bonus: elapsedTime < bonusTime ? bonusTime - elapsedTime : 0)
            createFireworks()
            showGameOver(won: true)
        }
    }

    func createFireworks(){
        fireworksHost = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        self.view?.addSubview(fireworksHost!)

        let particlesLayer = CAEmitterLayer()
        particlesLayer.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)

        fireworksHost!.layer.addSublayer(particlesLayer)
        fireworksHost!.layer.masksToBounds = true
        fireworksHost!.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)

        particlesLayer.backgroundColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0).cgColor
        particlesLayer.emitterShape = .point
        particlesLayer.emitterPosition = CGPoint(x: size.width/2, y: size.height * 0.8)
        particlesLayer.emitterSize = CGSize(width: 0.0, height: 0.0)
        particlesLayer.emitterMode = .outline
        particlesLayer.renderMode = .additive

        let cell1 = CAEmitterCell()

        cell1.name = "Parent"
        cell1.birthRate = 5.0
        cell1.lifetime = 2.5
        cell1.velocity = 300.0
        cell1.velocityRange = 100.0
        cell1.yAcceleration = -100.0
        cell1.emissionLongitude = -90.0 * (.pi / 180.0)
        cell1.emissionRange = 45.0 * (.pi / 180.0)
        cell1.scale = 0.0
        cell1.color = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor
        cell1.redRange = 0.9
        cell1.greenRange = 0.9
        cell1.blueRange = 0.9

        let image1_1 = UIImage(named: "Spark")?.cgImage

        let subcell1_1 = CAEmitterCell()
        subcell1_1.contents = image1_1
        subcell1_1.name = "Trail"
        subcell1_1.birthRate = 45.0
        subcell1_1.lifetime = 0.5
        subcell1_1.beginTime = 0.01
        subcell1_1.duration = 1.7
        subcell1_1.velocity = 80.0
        subcell1_1.velocityRange = 100.0
        subcell1_1.xAcceleration = 100.0
        subcell1_1.yAcceleration = 350.0
        subcell1_1.emissionLongitude = -360.0 * (.pi / 180.0)
        subcell1_1.emissionRange = 22.5 * (.pi / 180.0)
        subcell1_1.scale = 0.5
        subcell1_1.scaleSpeed = 0.13
        subcell1_1.alphaSpeed = -0.7
        subcell1_1.color = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor

        let image1_2 = UIImage(named: "Spark")?.cgImage

        let subcell1_2 = CAEmitterCell()
        subcell1_2.contents = image1_2
        subcell1_2.name = "Firework"
        subcell1_2.birthRate = 20000.0
        subcell1_2.lifetime = 15.0
        subcell1_2.beginTime = 1.6
        subcell1_2.duration = 0.1
        subcell1_2.velocity = 190.0
        subcell1_2.yAcceleration = 80.0
        subcell1_2.emissionRange = 360.0 * (.pi / 180.0)
        subcell1_2.spin = 114.6 * (.pi / 180.0)
        subcell1_2.scale = 0.1
        subcell1_2.scaleSpeed = 0.09
        subcell1_2.alphaSpeed = -0.7
        subcell1_2.color = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0).cgColor

        cell1.emitterCells = [subcell1_1, subcell1_2]

        particlesLayer.emitterCells = [cell1]
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            self.fireworksHost?.removeFromSuperview()
            self.fireworksHost = nil
        }
    }

    @objc private func pauseTimer() {
        guard timer != nil && !isTimerPaused else { return }
        timer?.invalidate()
        score.pause()
        isTimerPaused = true
    }

    @objc private func resumeTimer() {
        guard isTimerPaused else { return }

        // Restart the timer
        startTimer()
        score.start()
        isTimerPaused = false
    }
}
