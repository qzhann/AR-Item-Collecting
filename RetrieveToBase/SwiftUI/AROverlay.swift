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
                    self.game.receiveTouchDown(at: value.location)
                }
                self.touchedDown = true
            }
            .onEnded { (value) in
                // touch up
                self.game.receiveTouchUp(at: value.location)
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
                    gameStateOverlay
                    restartButton
                    titleLabel
                    
                    if game.shouldShowCompletionLabel {
                        completionLabel
                    }
                    
                    if game.shouldShowCompletionLabel == false {
                        selectionOverlay
                    }
                    
                }
            }
        
        }
//        .gesture(drag)
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
            BlurView(style: .dark)
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
                                .foregroundColor(Color.init(.lightText))
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
                .foregroundColor(Color.init(.lightText))
                .font(.system(size: 24, weight: .medium, design: .rounded))

                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    BlurView(style: .systemThinMaterialDark)
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
                .foregroundColor(Color.init(.lightText))
                .font(.system(size: 24, weight: .medium, design: .rounded))

                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    BlurView(style: .systemThinMaterialDark)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                )
                .padding(.top)
        }
    .offset(x: 0, y: -30)
    }
    var gameStateOverlay: some View {
        HStack {
            Spacer()

            VStack {
                Spacer()

                ForEach<Range<Int>, Int, SatelliteView>((0..<game.currentLevel.totalSatelliteCount), id: \.self) { index in
                    
                    let reverseIndex = self.game.currentLevel.totalSatelliteCount - 1 - index
                    
                    var discoverState: DiscoverState = .retrievd
                    if let currentIndex = self.game.currentLevel.currentSatelliteIndex {
                        if reverseIndex == currentIndex {
                            discoverState = .current
                        } else if reverseIndex < currentIndex {
                            discoverState = .retrievd
                        } else {
                            discoverState = .future
                        }
                    }
                    
                    return SatelliteView(discoverState: discoverState)
                    
                }
            }
            .padding()
            .padding(.bottom, 20)
            
        }
    }
    var selectionOverlay: some View {
        ZStack {

            ZStack {
                Circle()
                    .fill(Color.init(.lightText))
                .frame(width: 8, height: 8, alignment: .center)
                
                Circle()
                .stroke(Color.init(.lightText), lineWidth: 6)
                .frame(width: 100, height: 100, alignment: .center)
            }
            
            GeometryReader { proxy in
                VStack {
                    Spacer()
                    Button(action: {
                        if self.game.trackedNode == nil {
                            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            self.game.receiveTouchDown(at: center)
                        } else {
                            self.game.receiveTouchUp(at: .zero)
                        }
                    }) {
                        ZStack {
                            if self.game.trackedNode == nil {
                                BlurView(style: .dark)
                                .frame(width: 150, height: 60, alignment: .center)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 8)
                                )
                                Text("Select")
                                    .layoutPriority(1)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(Color.init(.lightText))
                                .padding(.horizontal, 16)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                .frame(width: 150, height: 60, alignment: .center)
                                Text("Shoot!")
                                    .layoutPriority(1)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(Color.init(.black))
                                .padding(.horizontal, 16)
                            }
                            

                        }
                    }
                    .padding(.bottom, 26)
                }
            }
            
            
        }
    }
    
}

enum DiscoverState {
    case retrievd
    case current
    case future
}

//struct SelectionOverlay: View {
//    @ObservedObject var game: Game
//    var body: some View {
//        ZStack
//    }
//}

struct SatelliteView: View {
    var discoverState: DiscoverState
    var fillColor: Color {
        switch discoverState {
        case .retrievd:
            return Color(.clear)
        case .current:
            return Color(.nextSatelliteColor)
        case .future:
            return Color.clear
        }
    }
    var strokeColor: Color {
        switch discoverState {
        case .retrievd:
            return Color(.lightGray)
        case .current:
            return Color(UIColor.nextSatelliteColor.withAlphaComponent(0.7))
        case .future:
            return Color(UIColor.nextSatelliteColor)
        }
    }
    var body: some View {
        ZStack {
            if discoverState == .future {
                Circle()
                .strokeBorder(
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [4]
                    )
                )
                .foregroundColor(strokeColor)
                .frame(width: 20, height: 20)
            } else  {
                ZStack {
                                        
                    Circle()
                    .strokeBorder(
                        style: StrokeStyle(
                            lineWidth: 2
                        )
                    )
                    .foregroundColor(strokeColor)
                    .frame(width: 20, height: 20)
                    
                    Circle()
                    .fill(fillColor)
                    .frame(width: 20, height: 20)
                    
                    if discoverState == .retrievd {
                        Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                    }
                    
                }
                
            }
        }
        
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
        Group {
            AROverlay()
            .background(Color.blue.opacity(0.2))
    
        }
        
    }
}
