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
    
    weak var game: Game!

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // scene set up
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        scene.physicsWorld.gravity = SCNVector3(0, 0, 0)
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        
        // game object set up
        self.game = Game.currrent
        self.game.touchDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        addBase()
        
        addSatellite()
        
        addWalls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func addBase() {
        let baseNode = SCNNode()
        
        let radius: CGFloat = 0.1
        // geometry
        let baseGeometry = SCNSphere(radius: radius)
        baseNode.geometry = baseGeometry
        baseGeometry.firstMaterial?.diffuse.contents = UIColor.baseColor
        
        // physics
        let physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: nil))
        baseNode.physicsBody = physicsBody
        
        sceneView.scene.rootNode.addChildNode(baseNode)
    }
    
    func addSatellite(at position: SCNVector3 = SCNVector3(0.1, 0.2, -0.5)) {
        let satelliteNode = SCNNode()
        
        let radius: CGFloat = 0.05
        
        // geometry
        let satelliteGeometry = SCNSphere(radius: radius)
        satelliteNode.geometry = satelliteGeometry
        satelliteGeometry.firstMaterial?.diffuse.contents = UIColor.satelliteColor
        satelliteGeometry.name = "inner ball"
                
        // position
        satelliteNode.position = position
        
        // physics
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: radius), options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        satelliteNode.physicsBody = physicsBody
        physicsBody.restitution = 0.9
                
        sceneView.scene.rootNode.addChildNode(satelliteNode)
    }
    
    func addWalls() {
        let topWallNode = SCNNode()
        let bottomWallNode = SCNNode()
        let leftWallNode = SCNNode()
        let rightWallNode = SCNNode()
        let frontWallNode = SCNNode()
        let backWallNode = SCNNode()
        
        let wallNodes = [topWallNode, bottomWallNode, leftWallNode, rightWallNode, frontWallNode, backWallNode]

        let wallThickness: Float = 0.05
        let distanceToTop: Float = 0.3
        let distanceToBottom: Float = 0.6
        let distanceToFront: Float = 2
        let distanceToBack: Float = 2
        let distanceToLeft: Float = 2
        let distanceToRight: Float = 2
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
            wallGeometry.firstMaterial?.transparency = 1
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
    
    
    @IBSegueAction func embed(_ coder: NSCoder) -> UIViewController? {
        let hostingController = UIHostingController(coder: coder, rootView: AROverlay())
        hostingController!.view.backgroundColor = .clear
        return hostingController
    }
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

// MARK: - Touch controller delegate

extension ViewController: TouchDelegate {
    func touchReceived(at point: CGPoint) {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = sceneView.hitTest(point, options: hitTestOptions)
        
        if let firstResult = hitTestResults.first {
            let node = firstResult.node
            if node.isInteractive {
                print("tapped on node \(node)")
            } else {
                for result in hitTestResults {
                    if result.node.geometry is SCNSphere {
                        print("sphere found in results, but not first")
                        print(result)
                    } else {
                        print(result)
                    }
                }
                print("tapped on non-interactive element")
            }
            nodeTapped(node)
        } else {
            print("no interactive node tapped")
        }
        
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
