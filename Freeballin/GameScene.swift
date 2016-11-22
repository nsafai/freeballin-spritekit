//
//  GameScene.swift
//  Freeballin
//
//  Created by Nicolai Safai on 11/18/16.
//  Copyright © 2016 Nicolai Safai. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    var ball: SKSpriteNode!
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func sceneDidLoad() {

        self.lastUpdateTime = 0
        
//        // Get label node from scene and store it for use later
//        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
//        if let label = self.label {
//            label.alpha = 0.0
//            label.run(SKAction.fadeIn(withDuration: 2.0))
        
        }
    override func didMove(to view: SKView) {
        /* Set up your scene here */
        /* Recursive node search for 'ball' (child of referenced node) */
        ball = self.childNode(withName: "//ball") as! SKSpriteNode
        ball.physicsBody?.isDynamic = false
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* Apply vertical impulse */
//        ball.physicsBody?.affectedByGravity = false
        
        /* drop the ball*/
        ball.physicsBody?.isDynamic = true
        /* Play SFX */
        let wooshSound = SKAction.playSoundFileNamed("woosh.wav", waitForCompletion: false)
        self.run(wooshSound)
        print("hello")
//        ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 1000))
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
}
