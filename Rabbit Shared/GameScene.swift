//
//  GameScene.swift
//  Rabbit Shared
//
//  Created by Ole-Kenneth on 30/09/2024.

// HARIO
//

import SpriteKit

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Ground: UInt32 = 0b1       // Binary: 1
    static let Bunny: UInt32 = 0b10       // Binary: 2
}

final class GameScene: SKScene {
    fileprivate var background : SKSpriteNode?
    fileprivate var hero : SKShapeNode?
    fileprivate var bunny: SKSpriteNode!
    private var cameraNode: SKCameraNode!
    var currentGroundEnd: CGFloat = 0

        
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    func createCustomGroundSegment(at startX: CGFloat) -> SKNode {
        let segmentWidth = CGFloat.random(in: 150...300)
        let dirtHeight: CGFloat = 30
        let grassHeight: CGFloat = 10
        let groundPositionY = frame.minY + dirtHeight + grassHeight

        let groundParentNode = SKNode()

        // Create dirt part of the ground
        let dirtNode = SKSpriteNode(color: .brown, size: CGSize(width: segmentWidth, height: dirtHeight))
        dirtNode.position = CGPoint(x: segmentWidth / 2, y: dirtHeight / 2)

        // Create grass part of the ground
        let grassNode = SKSpriteNode(color: .green, size: CGSize(width: segmentWidth, height: grassHeight))
        grassNode.position = CGPoint(x: segmentWidth / 2, y: dirtHeight + grassHeight / 2)

        // Add dirt and grass nodes as children to the parent node
        groundParentNode.addChild(dirtNode)
        groundParentNode.addChild(grassNode)

        // Set the position of the parent node
        groundParentNode.position = CGPoint(x: startX + segmentWidth / 2, y: groundPositionY)

        // Create physics body for the parent node
        groundParentNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: segmentWidth, height: dirtHeight))
        groundParentNode.physicsBody?.isDynamic = false
        groundParentNode.physicsBody?.categoryBitMask = PhysicsCategory.Ground
        groundParentNode.physicsBody?.contactTestBitMask = PhysicsCategory.Bunny
        groundParentNode.physicsBody?.collisionBitMask = PhysicsCategory.Bunny

        currentGroundEnd = startX + segmentWidth
        return groundParentNode
    }

    func createInitialCustomGround() {
        let initialGroundSegments = Int(ceil(frame.width / 300)) + 1
        for _ in 0..<initialGroundSegments {
            let groundSegment = createCustomGroundSegment(at: currentGroundEnd)
            addChild(groundSegment)
        }
    }

    
    func createDynamicGround() {
        let screenWidth = frame.width
        var currentX: CGFloat = frame.minX

        while currentX < screenWidth {
            let segmentWidth = CGFloat.random(in: 150...300)
            let segmentHeight = CGFloat.random(in: 15...140)
            let groundPositionY = frame.minY + segmentHeight

            let ground = SKSpriteNode(imageNamed: "green")
            ground.zPosition = 1
            ground.position = CGPoint(x: currentX + segmentWidth, y: groundPositionY)
            
            print(ground.position, screenWidth)
            ground.size = CGSize(width: segmentWidth, height: segmentHeight)
            
            ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
            ground.physicsBody?.isDynamic = false // The ground should not move due to physics
            ground.physicsBody?.categoryBitMask = PhysicsCategory.Ground
            ground.physicsBody?.contactTestBitMask = PhysicsCategory.Bunny
            ground.physicsBody?.collisionBitMask = PhysicsCategory.Bunny
            
            addChild(ground)
            
            currentX += segmentWidth
        }
    }

    func setUpScene() {
        // Set up camera
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        
        currentGroundEnd = frame.minX
        
        // Get label node from scene and store it for use later
        let background = SKSpriteNode(color: UIColor(red: 1, green: 1, blue: 1, alpha: 1), size: frame.size)
        background.zPosition = -1

        let sunSize = 350.0
        let sunPadding = 50.0
        let sun = SKSpriteNode(imageNamed:"sun")
        sun.size = CGSize(width: sunSize, height: sunSize)
        sun.texture?.filteringMode = .nearest
        sun.position = CGPoint(x: -sunPadding, y: sunSize)
        cameraNode.addChild(sun)

        addChild(background)
        
        let spriteSheet = SKTexture(imageNamed: "bunny") // Replace with your sprite sheet's name
        
        // Assume sprite sheet is organized in 3 rows of 6 frames each
        let rows = 1
        let columns = 4
        let totalFrames = rows * columns  // Total number of frames on the sheet
        
        // Calculate the size of each frame
        let frameWidth = 1.0 / CGFloat(columns)
        let frameHeight = 1.0 / CGFloat(rows)
        
        var bunnyTextures: [SKTexture] = []
        
        for row in 0..<rows {
            for column in 0..<columns {
                if row * columns + column >= totalFrames {
                    break // Avoid accessing frames outside the total count
                }
                
                // Calculate the texture rectangle
                let rect = CGRect(x: CGFloat(column) * frameWidth,
                                  y: CGFloat(row) * frameHeight,
                                  width: frameWidth,
                                  height: frameHeight)
                
                let texture = SKTexture(rect: rect, in: spriteSheet)
                bunnyTextures.append(texture)
            }
        }
        
        bunny = SKSpriteNode(texture: bunnyTextures.first)
        // Create the bunny sprite using the first frame
        bunny.position = CGPoint(x: frame.minX + bunny.size.width, y: frame.maxY)
        bunny.xScale = -1
        
        bunny.physicsBody = SKPhysicsBody(circleOfRadius: bunny.size.width / 2)
        bunny.physicsBody?.isDynamic = true
        bunny.physicsBody?.categoryBitMask = PhysicsCategory.Bunny
        bunny.physicsBody?.contactTestBitMask = PhysicsCategory.Ground
        bunny.physicsBody?.collisionBitMask = PhysicsCategory.Ground
        
        addChild(bunny)
        
        // Create the animation action
        let runAction = SKAction.animate(with: bunnyTextures, timePerFrame: 0.1)
        let repeatRunAction = SKAction.repeatForever(runAction)
        
        bunny.run(repeatRunAction)


        createInitialCustomGround()
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)  // Set gravity to simulate a real-world environment
        physicsWorld.contactDelegate = self
        
        self.backgroundColor = UIColor(white: 1, alpha: 1)

        self.setUpScene()
    }
    
    func makeBunnyJump() {
        let bunnySpeed: CGFloat = 400.0
        bunny.physicsBody?.velocity = CGVector(dx: 200, dy: bunnySpeed)
    }

    func resetBunnyPosition() {
        // Define the initial position of the bunny
        bunny.position = CGPoint(x: frame.minX + 100, y: frame.midY) // Adjust position as needed
        bunny.physicsBody?.velocity = CGVector(dx: 0, dy: 0) // Reset any movement
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        cameraNode.position = CGPoint(x: bunny.position.x, y: frame.midY) // adjust camera position
        
        if let camera = self.camera {
            let leftBoundary = camera.position.x - (size.width / 2)
            let rightBoundary = camera.position.x + (size.width / 2)
            let bottomBoundary = camera.position.y - (size.height / 2)
            let topBoundary = camera.position.y + (size.height / 2)
            
            if bunny.position.x < leftBoundary ||
               bunny.position.x > rightBoundary ||
               bunny.position.y < bottomBoundary ||
               bunny.position.y > topBoundary {
                
                resetBunnyPosition()
            }
        }
        
        bunny.zRotation = 0
        
        if bunny.position.x + frame.width / 2 > currentGroundEnd - 150 {
            let newGroundSegment = createCustomGroundSegment(at: currentGroundEnd)
            addChild(newGroundSegment)
        }

    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Handle contact between physics bodies
        // Example: Check which bodies made contact and handle collision
    }
}


#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let background = self.background {
            background.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for touch in touches {
            let location = touch.location(in: self)
            
            if location.x > frame.midX {
            }
            makeBunnyJump()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if location.x > frame.midX {
            }
            makeBunnyJump()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if location.x > frame.midX {
            }
            makeBunnyJump()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
        }
    }
    
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        self.makeBunnyJump()
    }
    
    override func mouseDragged(with event: NSEvent) {
        
    }
    
    override func mouseUp(with event: NSEvent) {
        
    }

}
#endif
