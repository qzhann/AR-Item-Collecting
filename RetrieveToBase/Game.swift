//
//  Game.swift
//  RetrieveToBase
//
//  Created by Zihan Qi on 9/12/20.
//  Copyright © 2020 Zihan Qi. All rights reserved.
//

import UIKit

protocol TouchDelegate: AnyObject {
    func touchReceived(at point: CGPoint)
}

class Game {
    weak var touchDelegate: TouchDelegate?
    
    func receiveTouch(at point: CGPoint) {
        touchDelegate?.touchReceived(at: point)
    }
    
    static var currrent = Game()
}
