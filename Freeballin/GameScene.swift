//
//  GameScene.swift
//  Freeballin
//
//  Created by Nicolai Safai on 11/18/16.
//  Copyright © 2016 Nicolai Safai. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /* boiler plate variables */
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()

    var ball: SKSpriteNode!
    var finishCup: SKSpriteNode!
    var insideCup: SKSpriteNode!
    var playIcon: SKSpriteNode!
    var playButton: SKSpriteNode!
    var stopIcon: SKSpriteNode!
    var lineBlock: SKSpriteNode!
    
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
        /* Setup the scene */
        physicsWorld.contactDelegate = self
        
        ball = self.childNode(withName: "//ball") as! SKSpriteNode
        finishCup = self.childNode(withName: "//RedCupPhysicsBody") as! SKSpriteNode
        insideCup = self.childNode(withName: "//InsideCup") as! SKSpriteNode
        playIcon = self.childNode(withName: "//PlayIcon") as! SKSpriteNode
        playButton = self.childNode(withName: "//PlayButton") as! SKSpriteNode
        stopIcon = self.childNode(withName: "//StopIcon") as! SKSpriteNode
        lineBlock = self.childNode(withName: "//LineBlock") as! SKSpriteNode
        
        ball.physicsBody?.isDynamic = false
        ballStartingPosition = ball.position
        ball.physicsBody!.contactTestBitMask = ball.physicsBody!.collisionBitMask
        finishCup.physicsBody!.contactTestBitMask = finishCup.physicsBody!.collisionBitMask
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first!
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if touchedNode == playButton {
            if setupMode == true {
                play()
            } else {
                reset()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let positionInScene = touch.location(in: self)
        let previousPosition = touch.previousLocation(in: self)
        let translation = CGVector(dx: positionInScene.x - previousPosition.x, dy: positionInScene.y - previousPosition.y)
        let touchedNode = atPoint(positionInScene)
        
        if true {
            print("trying to move lineblock")
            lineBlock.run(SKAction.move(by: translation, duration: 0.0))
        }
    }
    //            lineBlock.run(SKAction.move(to: CGPoint(x: lineBlock.position.x + translation.x, y: lineBlock.position.y + translation.y), duration: 0.0))
    func play() {
        
        ball.physicsBody?.isDynamic = true /* drop the ball*/

        let wooshSound = SKAction.playSoundFileNamed("woosh.wav", waitForCompletion: false)
        self.run(wooshSound)
        setupMode = false
        determineLogo()
    }
    
    func reset() {
        setupMode = true
        ball.run(SKAction.move(to: ballStartingPosition, duration: 0.0))
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
    
    func finishCupCollision() {
        print("victory")
        /* play SFX*/
        reset()
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* function is called before each frame is rendered */
        if (!intersects(ball)) {
            print("ball left the scene")
            reset()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* collision detections*/
        print("contact between two objects")
        

        switch contact.bodyA.node!.name! {
        case "RedCupPhysicsBody":
            let cupSound = SKAction.playSoundFileNamed("redcup.wav", waitForCompletion: false)
            self.run(cupSound)
        case "InsideCup":
            let cupSound = SKAction.playSoundFileNamed("redcup.wav", waitForCompletion: false)
            self.run(cupSound)
            let aahSound = SKAction.playSoundFileNamed("aah.wav", waitForCompletion: false)
            self.run(aahSound)
            finishCupCollision()
        case "LineBlock":
            let blockSound = SKAction.playSoundFileNamed("woodclick.wav", waitForCompletion: false)
            self.run(blockSound)
        default:
            break
        }
    }
}
