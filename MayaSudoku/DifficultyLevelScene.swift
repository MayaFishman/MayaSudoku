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
        
        // Calculate the center of the screen
        let screenCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Create buttons with a shadow effect
        let easyButton = createButton(text: "Easy", position: CGPoint(x: screenCenter.x, y: screenCenter.y + 150))
        easyButton.name = "Easy"
        addChild(easyButton)
        
        let mediumButton = createButton(text: "Medium", position: CGPoint(x: screenCenter.x, y: screenCenter.y + 50))
        mediumButton.name = "Medium"
        addChild(mediumButton)
        
        let hardButton = createButton(text: "Hard", position: CGPoint(x: screenCenter.x, y: screenCenter.y - 50))
        hardButton.name = "Hard"
        addChild(hardButton)
        
        let veryhardButton = createButton(text: "Very Hard", position: CGPoint(x: screenCenter.x, y: screenCenter.y - 150))
        veryhardButton.name = "Very Hard"
        addChild(veryhardButton)
        
    }
    
    private func createButton(text: String, position: CGPoint) -> SKShapeNode {
        // Shadow Node
        let shadow = SKShapeNode(rectOf: CGSize(width: 240, height: 70), cornerRadius: 15)
        shadow.position = CGPoint(x: position.x + 4, y: position.y - 4) // Offset shadow slightly
        shadow.fillColor = .black.withAlphaComponent(0.3)
        shadow.zPosition = 0
        addChild(shadow) // Add shadow to the scene
        
        // Main Button
        let button = SKShapeNode(rectOf: CGSize(width: 240, height: 70), cornerRadius: 15)
        button.position = position
        button.fillColor = SKColor(red: 0.25, green: 0.5, blue: 0.85, alpha: 1.0)
        button.strokeColor = .clear
        button.glowWidth = 3.0
        button.zPosition = 1
        
        // Label for the Button
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 26
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        button.addChild(label)
        
        return button
    }
    
    
    private func buttonTappedAnimation(_ button: SKShapeNode) {
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        button.run(sequence)
    }
    
    // Recursive function to find the parent button node
    private func findParentButton(node: SKNode?) -> SKShapeNode? {
        if let button = node as? SKShapeNode, button.name == "Easy" || button.name == "Medium" || button.name == "Hard" || button.name == "Very Hard" {
            return button
        } else if let parent = node?.parent {
            return findParentButton(node: parent)
        }
        return nil
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            
            if let button = findParentButton(node: touchedNode) {
                button.fillColor = SKColor(red: 0.2, green: 0.45, blue: 0.75, alpha: 1.0)
                buttonTappedAnimation(button)
                if button.name == "Easy" {
                    startSinglePlayerGame(difficulty: SudokuBoard.Difficulty.beginner)
                } else if button.name == "Medium" {
                    startSinglePlayerGame(difficulty: SudokuBoard.Difficulty.intermediate)
                } else if button.name == "Hard" {
                    startSinglePlayerGame(difficulty: SudokuBoard.Difficulty.hard)
                } else if button.name == "Very Hard" {
                    startSinglePlayerGame(difficulty: SudokuBoard.Difficulty.veryHard)
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            
            if let button = findParentButton(node: touchedNode) {
                button.fillColor = SKColor(red: 0.25, green: 0.5, blue: 0.85, alpha: 1.0)
            }
        }
    }
    
    // Start Single Player Game
    private func startSinglePlayerGame(difficulty: SudokuBoard.Difficulty) {
        print("Single Player Game Started!")
        let sudokuScene = SudokuScene(size: self.size)
        sudokuScene.scaleMode = .aspectFill
        sudokuScene.difficulty = difficulty
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(sudokuScene, transition: transition)
    }
}
