//
//  GameScene.swift
//  PenguinNinja
//
//  Created by Nick Sagan on 20.11.2021.
//

import SpriteKit
import GameplayKit
import AVFoundation

enum ForceBomb {
    case never, always, random
}

enum SequenceType: CaseIterable {
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
}

class GameScene: SKScene {
    
    var activeSlicePoints = [CGPoint]()
    var activeEnemies = [SKSpriteNode]()
    
    var gameScore: SKLabelNode!
    var score = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }

    var livesImages = [SKSpriteNode]()
    var lives = 3
    
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    
    var isSwooshSoundActive = false
    var bombSoundEffect: AVAudioPlayer?
    
    // The popupTime property is the amount of time to wait between the last enemy being destroyed and a new one being created.
    var popupTime = 0.9
    
    // The sequence property is an array of our SequenceType enum that defines what enemies to create.
    var sequence = [SequenceType]()
    
    // The sequencePosition property is where we are right now in the game.
    var sequencePosition = 0
    
    // The chainDelay property is how long to wait before creating a new enemy when the sequence type is .chain or .fastChain. Enemy chains don't wait until the previous enemy is offscreen before creating a new one, so it's like throwing five enemies quickly but with a small delay between each one.
    var chainDelay = 3.0
    
    // The nextSequenceQueued property is used so we know when all the enemies are destroyed and we're ready to create more.
    var nextSequenceQueued = true

    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)

        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
        
        createScore()
        createLives()
        createSlices()
        
        
        sequence = [.oneNoBomb, .oneNoBomb, .twoWithOneBomb, .twoWithOneBomb, .three, .one, .chain]

        for _ in 0 ... 1000 {
            if let nextSequence = SequenceType.allCases.randomElement() {
                sequence.append(nextSequence)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.tossEnemies()
        }
    }
    
    func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        addChild(gameScore)

        gameScore.position = CGPoint(x: 8, y: 8)
        score = 0
    }
    
    func createLives() {
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)

            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2

        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 3

        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9

        activeSliceFG.strokeColor = UIColor.white
        activeSliceFG.lineWidth = 5

        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }

    }
    
    func playSwooshSound() {
        isSwooshSoundActive = true

        let randomNumber = Int.random(in: 1...3)
        let soundName = "swoosh\(randomNumber).caf"

        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)

        run(swooshSound) { [weak self] in
            self?.isSwooshSoundActive = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // 1
        activeSlicePoints.removeAll(keepingCapacity: true)

        // 2
        let location = touch.location(in: self)
        activeSlicePoints.append(location)

        // 3
        redrawActiveSlice()

        // 4
        activeSliceBG.removeAllActions()
        activeSliceFG.removeAllActions()

        // 5
        activeSliceBG.alpha = 1
        activeSliceFG.alpha = 1
    }
    
    func redrawActiveSlice() {
        // 1
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }

        // 2
        if activeSlicePoints.count > 12 {
            activeSlicePoints.removeFirst(activeSlicePoints.count - 12)
        }

        // 3
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])

        for i in 1 ..< activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }

        // 4
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
    }
    
    func tossEnemies() {
        
        // we're always going to increase the speed of our physics world, so that objects move rise and fall faster too.
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02

        let sequenceType = sequence[sequencePosition]

        switch sequenceType {
        case .oneNoBomb:
            createEnemy(forceBomb: .never)

        case .one:
            createEnemy()

        case .twoWithOneBomb:
            createEnemy(forceBomb: .never)
            createEnemy(forceBomb: .always)

        case .two:
            createEnemy()
            createEnemy()

        case .three:
            createEnemy()
            createEnemy()
            createEnemy()

        case .four:
            createEnemy()
            createEnemy()
            createEnemy()
            createEnemy()

        case .chain:
            createEnemy()

            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 2)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 3)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 4)) { [weak self] in self?.createEnemy() }

        case .fastChain:
            createEnemy()

            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 2)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 3)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 4)) { [weak self] in self?.createEnemy() }
        }

        sequencePosition += 1
        nextSequenceQueued = false
    }
    
    func createEnemy(forceBomb: ForceBomb = .random) {
        let enemy: SKSpriteNode

        var enemyType = Int.random(in: 0...6)

        if forceBomb == .never {
            enemyType = 1
        } else if forceBomb == .always {
            enemyType = 0
        }

        if enemyType == 0 {
            // bomb code goes here
            // Create a new SKSpriteNode that will hold the fuse and the bomb image as children, setting its Z position to be 1.
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"

            // Create the bomb image, name it "bomb", and add it to the container.
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)

            // If the bomb fuse sound effect is playing, stop it and destroy it.
            if bombSoundEffect != nil {
                bombSoundEffect?.stop()
                bombSoundEffect = nil
            }

            // Create a new bomb fuse sound effect, then play it.
            if let path = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf") {
                if let sound = try?  AVAudioPlayer(contentsOf: path) {
                    bombSoundEffect = sound
                    sound.play()
                }
            }

            // Create a particle emitter node, position it so that it's at the end of the bomb image's fuse, and add it to the container.
            if let emitter = SKEmitterNode(fileNamed: "sliceFuse") {
                emitter.position = CGPoint(x: 76, y: 64)
                enemy.addChild(emitter)
            }
        } else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }

        // position code goes here
        // Give the enemy a random position off the bottom edge of the screen.
        let randomPosition = CGPoint(x: Int.random(in: 64...960), y: -128)
        enemy.position = randomPosition

        // Create a random angular velocity, which is how fast something should spin.
        let randomAngularVelocity = CGFloat.random(in: -3...3 )
        let randomXVelocity: Int

        // Create a random X velocity (how far to move horizontally) that takes into account the enemy's position.
        if randomPosition.x < 256 {
            randomXVelocity = Int.random(in: 8...15)
        } else if randomPosition.x < 512 {
            randomXVelocity = Int.random(in: 3...5)
        } else if randomPosition.x < 768 {
            randomXVelocity = -Int.random(in: 3...5)
        } else {
            randomXVelocity = -Int.random(in: 8...15)
        }

        // Create a random Y velocity just to make things fly at different speeds.
        let randomYVelocity = Int.random(in: 24...32)

        // Give all enemies a circular physics body where the collisionBitMask is set to 0 so they don't collide.
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0

        addChild(enemy)
        activeEnemies.append(enemy)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if activeEnemies.count > 0 {
            for (index, node) in activeEnemies.enumerated().reversed() {
                if node.position.y < -140 {
                    node.removeFromParent()
                    activeEnemies.remove(at: index)
                }
            }
        } else {
            if !nextSequenceQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) { [weak self] in
                    self?.tossEnemies()
                }

                nextSequenceQueued = true
            }
        }
        
        var bombCount = 0

        for node in activeEnemies {
            if node.name == "bombContainer" {
                bombCount += 1
                break
            }
        }

        if bombCount == 0 {
            // no bombs – stop the fuse sound!
            bombSoundEffect?.stop()
            bombSoundEffect = nil
        }
    }
    
}
