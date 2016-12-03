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
    var firstMovementWorthyCollisionDetected: Bool = false
    var ball: SKSpriteNode!
    var finishCup: SKSpriteNode!
    var insideCup: SKSpriteNode!
    var playIcon: SKSpriteNode!
    var playButton: SKSpriteNode!
    var stopIcon: SKSpriteNode!
    var lineBlock: MovableBlock!
    var timerLabel: SKLabelNode!
    var timerLabelDescription: SKLabelNode!
    var bestTimeLabel: SKLabelNode!
    var bestTimeLabelDescription: SKLabelNode!
    var timerContainerNode: SKNode!
    var buttonContainerNode: SKNode!
    var setupMode: Bool = true
    var ballStartingPosition = CGPoint()
    var touch: UITouch?
    var positionInScene: CGPoint?
    var touchedNode: SKNode?
    var rotationRecognizer: UIRotationGestureRecognizer?
    var timer: Float = 0.0
    var fingerTolerance: CGFloat?
    var fingerRect: CGRect?
    //    var touchedNodeFat: SKNode?
    var levelHolder: SKNode!
    var rotationSelectedBlock: MovableBlock!
    var level: SKReferenceNode?
    var levelNumber: Int!
    var numberOfLevels: Int!
    /* Tracking helpers */
    var trackerNode: SKNode? {
        didSet {
            if let trackerNode = trackerNode {
                /* Set tracker */
                lastTrackerPosition = trackerNode.position
            }
        }
    }
    var lastTrackerPosition = CGPoint(x: 0, y: 0)
    var lastTimeInterval:TimeInterval = 0
    var cameraStartingPosition: CGPoint?
    var timerContainerNodeStartingPosition: CGPoint?
    
    override func sceneDidLoad() {
        setupMode = true
    }
    
    override func didMove(to view: SKView) {
        /* Setup the scene */
        physicsWorld.contactDelegate = self
        ball = self.childNode(withName: "//ball") as! SKSpriteNode
        playIcon = self.childNode(withName: "//PlayIcon") as! SKSpriteNode
        playButton = self.childNode(withName: "//PlayButton") as! SKSpriteNode
        stopIcon = self.childNode(withName: "//StopIcon") as! SKSpriteNode
        timerLabel = self.childNode(withName: "//TimerLabel") as! SKLabelNode
        timerLabelDescription = self.childNode(withName: "//TimerLabelDescription") as! SKLabelNode
        bestTimeLabel = self.childNode(withName: "//BestTimeLabel") as! SKLabelNode
        bestTimeLabelDescription = self.childNode(withName: "//BestTimeLabelDescription") as! SKLabelNode
        timerContainerNode = self.childNode(withName: "TimerContainerNode") as SKNode!
        buttonContainerNode = self.childNode(withName: "//ButtonContainerNode") as SKNode!
        ball.physicsBody?.isDynamic = false
        ballStartingPosition = ball.position
        rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate(_:)))
        view.addGestureRecognizer(rotationRecognizer!)
        timer = 0.0
        
        levelHolder = childNode(withName: "levelHolder")
        levelNumber = 1
        numberOfLevels = 2
        loadLevel()
        cameraStartingPosition = CGPoint.init(x: (camera?.position.x)!, y: (camera?.position.y)!)
        timerContainerNodeStartingPosition = CGPoint.init(x: (timerContainerNode?.position.x)!, y: (timerContainerNode?.position.y)!)
    }
    
    func loadLevel() {
        let levelNumberString =  "//Level\(levelNumber!)"
        let resourcePath = Bundle.main.path(forResource: levelNumberString, ofType: "sks")
        level = SKReferenceNode (url: URL (fileURLWithPath: resourcePath!))
        print("Loaded level # \(levelNumber!)")
        levelHolder.addChild(level!)
        lineBlock = self.childNode(withName: "//LineBlock") as! SKSpriteNode as! MovableBlock
        finishCup = self.childNode(withName: "//RedCupPhysicsBody") as! SKSpriteNode
        insideCup = self.childNode(withName: "//InsideCup") as! SKSpriteNode
        
    }
    
    func nextLevel() {
        levelHolder.removeAllChildren()
        let levelLoadDelay = SKAction.wait(forDuration: (0.3))
        self.run(levelLoadDelay) {
            if self.levelNumber == self.numberOfLevels {
                self.levelNumber = 1
                self.loadLevel()
            } else {
                self.levelNumber = self.levelNumber! + 1
                self.loadLevel()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* function is called before each frame is rendered */
        if (!intersects(ball)) {
            print("ball left the scene")
            gameOver()
        }
        if (setupMode == false && ball.physicsBody?.isDynamic == true) {
            
            timer = timer + 1/60 /* 1/60 because the update function is run 60 times a second) */
        }
        let unit = "s"
        timerLabel.text = String.localizedStringWithFormat("%.2f %@", timer, unit)
        bestTimeLabel.text = "--"
        /* Check there is a node to track and camera is present */
        if let trackerNode = trackerNode, let camera = camera {
            /* Calculate distance to move */
            let moveDistanceX = trackerNode.position.x - lastTrackerPosition.x
            let moveDistanceY = trackerNode.position.y - lastTrackerPosition.y
            /* Duration is time between updates */
            let moveDuration = currentTime - lastTimeInterval
            /* Create a move action for the camera */
            let naturalCameraAcceleration = -moveDistanceY*trackerNode.position.y/800
            let moveCamera = SKAction.moveBy(x: 0, y: naturalCameraAcceleration, duration: moveDuration)
            if firstMovementWorthyCollisionDetected == true {
                if /* ball has moved past half the screen*/ (abs((ball.position.y - ballStartingPosition.y)) > 230) {
                    camera.run(moveCamera)
                    timerContainerNode.run(moveCamera)
                }
            }
            //            print(abs(ball.position.y - ballStartingPosition.y))
            lastTrackerPosition = trackerNode.position
        }
        /* Store current update step time */
        lastTimeInterval = currentTime
        //        print("trackerNode X:\(trackerNode?.position.x) Y:\(trackerNode?.position.y))")
        //        print("camera X:\(camera?.position.x) Y:\(camera?.position.y)")
    }
    
    func gameOver() {
        timer = 0.0
        reset()
    }
    
    func rotate(_ sender: UIRotationGestureRecognizer){
        if setupMode == true {
            let rotationTouchLocation = self.view?.convert(sender.location(in: self.view), to: self)
            let rotationTouchedNode = self.atPoint(rotationTouchLocation!)
            if rotationTouchedNode.name?.contains("LineBlock") == true {
                if rotationSelectedBlock == nil {
                    (rotationTouchedNode as! MovableBlock).selected = true
                    rotationSelectedBlock = (rotationTouchedNode as! MovableBlock)
                }
            }
            if let selectedBlock = rotationSelectedBlock {
                selectedBlock.run(SKAction.rotate(byAngle: (-(self.rotationRecognizer?.rotation)!*2), duration: 0.0))
                rotationRecognizer?.rotation = 0
            }
        }
        if (rotationRecognizer?.state == UIGestureRecognizerState.ended) {
            rotationSelectedBlock = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touch = touches.first!
        positionInScene = self.touch?.location(in: self)
        print(positionInScene as Any)
        touchedNode = self.atPoint(positionInScene!)
        /*fat finger code*/
        fingerTolerance = 0.1
        fingerRect = CGRect(origin: CGPoint(x: (positionInScene?.x)! - fingerTolerance!, y: (positionInScene?.y)! - fingerTolerance!), size: CGSize(width: fingerTolerance!*2, height: fingerTolerance!*2))
        let touchedNodeFat = physicsWorld.body(in: fingerRect!)?.node!
        switch touchedNode?.name {
        case "PlayButton"?, "PlayIcon"?, "StopIcon"?:
            /* Set tracker to follow penguin */
            if setupMode == true {
                play()
            } else {
                gameOver()
            }
        default:
            break
        }
        if touchedNodeFat?.name?.contains("LineBlock") == true {
            (touchedNodeFat as! MovableBlock).selected = true
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touch = touches.first!
        positionInScene = self.touch?.location(in: self)
        let previousPosition = self.touch?.previousLocation(in: self)
        let translation = CGVector(dx: (positionInScene?.x)! - (previousPosition?.x)!, dy: (positionInScene?.y)! - (previousPosition?.y)!)
        if setupMode == true {
            if touchedNode?.name?.contains("LineBlock") == true {
                (touchedNode as! MovableBlock).parent!.parent!.run(SKAction.move(by: translation, duration: 0.0))
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let humanLagDelay = SKAction.wait(forDuration: (0.05))
        self.run(humanLagDelay) {
            self.lineBlock.selected = false
            self.rotationSelectedBlock = nil
        }
    }
    
    func play() {
        ball.physicsBody?.isDynamic = true /* drop the ball*/
        timer = 0.0
        let wooshSound = SKAction.playSoundFileNamed("woosh.wav", waitForCompletion: false)
        self.run(wooshSound)
        setupMode = false
        determineLogo()
        trackerNode = ball
    }
    
    func reset() {
        setupMode = true
        ball.physicsBody?.isDynamic = false
        determineLogo()
        resetCamera()
        firstMovementWorthyCollisionDetected = false
        print("reset complete")
    }
    
    func resetCamera() {
        ball.run(SKAction.move(to: ballStartingPosition, duration: 0.35))
        
        if camera == nil {
            camera = self.childNode(withName: "camera") as! SKCameraNode?
            camera?.run(SKAction.move(to: cameraStartingPosition!, duration: 0.35))
            print("reset camera")
        } else {
            camera?.run(SKAction.move(to: cameraStartingPosition!, duration: 0.35))
        }
        timerContainerNode.run(SKAction.move(to: timerContainerNodeStartingPosition!, duration: 0.35))
        
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
        nextLevel()
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
            if /* ball has moved past half the screen*/ (abs((ball.position.y - ballStartingPosition.y)) > 230) {
                firstMovementWorthyCollisionDetected = true
            }
        default:
            break
        }
    }
}
