//
//  GameViewController.swift
//  MayaSudoko
//
//  Created by Maya Fishman on 26/10/2024.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
