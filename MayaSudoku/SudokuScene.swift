import SpriteKit

class SudokuScene: SKScene {
    
    // Variable to keep track of the currently selected cell
    private var selectedCell: SKShapeNode?
    private var gridSize: CGFloat = 0.0
    private var board: SudokuBoard?
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        gridSize = min(size.width, size.height) * 1
        board = SudokuBoard()
        board?.generate(difficulty: SudokuBoard.Difficulty.veryHard)
        
        drawSudokuGrid()
        drawNumberCells()
        drawSudokuBoard()
    }
    
    private func drawSudokuBoard() {
        guard let boardValues = board?.getUnsolved() else { return }
        
        let cellSize = gridSize / 9.0
        let gridOrigin = CGPoint(x: (size.width - gridSize) / 2, y: (size.height - gridSize) / 2)
        
        for (index, value) in boardValues.enumerated() {
            let row = index / 9
            let col = index % 9
            
            // Calculate the position of the cell
            let cellPosition = CGPoint(
                x: gridOrigin.x + CGFloat(col) * cellSize + cellSize / 2,
                y: gridOrigin.y + CGFloat(row) * cellSize + cellSize / 2
            )
            
            // If the cell contains a non-zero value, display it
            if value != 0 {
                let numberLabel = SKLabelNode(text: "\(value)")
                numberLabel.fontName = "AvenirNext-Bold"
                numberLabel.fontSize = 24
                numberLabel.fontColor = .black
                numberLabel.verticalAlignmentMode = .center
                numberLabel.horizontalAlignmentMode = .center
                numberLabel.position = cellPosition
                numberLabel.zPosition = 2 // Above the cell background
                
                addChild(numberLabel)
            }
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
            numberLabel.fontName = "AvenirNext-Bold"
            numberLabel.fontSize = 20
            numberLabel.fontColor = .black
            numberLabel.verticalAlignmentMode = .center
            numberLabel.horizontalAlignmentMode = .center
            numberLabel.position = CGPoint(x: 0, y: 0) // Center the label within the cell
            numberCell.addChild(numberLabel)
            
            addChild(numberCell)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        var touchedNode = atPoint(location)
            
        // Traverse up to find the top-level cell node
        while let parentNode = touchedNode.parent, !(touchedNode is SKShapeNode && touchedNode.name?.starts(with: "cell_") == true || touchedNode.name?.starts(with: "numberCell_") == true ) {
            touchedNode = parentNode
        }
        
        // Check if the touched node is a cell
        if let cell = touchedNode as? SKShapeNode, cell.name?.starts(with: "cell_") == true {
            
            // Deselect the previously selected cell
            selectedCell?.fillColor = .white
            
            // Select the new cell and change its color to blue
            cell.fillColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // Light pastel blue color
            selectedCell = cell
        }
        
        if let cell = touchedNode as? SKShapeNode, let name = cell.name, name.starts(with: "numberCell_") {
            print(name)
        }
    }
}

