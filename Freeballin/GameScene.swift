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
    
    /* boiler plate variables */
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()

    var ball: SKSpriteNode!
    var playIcon: SKSpriteNode!
    var stopIcon: SKSpriteNode!
    
    var setupMode: Bool = true
    var ballStartingPosition = CGPoint()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func sceneDidLoad() {

        self.lastUpdateTime = 0
            setupMode = true
        }
    override func didMove(to view: SKView) {
        /* Set up your scene here */
        
        ball = self.childNode(withName: "//ball") as! SKSpriteNode
        playIcon = self.childNode(withName: "//PlayIcon") as! SKSpriteNode
        stopIcon = self.childNode(withName: "//StopIcon") as! SKSpriteNode
        
        ball.physicsBody?.isDynamic = false
        ballStartingPosition = ball.position
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
 
        if setupMode == true /*game on*/ {
            play()
        } else /* restart*/ {
            reset()
        }
    }
    func play() {
        
        ball.physicsBody?.isDynamic = true /* drop the ball*/

        let wooshSound = SKAction.playSoundFileNamed("woosh.wav", waitForCompletion: false)
        self.run(wooshSound)
        setupMode = false
        determineLogo()
    }
    
    func reset() {
        setupMode = true
        ball.position = ballStartingPosition
        ball.physicsBody?.isDynamic = false
        determineLogo()
    }
    
    func determineLogo() {
        if (setupMode == true) {
            playIcon.alpha = 1
            stopIcon.alpha = 0
        } else {
            playIcon.alpha = 0
            stopIcon.alpha = 1
        }
    }
    
    func gameOver() {
        /* play SFX*/
        reset()
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        
        if (!intersects(ball)) {
            print("ball left the scene")
            gameOver()
        }
    }
}
