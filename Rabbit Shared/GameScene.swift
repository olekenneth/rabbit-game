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
    private var level = 1
    private var currentTileMap: SKTileMapNode?

        
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

    func tileMapPhysics(tileMap: SKTileMapNode)
    {
        let tileSize = CGSize(width: tileMap.tileSize.width, height: tileMap.tileSize.height)
        for col in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row)
                {
                    guard let textureName = tileDefinition.name else { break }
                    if textureName.localizedCaseInsensitiveContains("center") {
                        if let tileTexture = tileDefinition.textures.first {
                            let centerOfTile = tileMap.centerOfTile(atColumn: col, row: row)
                            
                            let tileNode = SKNode()
                            
                            tileNode.position = centerOfTile
                            tileNode.physicsBody = SKPhysicsBody(texture: tileTexture,
                                                                 size: tileSize)
                            tileNode.physicsBody?.linearDamping = 60.0
                            tileNode.physicsBody?.friction = 0.8
                            tileNode.physicsBody?.affectedByGravity = false
                            tileNode.physicsBody?.allowsRotation = false
                            tileNode.physicsBody?.restitution = 0.0
                            tileNode.physicsBody?.isDynamic = false
                            tileNode.physicsBody?.collisionBitMask = PhysicsCategory.Bunny
                            tileNode.physicsBody?.categoryBitMask = PhysicsCategory.Ground
                            
                            
                            tileMap.addChild(tileNode)
                        }
                    }
                
                }
            }
        }
    }

    func loadLevel() {
        if let currentTileMap {
            currentTileMap.position.y = 5000
            currentTileMap.removeAllChildren()
        }
        let tileMap = childNode(withName: "level" + String(level)) as! SKTileMapNode
        print(tileMap)
        currentTileMap = tileMap
        tileMapPhysics(tileMap: tileMap)
        
        tileMap.position.y = 0
    }
    
    func setUpScene() {
        // Set up camera
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        loadLevel()
        
        let sunSize = 350.0
        let sunPadding = 50.0
        let sun = SKSpriteNode(imageNamed:"sun")
        sun.size = CGSize(width: sunSize, height: sunSize)
        sun.texture?.filteringMode = .nearest
        sun.position = CGPoint(x: -sunPadding, y: sunSize)
        sun.zPosition = -1
        cameraNode.addChild(sun)
        
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
        
        bunny.physicsBody = SKPhysicsBody(circleOfRadius: bunny.size.width / 3)
        bunny.physicsBody?.isDynamic = true
        bunny.physicsBody?.categoryBitMask = PhysicsCategory.Bunny
        bunny.physicsBody?.contactTestBitMask = PhysicsCategory.Ground
        bunny.physicsBody?.collisionBitMask = PhysicsCategory.Ground
        
        addChild(bunny)
        
        // Create the animation action
        let runAction = SKAction.animate(with: bunnyTextures, timePerFrame: 0.1)
        let repeatRunAction = SKAction.repeatForever(runAction)
        
        bunny.run(repeatRunAction)
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)  // Set gravity to simulate a real-world environment
        physicsWorld.contactDelegate = self
        
        // self.backgroundColor = UIColor(white: 1, alpha: 1)

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
        
        level += 1
        
        if level > 3 {
            level = 1
        }
        loadLevel()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        cameraNode.position = CGPoint(x: bunny.position.x + bunny.size.width / 2, y: frame.midY) // adjust camera position
        
        if let camera = self.camera {
            let leftBoundary = camera.position.x - (size.width / 2)
            let rightBoundary = frame.maxX - 200
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
