//
//  IndicatorView.swift
//  RetrieveToBase
//
//  Created by Zihan Qi on 9/13/20.
//  Copyright © 2020 Zihan Qi. All rights reserved.
//

import SwiftUI
import SceneKit
import ARKit

struct IndicatorView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

func projectionVectorOf(_ target: SCNNode, onCamera camera: ARCamera) {
    
    // first get the vector between the target and the camera
    let cameraTransform = SCNMatrix4(camera.transform)
    let cameraPosition = SCNVector3(cameraTransform.m41, cameraTransform.m42, cameraTransform.m43)
    let distanceVector = SCNVector3(target.position.x - cameraPosition.x, target.position.y - cameraPosition.y, target.position.z - cameraPosition.z)
    
    let cameraDirection = SCNVector3(-cameraTransform.m31, -cameraTransform.m32, -cameraTransform.m33)
    
    let projectionVectorOnCameraPlane = projectionVectorOf(distanceVector, onPlaneWithNormalVector: cameraDirection)
    
    let cameraAngle = camera.eulerAngles
//    print("x: \(projectionVectorOnCameraPlane.x / (2*Float.pi) * 360)")
//    print("y: \(projectionVectorOnCameraPlane.y / (2*Float.pi) * 360)")
//    print("z: \(projectionVectorOnCameraPlane.z / (2*Float.pi) * 360)")
    
    let unitYVector = float4(-1, 0, 0, 1)
    let upVectorH = camera.transform * unitYVector
    // drop the 4th element
    let upVector = SCNVector3(upVectorH.x, upVectorH.y, upVectorH.z)
//    
//    print("x: \(upVector.x / (2*Float.pi) * 360)")
//    print("y: \(upVector.y / (2*Float.pi) * 360)")
//    print("z: \(upVector.z / (2*Float.pi) * 360)")
}

func projectionVectorOf(_ distancVector: SCNVector3, onPlaneWithNormalVector direction: SCNVector3) -> SCNVector3 {
    let result = SCNVector3(distancVector.x - direction.x, distancVector.y - direction.y, distancVector.z - direction.z)
    return result
}

func projectionOf(_ vector1: SCNVector3, onto vector2: SCNVector3) -> SCNVector3 {
    let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z
    let magnitudeSquaredOfVector2 = pow(vector2.x, 2) + pow(vector2.y, 2) + pow(vector2.z, 2)
    let coefficient = dotProduct / magnitudeSquaredOfVector2
    
    let result = SCNVector3(vector2.x*coefficient, vector2.y*coefficient, vector2.z*coefficient)
    return result
}

struct IndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        IndicatorView()
    }
}
