//
//  CustomNode.swift
//  RetrieveToBase
//
//  Created by Zihan Qi on 9/12/20.
//  Copyright © 2020 Zihan Qi. All rights reserved.
//

import SceneKit
import UIKit

class SatelliteNode: SCNNode {
    var index: Int
    
    init(index: Int) {
        self.index = index
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
