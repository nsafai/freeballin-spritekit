//
//  GameScene.swift
//  Freeballin
//
//  Created by Nicolai Safai on 11/18/16.
//  Copyright © 2016 Nicolai Safai. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var ball: SKSpriteNode!
    var finishCup: SKSpriteNode!
    var insideCup: SKSpriteNode!
    var playIcon: SKSpriteNode!
    var playButton: SKSpriteNode!
    var stopIcon: SKSpriteNode!
    var lineBlock: MovableBlock!
    var timerLabel: SKLabelNode!
    var setupMode: Bool = true
    var ballStartingPosition = CGPoint()
    var touch: UITouch?
    var positionInScene: CGPoint?
    var touchedNode: SKNode?
    var rotationRecognizer: UIRotationGestureRecognizer?
    var timer: Float = 0.0
    var fingerTolerance: CGFloat?
    var fingerRect: CGRect?
    var touchedNodeFat: SKNode?
    var levelHolder: SKNode!
    var rotationSelectedBlock: MovableBlock!
    
    override func sceneDidLoad() {
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
        timerLabel = self.childNode(withName: "//TimerLabel") as! SKLabelNode
        ball.physicsBody?.isDynamic = false
        ballStartingPosition = ball.position
        ball.physicsBody!.contactTestBitMask = ball.physicsBody!.collisionBitMask
        finishCup.physicsBody!.contactTestBitMask = finishCup.physicsBody!.collisionBitMask
        rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate(_:)))
        view.addGestureRecognizer(rotationRecognizer!)
        timer = 0.0
        timerLabel.text = "invisible text"
        timerLabel.alpha = 0
        levelHolder = childNode(withName: "levelHolder")
        /* Load Level 1 */
        let resourcePath = Bundle.main.path(forResource: "//Level1", ofType: "sks")
        let level = SKReferenceNode (url: URL (fileURLWithPath: resourcePath!))
        levelHolder.addChild(level)
        lineBlock = self.childNode(withName: "//LineBlock") as! SKSpriteNode as! MovableBlock
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* function is called before each frame is rendered */
        if (!intersects(ball)) {
            print("ball left the scene")
            gameOver()
        }
        if setupMode == false {
            timerLabel.alpha = 1
            timer = timer + 1/60 /* 1/60 because the update function is run 60 times a second) */
        }
        let unit = "s"
        timerLabel.text = String.localizedStringWithFormat("%.2f %@", timer, unit)
    }
    
    func gameOver() {
        timer = 0.0
        reset()
    }
    
    func rotate(_ sender: UIRotationGestureRecognizer){
        if setupMode == true {
            
            let rotationTouchLocation = self.view?.convert(sender.location(in: self.view), to: self)
            let rotationTouchedNode = self.atPoint(rotationTouchLocation!)
            print("rotationTouchedNode in rotate: is \(rotationTouchedNode.name)")
            
            if rotationTouchedNode.name?.contains("LineBlock") == true {
                if rotationSelectedBlock == nil {
                    (rotationTouchedNode as! MovableBlock).selected = true
                    rotationSelectedBlock = (rotationTouchedNode as! MovableBlock)
                }
            }
            if let selectedBlock = rotationSelectedBlock {
                selectedBlock.run(SKAction.rotate(byAngle: (-(self.rotationRecognizer?.rotation)!*2), duration: 0.0))
                rotationRecognizer?.rotation = 0
//                let humanLagDelay = SKAction.wait(forDuration: (0.2))
            }
            //            if let selectedLineBlock = (rotationTouchedNode as? MovableBlock) {
            //                if selectedLineBlock.selected = true
            
            //                rotationRecognizer?.rotation = 0
            //            }
        }
        if (rotationRecognizer?.state == UIGestureRecognizerState.ended) {
            print("Rotation recognizer ended")
            rotationSelectedBlock = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        touch = touches.first!
        positionInScene = self.touch?.location(in: self)
        touchedNode = self.atPoint(positionInScene!)
        /*fat finger code*/
        fingerTolerance = 0.1
        fingerRect = CGRect(origin: CGPoint(x: (positionInScene?.x)! - fingerTolerance!, y: (positionInScene?.y)! - fingerTolerance!), size: CGSize(width: fingerTolerance!*2, height: fingerTolerance!*2))
        touchedNodeFat = physicsWorld.body(in: fingerRect!)?.node!
        
        switch touchedNode?.name {
        case "PlayButton"?, "PlayIcon"?, "StopIcon"?:
            if setupMode == true {
                play()
            } else {
                gameOver()
            }
        default:
            break
        }
        //        if touchedNodeFat?.name?.contains("LineBlock") == true {
        //            (touchedNodeFat as! MovableBlock).selected = true
        //        }
        print("touchedNode in touchesBegan: is \(touchedNode?.name)")
        print("touchedNodeFat in touchesBegan: is \(touchedNodeFat?.name)")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchedNode in touchesBegan: is \(touchedNode?.name)")
        print("touchedNodeFat in touchesBegan: is \(touchedNodeFat?.name)")
        touch = touches.first!
        positionInScene = self.touch?.location(in: self)
        let previousPosition = self.touch?.previousLocation(in: self)
        let translation = CGVector(dx: (positionInScene?.x)! - (previousPosition?.x)!, dy: (positionInScene?.y)! - (previousPosition?.y)!)
        
        if setupMode == true {
            if touchedNodeFat?.name?.contains("LineBlock") == true {
                //                (touchedNodeFat as! MovableBlock).selected = true
                (touchedNodeFat as! MovableBlock).parent!.parent!.run(SKAction.move(by: translation, duration: 0.0))
                //                print("touchesMoved()")
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let humanLagDelay = SKAction.wait(forDuration: (0.05))
//        lineBlock.run(humanLagDelay) {
//        }
        self.run(humanLagDelay) {
            self.lineBlock.selected = false
            self.rotationSelectedBlock = nil
        }
        print("touchesEnded()")
    }
    
    func play() {
        ball.physicsBody?.isDynamic = true /* drop the ball*/
        timer = 0.0
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* collision detections*/
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
