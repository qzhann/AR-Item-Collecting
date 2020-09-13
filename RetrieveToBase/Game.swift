//
//  Game.swift
//  RetrieveToBase
//
//  Created by Zihan Qi on 9/12/20.
//  Copyright © 2020 Zihan Qi. All rights reserved.
//

import UIKit
import SceneKit
import Combine

protocol TouchDelegate: AnyObject {
    func touchReceived(at point: CGPoint)
}

protocol GameDelegate: AnyObject {
    func gameLevelChanged()
}

protocol LevelCompletionDelegate: AnyObject {
    func levelCompleted()
}

enum LevelState {
    case currentSatellite(Int)
    case completed
}

class Level {
    let totalSatelliteCount: Int
    var levelState: LevelState = .currentSatellite(0) {
        didSet {
            updateSatellitesInScene()
            switch levelState {
            case .completed:
                print("level: \(totalSatelliteCount), state now completed")
                levelChangeDelegate?.levelCompleted()
            case .currentSatellite(let index):
                print("level: \(totalSatelliteCount), state now \(index)")
                break
            }
        }
    }
    var base: SCNNode!
    var allSatellites: [SCNNode] = []
    var satellites: [SCNNode] = []
    weak var levelChangeDelegate: LevelCompletionDelegate?
    
    init(totalSatelliteCount: Int) {
        self.totalSatelliteCount = totalSatelliteCount
        
        resetLevel()
        
        satellites.forEach { $0.geometry?.firstMaterial?.diffuse.contents = UIColor.defaultSatelliteColor }
        satellites[0].geometry?.firstMaterial?.diffuse.contents = UIColor.nextSatelliteColor
    }
    
    func resetLevel() {
        // add base
        let baseNode = SCNNode()
        let radius: CGFloat = 0.1
        // geometry
        let baseGeometry = SCNSphere(radius: radius)
        baseNode.geometry = baseGeometry
        baseGeometry.firstMaterial?.diffuse.contents = UIColor.baseColor
        baseNode.name = "base"
        // position
        baseNode.position = SCNVector3(0, 0, -0.2)
        // physics
        let physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: nil))
        baseNode.physicsBody = physicsBody
        
        base = baseNode
        
        // add satellites
        satellites = []
        for i in 0 ..< totalSatelliteCount {
            let satelliteNode = SatelliteNode(index: i)
            let position: SCNVector3
            if totalSatelliteCount == 1 {
                position = SCNVector3(0, 0, 0.3)
            } else {
                position = SCNVector3.randomForItemWithRadiusInRoom(itemRadius: Float(radius), scale: 0.5)
            }
            let radius: CGFloat = 0.05
            // geometry
            let satelliteGeometry = SCNSphere(radius: radius)
            satelliteNode.geometry = satelliteGeometry
            satelliteGeometry.firstMaterial?.diffuse.contents = UIColor.defaultSatelliteColor
            // position
            satelliteNode.position = position
            // physics
            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
            satelliteNode.physicsBody = physicsBody
            physicsBody.restitution = 0.9
            physicsBody.damping = 0.2
            physicsBody.contactTestBitMask = physicsBody.collisionBitMask
            
            satellites.append(satelliteNode)
        }
        allSatellites = satellites
    }
    
    func correctSatelliteHit() {
        // update game state
        switch levelState {
        case .completed:
            break
        case .currentSatellite(let currentIndex):
            let nextIndex = currentIndex + 1
            // check if we've reached over the last satellite
            if nextIndex >= totalSatelliteCount {
                self.levelState = .completed
            } else {
                self.levelState = .currentSatellite(nextIndex)
            }
        }
    }
    
    func updateSatellitesInScene() {
        switch self.levelState {
        case .completed:
            satellites.remove(at: 0)
            break
        case .currentSatellite(let index):
            var newSatellites: [SCNNode] = []
            for i in allSatellites.indices {
                if i >= index {
                    newSatellites.append(allSatellites[i])
                }
            }
            satellites = newSatellites
            satellites.forEach { $0.geometry?.firstMaterial?.diffuse.contents = UIColor.defaultSatelliteColor }
            let nextNode = satellites.first { (node) -> Bool in
                let satellite = node as! SatelliteNode
                return satellite.index == index
            }
            nextNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.nextSatelliteColor
        }
    }
    
    func baseCollidesWithSatellite(_ satellite: SatelliteNode) {
        guard let index = currentSatelliteIndex else { return }
        if index == satellite.index {
            // correct satellite collision
            let fadeActions = fadeNode(satellite)
            let flashColorActions = flashColorOnBase(color: UIColor.nextSatelliteColor)
            let flashExpansionActions = flashExpansionOnNode(base)
            
            base.runAction(SCNAction.group([flashColorActions, flashExpansionActions]))
            satellite.runAction(fadeActions, completionHandler: {
                self.correctSatelliteHit()
            })
            
        } else {
            // incorrect satellite collision
            let flashColorActions = flashColorOnBase(color: UIColor.incorrectColor)
            
            base.runAction(flashColorActions, completionHandler: nil)
        }
    }
    
    func flashColorOnBase(color: UIColor) -> SCNAction {
        let beforeColor: UIColor = .baseColor
        let flashColor: UIColor = color
        let rampUpDuration: CGFloat = 0.1
        let rampDownDuration: CGFloat = 0.4
        
        let flashColorAction = SCNAction.customAction(duration: TimeInterval(rampUpDuration)) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / rampUpDuration
            let color = self.interpolatedColor(from: beforeColor, to: flashColor, percentage: percentage)
            node.geometry!.firstMaterial!.diffuse.contents = color
        }
        
        let revertColorAction = SCNAction.customAction(duration: TimeInterval(rampDownDuration)) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / rampDownDuration
            let color = self.interpolatedColor(from: flashColor, to: beforeColor, percentage: percentage)
            node.geometry!.firstMaterial!.diffuse.contents = color
        }
        revertColorAction.timingMode = .easeOut
        
        return SCNAction.sequence([flashColorAction, revertColorAction])
    }
    
    func flashExpansionOnNode(_ node: SCNNode) -> SCNAction {
        let fromValue: CGFloat = CGFloat(node.scale.x)
        let toValue: CGFloat = CGFloat(node.scale.x * 1.2)
        let rampUpDuration: CGFloat = 0.4
        let scaleUp = SCNAction.customAction(duration: TimeInterval(rampUpDuration)) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / rampUpDuration
            let scaleFactor = fromValue + (toValue - fromValue) * percentage
            node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        }
        scaleUp.timingMode = .easeOut
        
