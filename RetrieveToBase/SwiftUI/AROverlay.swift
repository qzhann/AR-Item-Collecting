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
    @State private var showReplayOptions = false
    
    @ObservedObject var game = Game.currrent
    
    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { (value) in
                // touch down and drag
                if self.touchedDown == false {  // first-time touch down
                    self.game.receiveTouch(at: value.location)
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
                ZStack {
                    restartButton
                    titleLabel
                    
                    if game.shouldShowCompletionLabel {
                        completionLabel
                    }
                    
                    
                }
            }
        
        }
        .gesture(drag)
    }
    
    var replayOptions: some View {

        VStack {
            Button(action: {
                self.game.resetLevel()
                withAnimation(.linear(duration: 0.2)) { self.showReplayOptions = false }
                
            }) {
                Text("Restart Level")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 7)
                .padding(.horizontal, 3)
                .offset(y: 5)
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            
            Rectangle()
                .fill(Color.white)
                .frame(height: 1)
            
            Button(action: {
                self.game.restartFromTutorial()
                withAnimation(.linear(duration: 0.2)) { self.showReplayOptions = false }

            }) {
                Text("Tutorial")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 7)
                .padding(.horizontal, 3)
                .offset(y: -5)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
        }
        .background(
            BlurView(style: .prominent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        )
            .frame(width: 140)
    }
    
    var restartButton: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.15)) { self.showReplayOptions.toggle() } }) {
                        ZStack {
                            BlurView(style: .prominent)
                                .frame(width: 44, height: 44, alignment: .center)
                                .clipShape(Circle())
                            
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            .offset(x: 0, y: -3)
                        }
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                    if showReplayOptions {
                        replayOptions
                            .offset(y: -8)
                            .padding(.leading, 8)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
                
            }
            Spacer()
        }
    }
    var titleLabel: some View {
        VStack {
            
            Text(game.labelContent)
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .medium, design: .rounded))

                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    BlurView(style: .prominent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                )
                .padding(.top)
            Spacer()
        }
    }
    var completionLabel: some View {
        VStack {
            
            HStack {
                Image(systemName: "checkmark")
                Text(game.completionLabel)
            }
                .foregroundColor(.white)
                .font(.system(size: 24, weight: .medium, design: .rounded))

                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    BlurView(style: .prominent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                )
                .padding(.top)
        }
    .offset(x: 0, y: -30)
    }
    
}

struct BlurView: UIViewRepresentable {

    let style: UIBlurEffect.Style

    func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        return view
    }

    func updateUIView(_ uiView: UIView,
                      context: UIViewRepresentableContext<BlurView>) {

    }

}

struct AROverlay_Previews: PreviewProvider {
    static var previews: some View {
        AROverlay()
            .background(Color.blue.opacity(0.2))
    }
}
