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
import SwiftUI
import SceneKit.ModelIO


protocol TouchDelegate: AnyObject {
    func touchDownReceived(at point: CGPoint)
    func touchUpReceived(at point: CGPoint)
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
    weak var game: Game?
    var levelState: LevelState = .currentSatellite(0) {
        didSet {
            DispatchQueue.main.async {
                self.game?.objectWillChange.send()
            }
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
    var levelDescription: String {
        switch totalSatelliteCount {
        case 1:
            return "Tutorial"
        case 2:
            return "Level 1"
        default:
            return "Level 2"
        }
    }
    var base: SCNNode!
    var allSatellites: [SCNNode] = []
    var satellites: [SCNNode] = []
    weak var levelChangeDelegate: LevelCompletionDelegate?
    
    init(totalSatelliteCount: Int) {
        self.totalSatelliteCount = totalSatelliteCount
        
        resetLevel()
    }
    
    func resetLevel() {
        // rest game state
        levelState = .currentSatellite(0)
        
        // add base
        let sphereScene = SCNScene(named: "art.scnassets/sphere.scn")!
        let baseNode = sphereScene.rootNode
        
//        let baseNode = SCNNode()
//        baseNode.opacity = 0.9
        let radius: CGFloat = 0.06
        // geometry
        let baseGeometry = SCNSphere(radius: radius)
        baseNode.geometry = baseGeometry
        baseGeometry.firstMaterial?.diffuse.contents = UIColor.baseColor
        baseNode.name = "base"
        // position
        baseNode.position = SCNVector3(0, 0, -0.4)
        // physics
        let physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: nil))
        baseNode.physicsBody = physicsBody
        
        base = baseNode
        let pulseSphere = SCNSphere(radius: radius)
        pulseSphere.firstMaterial?.diffuse.contents = UIColor.baseColor
        let pulseNode = SCNNode(geometry: pulseSphere)
        
        baseNode.addChildNode(pulseNode)
        let duration: CGFloat = 2
        let fromOpacityValue: CGFloat = 1
        let toOpacityValue: CGFloat = 0
        let fromScaleValue: CGFloat = 1
        let toScaleValue: CGFloat = 1.7
        let pulse = SCNAction.customAction(duration: Double(duration)) { (node, currentTime) in
            let percentage = currentTime / duration
            node.opacity = fromOpacityValue + (toOpacityValue - fromOpacityValue) * percentage
            let scaleFactor =  fromScaleValue + (toScaleValue - fromScaleValue) * percentage
            node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        }
        baseNode.addChildNode(pulseNode)
        pulseNode.runAction(SCNAction.repeatForever(SCNAction.sequence([pulse, SCNAction.wait(duration: 0.6)])))
        
        // add satellites
        allSatellites = []
        satellites = []
        for i in 0 ..< totalSatelliteCount {
            let satelliteNode = SatelliteNode(index: i)
            satelliteNode.opacity = 1
            let position: SCNVector3
            if totalSatelliteCount == 1 {
                position = SCNVector3(0, 0, -0.1)
            } else {
                position = SCNVector3.randomForItemWithRadiusInRoom(itemRadius: Float(radius), scale: 0.3)
            }
            let radius: CGFloat = 0.03
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
            
            allSatellites.append(satelliteNode)
        }
        satellites = allSatellites
        
        updateSatellitesInScene()
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
        game?.trackedNode = nil
    }
    
    func updateSatellitesInScene() {
        switch self.levelState {
        case .completed:
            break
        case .currentSatellite(let index):
            satellites = []
            for i in allSatellites.indices {
                if i >= index {
                    satellites.append(allSatellites[i])
                }
            }

            satellites.forEach { $0.geometry?.firstMaterial?.diffuse.contents = UIColor.defaultSatelliteColor }
            satellites.first?.geometry?.firstMaterial?.diffuse.contents = UIColor.nextSatelliteColor
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
    
    var currentSatelliteIndex: Int? {
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

class Game: LevelCompletionDelegate, ObservableObject {
    private var allLevels: [Level] = Level.allLevels
    var objectWillChange = ObservableObjectPublisher()
    var currentLevel: Level {
        didSet {
            if oldValue != currentLevel {
                gameDelegate?.gameLevelChanged()
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                    self.labelContent = self.currentLevel.levelDescription
                }
            }
        }
    }
    
    var shouldShowCompletionLabel: Bool = false
    var labelContent: String = "Tutorial"
    var completionLabel: String = ""
    
    var trackedNode: SCNNode? {
        didSet {
            if trackedNode != nil {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }
    weak var touchDelegate: TouchDelegate?
    weak var gameDelegate: GameDelegate?
        
    init() {
        self.currentLevel = allLevels[0]
        self.allLevels.forEach{ $0.levelChangeDelegate = self }
        self.allLevels.forEach{ $0.game = self }
    }
    
    func baseCollidesWithSatellite(_ satellite: SatelliteNode) {
        currentLevel.baseCollidesWithSatellite(satellite)
    }
    
    func receiveTouchDown(at point: CGPoint) {
        touchDelegate?.touchDownReceived(at: point)
    }
    
    func receiveTouchUp(at point: CGPoint) {
        touchDelegate?.touchUpReceived(at: point)
    }
    
    func resetLevel() {
        currentLevel.resetLevel()
        gameDelegate?.gameLevelChanged()
        
        print("reset level. Current level now \(currentLevel.totalSatelliteCount)")
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.labelContent = self.currentLevel.levelDescription
        }
    }
    
    func restartFromTutorial() {
        for level in allLevels {
            level.resetLevel()
        }
        
        currentLevel = allLevels[0]
        gameDelegate?.gameLevelChanged()
        
        print("reset level. Current level now \(currentLevel.totalSatelliteCount)")
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.labelContent = self.currentLevel.levelDescription
        }
    }
        
    var allNodes: [SCNNode] {
        return [currentLevel.base] + currentLevel.satellites
    }
    
    // MARK: - Level Completion delegate
    func levelCompleted() {
        switch currentLevel.levelState {
        case .completed:
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.completionLabel = "\(self.currentLevel.levelDescription) Completed "
                withAnimation { self.shouldShowCompletionLabel = true }
            }
            
            
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [unowned self] (_) in
                DispatchQueue.main.async {
                    withAnimation { self.shouldShowCompletionLabel = false }
                    self.objectWillChange.send()
                }
            }
            
            // go to next level with a delay
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (_) in
                let index = self.allLevels.firstIndex(of: self.currentLevel)!
                if index != self.allLevels.count - 1 {
                    let nextIndex = index + 1
                    self.allLevels[nextIndex].levelState = .currentSatellite(0)
                    self.currentLevel = self.allLevels[nextIndex]
                }
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