//        let rampDownDuration: CGFloat = 0.4
//        let scaleDown = SCNAction.customAction(duration: TimeInterval(rampDownDuration)) { (node, elapsedTime) -> () in
//            let percentage = elapsedTime / rampDownDuration
//            let scaleFactor = toValue + (fromValue - toValue) * percentage
//            node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
//        }
        
        return SCNAction.sequence([scaleUp])
    }
    
    func fadeNode(_ node: SCNNode) -> SCNAction {
        node.physicsBody?.velocity = .init(x: 0, y: 0, z: 0)

        let fadeDuration: CGFloat = 0.2
        let fade = SCNAction.customAction(duration: TimeInterval(fadeDuration)) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / fadeDuration
            let opacity = 1 - percentage
            node.opacity = opacity
        }
        
        return fade
    }
    
    func interpolatedColor(from: UIColor, to: UIColor, percentage: CGFloat) -> UIColor {
        let color = UIColor(red: from.redValue + (to.redValue - from.redValue) * percentage,
            green: from.greenValue + (to.greenValue - from.greenValue) * percentage,
            blue: from.blueValue + (to.blueValue - from.blueValue) * percentage,
            alpha: from.alphaValue + (to.alphaValue - from.alphaValue) * percentage
            )
        return color
    }
    
    private var currentSatelliteIndex: Int? {
        switch self.levelState {
        case .completed:
            return nil
        case .currentSatellite(let index):
            return index
        }
    }
    
    static var level1 = Level(totalSatelliteCount: 1)
    static var level2 = Level(totalSatelliteCount: 2)
    static var level3 = Level(totalSatelliteCount: 10)
    static var allLevels = [level1, level2, level3]
}

extension Level: Equatable {
    static func ==(lhs: Level, rhs: Level) -> Bool {
        return lhs.totalSatelliteCount == rhs.totalSatelliteCount
    }
}

class Game: LevelCompletionDelegate {
    private var allLevels: [Level] = Level.allLevels
    var currentLevel: Level {
        didSet {
            if oldValue != currentLevel {
                gameDelegate?.gameLevelChanged()
            }
        }
    }
    
    weak var touchDelegate: TouchDelegate?
    weak var gameDelegate: GameDelegate?
    
    var cancellable: AnyCancellable?
    
    init() {
        self.currentLevel = allLevels[0]
        self.allLevels.forEach{ $0.levelChangeDelegate = self }
    }
    
    func baseCollidesWithSatellite(_ satellite: SatelliteNode) {
        currentLevel.baseCollidesWithSatellite(satellite)
    }
    
    func receiveTouch(at point: CGPoint) {
        touchDelegate?.touchReceived(at: point)
        
        // FIXME: Change this
//        self.currentLevel.correctSatelliteHit()
    }
        
    var allNodes: [SCNNode] {
        return [currentLevel.base] + currentLevel.satellites
    }
    
    // MARK: - Level Completion delegate
    func levelCompleted() {
        switch currentLevel.levelState {
        case .completed:
            let index = allLevels.firstIndex(of: currentLevel)!
            if index != allLevels.count - 1 {
                let nextIndex = index + 1
                allLevels[nextIndex].levelState = .currentSatellite(0)
                currentLevel = allLevels[nextIndex]
            }
            
        default:
            break
        }
    }
    
    static var currrent = Game()
    
    
}

extension SCNVector3 {
    static func randomForItemWithRadiusInRoom(itemRadius: Float, scale: Float = 1, top: Float = 0.3, bottom: Float = 0.6, left: Float = 2, right: Float = 2, front: Float = 2, back: Float = 2) -> SCNVector3 {
        let fittableTop = top * scale - itemRadius
        let fittableBottom = -bottom * scale + itemRadius
        let fittableLeft = -left * scale + itemRadius
        let fittableRight = right * scale - itemRadius
        let fittableFront = -front * scale + itemRadius
        let fittableBack = back * scale - itemRadius
        
        return SCNVector3(Float.random(in: fittableLeft...fittableRight), Float.random(in: fittableBottom...fittableTop), Float.random(in: fittableFront...fittableBack))
    }
}

extension UIColor {
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }
}
