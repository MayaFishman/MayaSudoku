import SpriteKit

class SudokuScene: SKScene {
    
    // Variable to keep track of the currently selected cell
    private var selectedCell: SKShapeNode?
    private var gridSize: CGFloat = 0.0
    private var board: SudokuBoard?
    
    override func didMove(to view: SKView) {
        gridSize = min(size.width, size.height) * 1
        
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
            self.board?.generate(difficulty: SudokuBoard.Difficulty.veryHard)
            
            // Return to the main thread to handle the fade-out and UI update
            DispatchQueue.main.async {
                if let waitingAnimation = self.childNode(withName: "waitingAnimation") {
                    // Create the fade-out and remove actions
                    let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                    let remove = SKAction.removeFromParent()
                    
                    // Sequence that fades out and removes the waiting animation, then draws the board
                    let fadeOutAndRemove = SKAction.sequence([
                        fadeOut,
                        remove,
                        SKAction.run { [weak self] in
                            guard let self = self else { return }
                            // Draw the grid, number cells, and the Sudoku board after fade-out completes
                            self.drawSudokuGrid()
                            self.drawNumberCells()
                            self.drawSudokuBoard()
                        }
                    ])
                    
                    // Run the fade-out and remove sequence
                    waitingAnimation.run(fadeOutAndRemove)
                }
            }
        }
    }

    private func drawSudokuBoardCell(index: Int, value: Int) {
        let row = index / 9
        let col = index % 9
        let cellSize = gridSize / 9.0
        let gridOrigin = CGPoint(x: (size.width - gridSize) / 2, y: (size.height - gridSize) / 2)
        
        // Calculate the position of the cell
        let cellPosition = CGPoint(
            x: gridOrigin.x + CGFloat(col) * cellSize + cellSize / 2,
            y: gridOrigin.y + CGFloat(row) * cellSize + cellSize / 2
        )

        let cell = atPoint(cellPosition)
        
        // If the cell contains a non-zero value, display it
        if value != 0 {
            let numberLabel = SKLabelNode(text: "\(value)")
            numberLabel.fontName = "AvenirNext"
            numberLabel.fontSize = 24
            numberLabel.fontColor = .black
            numberLabel.verticalAlignmentMode = .center
            numberLabel.horizontalAlignmentMode = .center
            numberLabel.position = CGPoint(x:0, y:0)
            numberLabel.zPosition = 2 // Above the cell background
            
            cell.addChild(numberLabel)
        }
    }
    
    
    private func drawSudokuBoard() {
        guard let boardValues = board?.getUnsolved() else { return }
        print(boardValues)
        
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
            let horizontalLine = SKShapeNode(rectOf: CGSize(width: gridSize, height: row % 3 == 0 ? 4 : 1))
            horizontalLine.position = CGPoint(x: size.width / 2, y: linePositionY)
            if row % 3 == 0 {
                horizontalLine.fillColor = row % 3 == 0 ? .black : .gray
                addChild(horizontalLine)
            }
            
            // Vertical line
            let verticalLine = SKShapeNode(rectOf: CGSize(width: row % 3 == 0 ? 4 : 1, height: gridSize))
            verticalLine.position = CGPoint(x: linePositionX, y: size.height / 2)
            if row % 3 == 0 {
                verticalLine.fillColor = row % 3 == 0 ? .black : .gray
                addChild(verticalLine)
            }
        }
        
        // Draw individual cells (for future interactive functionality)
        for row in 0..<9 {
            for col in 0..<9 {
                let cellPosition = CGPoint(x: gridOrigin.x + CGFloat(col) * cellSize + cellSize / 2,
                                           y: gridOrigin.y + CGFloat(row) * cellSize + cellSize / 2)
                
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize - 2, height: cellSize - 2) /*cornerRadius: 4*/)
                cell.position = cellPosition
                cell.strokeColor = .lightGray
                cell.fillColor = .white
                cell.zPosition = 1
                cell.name = "cell_\(row)_\(col)" // Name cells uniquely if interactive functionality is added
                addChild(cell)
            }
        }
    }
    
    private func drawNumberCells() {
        // Size and spacing of the number cells
        let cellSize = gridSize / 9.0
        let gridOrigin = CGPoint(x: (size.width - gridSize) / 2, y: (size.height - gridSize) / 2 + gridSize / 6)
        let bottomOffset = gridOrigin.y - cellSize * 2.5 // Space below the grid for number cells
        
        let startX = (size.width - gridSize) / 2 + cellSize / 2

        // Create number cells from 1 to 9
        for i in 1...9 {
            let numberCell = SKShapeNode(rectOf: CGSize(width: cellSize - 2, height: cellSize - 2), cornerRadius: 4)
            numberCell.position = CGPoint(x: startX + CGFloat(i - 1) * cellSize, y: bottomOffset)
            numberCell.fillColor = SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0)
            numberCell.strokeColor = .gray
            numberCell.zPosition = 1
            numberCell.name = "numberCell_\(i)" // Name for identification

            // Add label with number
            let numberLabel = SKLabelNode(text: "\(i)")
            numberLabel.fontName = "AvenirNext"
            numberLabel.fontSize = 24
            numberLabel.fontColor = .black
            numberLabel.verticalAlignmentMode = .center
            numberLabel.horizontalAlignmentMode = .center
            numberLabel.position = CGPoint(x: 0, y: 0) // Center the label within the cell
            numberCell.addChild(numberLabel)
            
            addChild(numberCell)
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
                    cell.fillColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // Highlight color
                }
            }
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
        guard var boardValues = board?.getUnsolved() else { return }
        guard let solvedValue = board?.getSolved() else { return }
            
        // Traverse up to find the top-level cell node
        while let parentNode = touchedNode.parent, !(touchedNode is SKShapeNode && touchedNode.name?.starts(with: "cell_") == true || touchedNode.name?.starts(with: "numberCell_") == true ) {
            touchedNode = parentNode
        }
        
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
                    if index == -1 {
                        return
                    }
                    
                    if board!.setValue(index: index, val: val) {
                        print("great success!")
                        drawSudokuBoardCell(index: index, value: val)
                    }
                }
            }
        }
    }
}

