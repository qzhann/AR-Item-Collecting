//
//  ViewController.swift
//  RetrieveToBase
//
//  Created by Zihan Qi on 9/12/20.
//  Copyright © 2020 Zihan Qi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftUI

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var trackedNode: SCNNode?
    var relativePosition: SCNVector3?
    weak var game: Game!
    var gameNodes: [SCNNode] = []

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // scene set up
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        scene.physicsWorld.gravity = SCNVector3(0, 0, 0)
        scene.physicsWorld.contactDelegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [.showWorldOrigin]
        sceneView.session.delegate = self
        
        // game object set up
        self.game = Game.currrent
        self.game.touchDelegate = self
        self.game.gameDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        // add walls
        addWalls(scale: 1)
        
        // trigger level change
        gameLevelChanged()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func addWalls(scale: Float = 1) {
        let topWallNode = SCNNode()
        let bottomWallNode = SCNNode()
        let leftWallNode = SCNNode()
        let rightWallNode = SCNNode()
        let frontWallNode = SCNNode()
        let backWallNode = SCNNode()
        
        let wallNodes = [topWallNode, bottomWallNode, leftWallNode, rightWallNode, frontWallNode, backWallNode]
        wallNodes.forEach { $0.opacity = 0 }
        wallNodes.forEach { $0.name = "wall" }

        let wallThickness: Float = 0.05
        let distanceToTop: Float = 0.3 * scale
        let distanceToBottom: Float = 0.6 * scale
        let distanceToFront: Float = 2 * scale
        let distanceToBack: Float = 2 * scale
        let distanceToLeft: Float = 2 * scale
        let distanceToRight: Float = 2 * scale
        let leftRightDistance = distanceToLeft + distanceToRight
        let topBottomDistance = distanceToTop + distanceToBottom
        let frontBackDistance = distanceToFront + distanceToBack

        // geometry
        let topBottomWallGeometry = SCNBox(width: CGFloat(leftRightDistance), height: CGFloat(wallThickness), length: CGFloat(frontBackDistance), chamferRadius: 0)
        let frontBackWallGeometry = SCNBox(width: CGFloat(leftRightDistance), height: CGFloat(topBottomDistance), length: CGFloat(wallThickness), chamferRadius: 0)
        let leftRightWallGeometry = SCNBox(width: CGFloat(wallThickness), height: CGFloat(topBottomDistance), length: CGFloat(frontBackDistance), chamferRadius: 0)
        let wallGeometries = [topBottomWallGeometry, frontBackWallGeometry, leftRightWallGeometry]
        for wallGeometry in wallGeometries {
            wallGeometry.firstMaterial?.diffuse.contents = UIColor.wallColor
        }
        
        topWallNode.geometry = topBottomWallGeometry
        bottomWallNode.geometry = topBottomWallGeometry
        leftWallNode.geometry = leftRightWallGeometry
        rightWallNode.geometry = leftRightWallGeometry
        frontWallNode.geometry = frontBackWallGeometry
        backWallNode.geometry = frontBackWallGeometry
        
        // position
        let surroundingWallYPosition = -topBottomDistance / 2 + distanceToTop
        topWallNode.position = SCNVector3(x: 0, y: distanceToTop, z: 0)
        bottomWallNode.position = SCNVector3(x: 0, y: -distanceToBottom, z: 0)
        leftWallNode.position = SCNVector3(x: -distanceToLeft, y: surroundingWallYPosition, z: 0)
        rightWallNode.position = SCNVector3(x: distanceToRight, y: surroundingWallYPosition, z: 0)
        frontWallNode.position = SCNVector3(x: 0, y: surroundingWallYPosition, z: -distanceToFront)
        backWallNode.position = SCNVector3(x: 0, y: surroundingWallYPosition, z: distanceToBack)

        // physics
        for wallNode in wallNodes {
            let physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: wallNode.geometry!, options: nil))
            wallNode.physicsBody = physicsBody
            physicsBody.restitution = 0.9
            physicsBody.contactTestBitMask = physicsBody.collisionBitMask
        }
        
        wallNodes.forEach { sceneView.scene.rootNode.addChildNode($0) }
    }
    
    func nodeTapped(_ node: SCNNode) {
        
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        let power: Float = 1
        let cameraTransform = SCNMatrix4(currentFrame.camera.transform)
        let force = SCNVector3(-cameraTransform.m31*power, -cameraTransform.m32*power, -cameraTransform.m33*power)
        
        node.physicsBody?.applyForce(force, asImpulse: true)
    }
    
    func objectdidBeginCollisionWithWall(_ wall: SCNNode) {
        let collisionOpacity: CGFloat = 0.7
        let defaultOpacity: CGFloat = 0.0
        let rampUpOpacityDuration = 0.2
        let rampDownOpacityDuration = 0.4
        SCNTransaction.begin()
        SCNTransaction.animationDuration = rampUpOpacityDuration
        let opacityFadingAnimation = CABasicAnimation(keyPath: "opacity")
        opacityFadingAnimation.duration = rampDownOpacityDuration
        opacityFadingAnimation.fromValue = collisionOpacity
        opacityFadingAnimation.toValue = defaultOpacity
        SCNTransaction.completionBlock = {
            wall.opacity = defaultOpacity
            wall.addAnimation(opacityFadingAnimation, forKey: "opacity")
        }
        
        wall.opacity = collisionOpacity
        
        SCNTransaction.commit()
    }
    
    
    @IBSegueAction func embed(_ coder: NSCoder) -> UIViewController? {
        let hostingController = UIHostingController(coder: coder, rootView: AROverlay())
        hostingController!.view.backgroundColor = .clear
        return hostingController
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        guard let trackedNode = trackedNode else { return }
        guard trackedNode is SatelliteNode else { self.trackedNode = nil; self.relativePosition = nil; return }
        guard let cameraNode = sceneView.pointOfView else { return }
        let updatedTransform = updatedTransformOf(trackedNode, withPosition: SCNVector3(0, 0, -0.3), relativeTo: cameraNode)
        trackedNode.transform = updatedTransform
    }
}

func updatedTransformOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) -> SCNMatrix4 {
    let referenceNodeTransform = matrix_float4x4(referenceNode.transform)

    // Setup a translation matrix with the desired position
    var translationMatrix = matrix_identity_float4x4
    translationMatrix.columns.3.x = position.x
    translationMatrix.columns.3.y = position.y
    translationMatrix.columns.3.z = position.z

    // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
    let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
    return SCNMatrix4(updatedTransform)
}

// MARK: - Touch controller delegate

extension ViewController: TouchDelegate {
    
    func touchDownReceived(at point: CGPoint) {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = sceneView.hitTest(point, options: hitTestOptions)

        if let firstResult = hitTestResults.first {
            let node = firstResult.node
            guard node is SatelliteNode else { return }
            let updatedTransform = updatedTransformOf(node, withPosition: SCNVector3(0, 0, -0.3), relativeTo: sceneView.pointOfView!)
            let updatedPosition = SCNVector3(updatedTransform.m41, updatedTransform.m42, updatedTransform.m43)

            let trackAction = SCNAction.move(to: updatedPosition, duration: 0.2)
            trackAction.timingMode = .easeIn
            node.runAction(trackAction, completionHandler: {
                self.trackedNode = node
            })
        }
    }
    
    func touchUpReceived(at point: CGPoint) {
        trackedNode = nil
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = sceneView.hitTest(point, options: hitTestOptions)
        
        if let firstResult = hitTestResults.first {
            let node = firstResult.node
            nodeTapped(node)
        }
        
        // FIXME: Remove this
//        game.currentLevel.correctSatelliteHit()
    }
}

// MARK: - Physics Contact delegate

extension ViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        // wall collision
        if contact.nodeA.name == "wall" || contact.nodeB.name == "wall" {
            let wall = contact.nodeA.name == "wall" ? contact.nodeA : contact.nodeB
            
            objectdidBeginCollisionWithWall(wall)
        }
        
        // collision with base
        if contact.nodeA.name == "base" || contact.nodeB.name == "base" {
            let satellite = (contact.nodeA.name == "base" ? contact.nodeB : contact.nodeA) as! SatelliteNode
            
            game.baseCollidesWithSatellite(satellite)
        }
    }
}

// MARK: - Game Delegate

extension ViewController: GameDelegate {
    func gameLevelChanged() {
        
        // remove the previous nodes
        gameNodes.forEach { $0.removeFromParentNode() }
        
        for childNode in sceneView.scene.rootNode.childNodes {
            childNode.removeFromParentNode()
        }
        
        addWalls()
        
        // add the level nodes
        game.allNodes.forEach { sceneView.scene.rootNode.addChildNode($0) }
        gameNodes = game.allNodes
    }
}



extension SCNNode {
    var isInteractive: Bool {
        return self.geometry is SCNSphere
    }
    
    func treeRoot() -> SCNNode {
        rootNodeOf(self)
    }
    
    private func rootNodeOf(_ node: SCNNode) -> SCNNode {
        var result = node
        while result.parent != nil {
            result = result.parent!
        }
        return result
    }
}
