//
//  AROverlay.swift
//  RetrieveToBase
//
//  Created by Zihan Qi on 9/12/20.
//  Copyright © 2020 Zihan Qi. All rights reserved.
//

import SwiftUI

struct AROverlay: View {
    @State private var touchedDown = false
    weak var game = Game.currrent
    
    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { (value) in
                // touch down and drag
                if self.touchedDown == false {  // first-time touch down
                    self.game?.receiveTouch(at: value.location)
                }
                self.touchedDown = true
            }
            .onEnded { (value) in
                // touch up
                self.touchedDown = false
            }
    }
    
    var body: some View {
        ZStack {
            // rectangle that enables full-screen gesture
            Rectangle()
                .fill(Color.white)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .opacity(0.01)

            // actual content goes here
            VStack {
                HStack {
                    Spacer()
                    Button("Button", action: {})
                        .padding(EdgeInsets(top: 44, leading: 10, bottom: 10, trailing: 44))
                }
                Spacer()
                
            }
        }
    
    .gesture(drag)
    }
}

struct AROverlay_Previews: PreviewProvider {
    static var previews: some View {
        AROverlay()
            .background(Color.blue.opacity(0.2))
    }
}
