//
//  GameViewController.swift
//  MayaSudoku
//
//  Created by Maya Fishman on 26/10/2024.
//

import UIKit
import SpriteKit
import GameplayKit
import GameKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        authenticateLocalPlayer()

        // Create and configure the MainMenuScene
        if let view = self.view as! SKView? {
            let scene = MainMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill

            // Present the MainMenuScene
            view.presentScene(scene)

            view.ignoresSiblingOrder = true
            //view.showsFPS = true
            //view.showsNodeCount = true
        }

        setupGKAccessPoint()
    }

    func authenticateLocalPlayer() {
            let localPlayer = GKLocalPlayer.local
            localPlayer.authenticateHandler = { [weak self] (viewController, error) in
                if let vc = viewController {
                    self?.present(vc, animated: true, completion: nil)
                } else if localPlayer.isAuthenticated {
                    print("Player is authenticated")
                    // Now that the player is authenticated, activate the GKAccessPoint
                    GKAccessPoint.shared.isActive = true
                } else {
                    print("Game Center authentication failed: \(error?.localizedDescription ?? "No error")")
                }
            }
        }

        func setupGKAccessPoint() {
            let accessPoint = GKAccessPoint.shared
            accessPoint.location = .topLeading  // Choose desired location
            accessPoint.isActive = GKLocalPlayer.local.isAuthenticated
        }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
