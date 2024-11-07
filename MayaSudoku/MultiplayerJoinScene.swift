import SpriteKit
import UIKit

class MultiplayerJoinScene: SKScene, UIPickerViewDataSource, UIPickerViewDelegate {
    private var digitPickers: [UIPickerView] = []
    private var selectedDigits: [Int] = [0, 0, 0, 0] // Initialize each digit to 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 1.0)

        // Title
        let titleLabel = SKLabelNode(text: "Join a game")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        addChild(titleLabel)

        // Prompt for entering code
        let promptLabel = SKLabelNode(text: "Enter 4-digit game code:")
        promptLabel.fontName = "AvenirNext-Regular"
        promptLabel.fontSize = 28
        promptLabel.fontColor = .white
        promptLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        addChild(promptLabel)

        // Create and position 4 picker wheels
        let pickerWidth: CGFloat = 70
        let pickerSpacing: CGFloat = 10
        let pickerStartingX = view.frame.midX - (pickerWidth * 2 + pickerSpacing)

        for i in 0..<4 {
            let picker = UIPickerView(frame: CGRect(x: pickerStartingX + CGFloat(i) * (pickerWidth + pickerSpacing), y: view.frame.midY - 60, width: pickerWidth, height: 70)) // Increased height for readability
            picker.delegate = self
            picker.dataSource = self
            picker.tag = i // Use the tag to identify each picker
            picker.alpha = 0
            view.addSubview(picker)
            digitPickers.append(picker)
        }
        UIView.animate(withDuration: 1.0) {
            self.digitPickers.forEach { $0.alpha = 1 } // Fade each picker in
        }

        // Back Button
        let backButton = ButtonNode(text: "Back", position: CGPoint(x: size.width / 2, y: size.height * 0.2))
        backButton.onTap = { [weak self] in
            self?.goBack()
        }
        addChild(backButton)

        // Start Button
        let startButton = ButtonNode(text: "Join", position: CGPoint(x: size.width / 2, y: size.height * 0.2 + 100))
        startButton.onTap = { [weak self] in
            self?.joinGame()
        }
        addChild(startButton)
    }

    override func willMove(from view: SKView) {
        digitPickers.forEach { $0.removeFromSuperview() }
    }

    // MARK: - UIPickerView DataSource and Delegate

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // Each picker represents a single digit
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 10 // Digits 0–9
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = "\(row)"
        label.textAlignment = .center
        label.font = UIFont(name: "AvenirNext-Bold", size: 32) // Set a larger font
       //let selectedRow = pickerView.selectedRow(inComponent: component)
        //label.alpha = 1.0
        label.textColor = .white
        label.backgroundColor = .clear
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDigits[pickerView.tag] = row // Update the selected digit for the corresponding picker
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 70
    }

    private func joinGame() {
        let gameCode = selectedDigits.map { String($0) }.joined()
        print("Attempting to join game with code: \(gameCode)")

        // Transition back to the previous scene (e.g., MainMenuScene)
        UIView.animate(withDuration: 0.5, animations: {
            self.digitPickers.forEach { $0.alpha = 0 } // Fade each picker out
        }) { _ in
            // Remove pickers after fade-out is complete
            self.digitPickers.forEach { $0.removeFromSuperview() }
        }

        let waitingScene = MultiplayerWaitForHostScene(size: self.size)
        waitingScene.partyCode = gameCode
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(waitingScene, transition: transition)
    }

    private func goBack() {
        GameSessionManager.shared.cancelSession()

        // Transition back to the previous scene (e.g., MainMenuScene)
        UIView.animate(withDuration: 0.5, animations: {
            self.digitPickers.forEach { $0.alpha = 0 } // Fade each picker out
        }) { _ in
            // Remove pickers after fade-out is complete
            self.digitPickers.forEach { $0.removeFromSuperview() }
        }

        let mainMenuScene = MainMenuScene(size: self.size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(mainMenuScene, transition: transition)
    }
}
