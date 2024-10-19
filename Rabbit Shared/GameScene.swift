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
    static let Carrot: UInt32 = 0b11      // Binary: 3
}

final class GameScene: SKScene {
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
    
    var tilesFrom = 0
    var tilesUntil = 0
    var cameraX = -1000000.0
    func tileMapPhysics(tileMap: SKTileMapNode, cameraX: CGFloat) {
        let tileSize = tileMap.tileSize
        tilesUntil = Int(cameraX / (tileSize.width * tileMap.xScale)) + 25
        
        for col in tilesFrom..<min(tileMap.numberOfColumns, tilesUntil) {
            for row in 0..<tileMap.numberOfRows {
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row) {
                    if let textureName = tileDefinition.name, textureName.localizedCaseInsensitiveContains("center") {
                        let centerOfTile = tileMap.centerOfTile(atColumn: col, row: row)
                        let tileNode = SKNode()
                        
                        tileNode.position = centerOfTile
//                        tileNode.size = tileSize
//                        tileNode.color = .blue
                        tileNode.physicsBody = SKPhysicsBody(rectangleOf: tileSize)
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
        tilesFrom = tilesUntil
    }
    
    func loadLevel() {
        if let currentTileMap {
            currentTileMap.position.y = 5000
            currentTileMap.removeAllChildren()
        }
        tilesFrom = 0
        tilesUntil = 0

        let tileMap = childNode(withName: "level" + String(level)) as! SKTileMapNode
        currentTileMap = tileMap
        // tileMapPhysics(tileMap: tileMap)
        
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
        // bunny.physicsBody?.allowsRotation = false
        bunny.physicsBody?.restitution = 0.3
        bunny.physicsBody?.categoryBitMask = PhysicsCategory.Bunny
        bunny.physicsBody?.contactTestBitMask = PhysicsCategory.Carrot
        bunny.physicsBody?.collisionBitMask = PhysicsCategory.Ground
        
        print(PhysicsCategory.Carrot)
        
        addChild(bunny)
        
        // Create the animation action
        let runAction = SKAction.animate(with: bunnyTextures, timePerFrame: 0.09)
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
        bunny.physicsBody?.applyImpulse(.init(dx: 300, dy: 300))
    }
    
    func resetBunnyPosition() {
        // Define the initial position of the bunny
        bunny.position = CGPoint(x: frame.minX + 100, y: frame.midY) // Adjust position as needed
        bunny.physicsBody?.velocity = CGVector(dx: 0, dy: 0) // Reset any movement
        cameraX = 0.0
        level += 1
        
        if level > 5 {
            level = 1
        }
        loadLevel()
    }
        
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        bunny.zRotation = 0
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
        
        if cameraNode.frame.offsetBy(dx: (frame.width / 2), dy: 0).maxX - cameraX > 1200 {
            cameraX = cameraNode.frame.offsetBy(dx: (frame.width / 2), dy: 0).maxX
            tileMapPhysics(tileMap: currentTileMap!, cameraX: cameraX)
        }
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Handle contact between physics bodies
        // Example: Check which bodies made contact and handle collision
        if contact.bodyA.categoryBitMask == PhysicsCategory.Carrot {
            bunny.physicsBody?.applyImpulse(.init(dx: 800, dy: 0))
            contact.bodyA.node?.removeFromParent()
        }
    }
}


#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
            // makeBunnyJump()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if location.x > frame.midX {
            }
            // makeBunnyJump()
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
