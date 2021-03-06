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
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    var movementWorthyEventHappened: Bool = false
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
    var instructionArrow: SKSpriteNode!
    var timerContainerNode: SKNode!
    var buttonContainerNode: SKNode!
    var levelBoundaryBottom: SKSpriteNode!
    var levelBoundaryLeft: SKSpriteNode!
    var levelBoundaryRight: SKSpriteNode!
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
    var buttonContainerNodeStartingPosition: CGPoint?
    var audioSession : AVAudioSession?
    
    override func sceneDidLoad() {
        setupMode = true
    }
    
    override func didMove(to view: SKView) {
        /* Setup the scene */
        
        /* setup sound */
        setupSound()
        
        /* load sprites */
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
        
        /* add rotation gesture recognizer */
        rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate(_:)))
        view.addGestureRecognizer(rotationRecognizer!)
        
        /* set timer to 0.0 seconds */
        timer = 0.0
        
        /* setup level constants */
        levelHolder = childNode(withName: "levelHolder")
        levelNumber = 1
        numberOfLevels = 3
        loadLevel()
        
        /* log initial locations so we can return back to these after game over or next level */
        cameraStartingPosition = CGPoint.init(x: (camera?.position.x)!, y: (camera?.position.y)!)
        timerContainerNodeStartingPosition = CGPoint.init(x: (timerContainerNode?.position.x)!, y: (timerContainerNode?.position.y)!)
        buttonContainerNodeStartingPosition = CGPoint.init(x: (buttonContainerNode?.position.x)!, y: (buttonContainerNode?.position.y)!)
    }
    
    func setupSound() {
        /* allow background music to continue playing while playing game */
        audioSession = AVAudioSession.sharedInstance()
        try!audioSession?.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers) // might consider using .duck to reduce music volume when game sounds are played
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
        levelBoundaryBottom = self.childNode(withName: "//LevelBoundaryBottom") as! SKSpriteNode
        levelBoundaryLeft = self.childNode(withName: "//LevelBoundaryLeft") as! SKSpriteNode
        levelBoundaryRight = self.childNode(withName: "//LevelBoundaryRight") as! SKSpriteNode
        print("level size: \(level?.scene?.size)")
        /* display level instructions */
        showLevelInstructions()
    }
    
    func showLevelInstructions() {
        if levelNumber == 1 {
            pulsate(pointOfInterest: playIcon) // user has never played before, highlight play icon
        } else if levelNumber == 2 {
            playIcon.removeAction(forKey: "pulsate")
            instructionArrow = self.childNode(withName: "//InstructionArrow") as! SKSpriteNode
            pulsate(pointOfInterest: instructionArrow)
        } else {
            playIcon.removeAction(forKey: "pulsate")
        }
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
        touchedNode = self.atPoint(positionInScene!)
        
        /*fat finger code*/
        fingerTolerance = 0.1
        fingerRect = CGRect(origin: CGPoint(x: (positionInScene?.x)! - fingerTolerance!, y: (positionInScene?.y)! - fingerTolerance!), size: CGSize(width: fingerTolerance!*2, height: fingerTolerance!*2))
        let touchedNodeFat = physicsWorld.body(in: fingerRect!)?.node!
        
        /* start / end game when top button pressed */
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
        
        /* (possibly unnecessary) code to make selecting a block easier */
        if touchedNodeFat?.name?.contains("LineBlock") == true {
            (touchedNodeFat as! MovableBlock).selected = true
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touch = touches.first!
        positionInScene = self.touch?.location(in: self)
        
        /* code to move a movable block */
        let previousPosition = self.touch?.previousLocation(in: self)
        let translation = CGVector(dx: (positionInScene?.x)! - (previousPosition?.x)!, dy: (positionInScene?.y)! - (previousPosition?.y)!)
        if setupMode == true {
            if touchedNode?.name?.contains("LineBlock") == true {
                (touchedNode as! MovableBlock).parent!.parent!.run(SKAction.move(by: translation, duration: 0.0))
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* code to let go of a block */
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
        self.run(wooshSound) /* SFX */
        setupMode = false /* setupmode = false means movable blocks become immovable*/
        determineLogo() /* determine whether to display play or stop icon */
        trackerNode = ball /* camera trackernode */
    }
    
    func reset() {
        setupMode = true
        ball.physicsBody?.isDynamic = false
        determineLogo()
        resetCamera()
        movementWorthyEventHappened = false
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
        buttonContainerNode.run(SKAction.move(to: buttonContainerNodeStartingPosition!, duration: 0.35))
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
    
    func pulsate(pointOfInterest: SKNode) {
        let pulseUp = SKAction.scale(to: 0.9, duration: 0.5)
        let pulseDown = SKAction.scale(to: 0.6, duration: 0.5)
        let pulse = SKAction.sequence([pulseUp, pulseDown])
        let repeatPulse = SKAction.repeatForever(pulse)
        pointOfInterest.run(repeatPulse, withKey: "pulsate")
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* function is called before each frame is rendered */
        
        /*if ball leaves allowed zone, game over */
        if (levelBoundaryBottom.intersects(ball) == true) ||
            (levelBoundaryLeft.intersects(ball) == true) ||
            (levelBoundaryRight.intersects(ball) == true) {
            print("ball left the scene")
            gameOver()
        }
        
        /* timer code */
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
            let naturalCameraAcceleration = moveDistanceY
            let moveCamera = SKAction.moveBy(x: 0, y: naturalCameraAcceleration, duration: moveDuration)
            let distanceBallTravelled = (abs((ball.position.y - ballStartingPosition.y)))
            if movementWorthyEventHappened == true {
                if /* ball has moved past half the screen*/ (distanceBallTravelled > 230) {
                    camera.run(moveCamera)
                    timerContainerNode.run(moveCamera)
                    buttonContainerNode.run(moveCamera)
                }
            }
            if (distanceBallTravelled > 350) {
                movementWorthyEventHappened = true
            }
            lastTrackerPosition = trackerNode.position
       }
        /* Store current update step time */
        lastTimeInterval = currentTime
    }
}
