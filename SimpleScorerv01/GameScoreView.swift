//
//  ContentView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 3/16/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import Combine

struct GameScoreView: View {
    
    @EnvironmentObject var game : Game
    @State private var shouldScroll = true
    
    // PlayerEntry
    @State private var showPlayerEntry = false
    
    // cube display
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    @State var dragOffset = CGSize.zero
    @State var previousWidth = CGFloat(0)
    @State var swipingLeft = true
    
    // image picker
    @State private var imagePicked = UIImage()
    @State private var showImagePicker = false
    @State private var pickerSource = UIImagePickerController.SourceType.photoLibrary
    
    //Grid view
    
    
    func nbrRowsColumns(screenWidth: CGFloat, playerCount: Int) -> (rows : Int, columns : Int) {
        
        let nbrColumns = Double((screenWidth) / 325).rounded(.down)
        let nbrRows = Double(Double(playerCount) / nbrColumns).rounded(.up)
        return (Int(nbrRows),Int(nbrColumns))
    }
    
    func dragToRotation(translation : CGSize) -> Angle {
        return Angle(degrees: Double(translation.width/4.16))
    }
    
    func setSwipingDirection (width : CGFloat) {
        if width - previousWidth > 0 {
            swipingLeft = false
        } else {
            swipingLeft = true
        }
        previousWidth = width
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack {
                Color.offWhite.edgesIgnoringSafeArea(.all)
                
                AllScoresView()
                    .modifier(cubeRotation(dragOffset: $dragOffset, screen: .allScores, screenWidth: geometry.size.width))
//                    .scaleEffect(0.9)
                
                GameSetupView(showPlayerEntry: self.$showPlayerEntry)
                    .modifier(cubeRotation(dragOffset: $dragOffset, screen: .gameSetup, screenWidth: geometry.size.width))

                // Score Cards View
                ScoreCardsGridView()
                    .modifier(cubeRotation(dragOffset: $dragOffset, screen: .scoreCards, screenWidth: geometry.size.width))
                
                BottomButtonsView()
                
                if self.showImagePicker {
                    CircleImagePickerView(isPresented: self.$showImagePicker, selectedImage: self.$imagePicked, source: self.pickerSource)
                        .edgesIgnoringSafeArea(.all)
                }
                
                if self.showPlayerEntry {
                    PlayersEntryView(isVisible: self.$showPlayerEntry)
                }
            }
            .gesture(

                DragGesture()
                    .onChanged { gesture in
//                        print("\(gesture.translation.width) - Prev \(previousWidth) - left? \(swipingLeft)")
                        if !(self.displayInfo.allScoreScrolling) {
                            self.setSwipingDirection(width: gesture.translation.width)

                            if gesture.startLocation.x > (geometry.size.width - 25) && self.displayInfo.screenDisplayed != ScreenType.gameSetup {
                                self.dragOffset = gesture.translation
                            } else if gesture.startLocation.x < 25 && self.displayInfo.screenDisplayed != ScreenType.allScores {
                                self.dragOffset = gesture.translation
                            } else {
                                self.dragOffset = .zero
                            }
                        } else {
                            self.dragOffset = .zero
                        }

                    }
                    .onEnded({ (value) in

                        if self.dragOffset != .zero {
                            if self.dragOffset.width > 0 && !self.swipingLeft {
                                if (ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue - 1) != nil) {
                                    self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue - 1)!
                                }
                            } else if self.dragOffset.width < 0 && self.swipingLeft {
                                if (ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue + 1) != nil) {
                                    self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue + 1)!
                                }
                            }
                            self.dragOffset = .zero
                        }
                    })
            )
        }
    }
}

struct cubeRotation: ViewModifier {
    
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    
    @Binding var dragOffset : CGSize
    
    let screen : ScreenType
    
    let screenWidth : CGFloat
    
    func angle() -> Angle {
        if !(self.dragOffset == .zero) {
            return Angle(degrees: 90 * Double(screen - self.displayInfo.screenDisplayed)) + self.dragToRotation(translation: self.dragOffset)
        } else {
            return Angle(degrees: 0.0)
        }
    }
    
    func edge() -> UnitPoint {
        
        if (screen - self.displayInfo.screenDisplayed) == 0 {
            if dragOffset.width > 0 {
                return .leading
            } else {
                return .trailing
            }
        } else if (screen - self.displayInfo.screenDisplayed) > 0 {
            if dragOffset.width > 0 {
                return .trailing
            } else {
                return .leading
            }
        } else {
            if dragOffset.width > 0 {
                return .trailing
            } else {
                return .leading
            }
        }
    }
    
    func offSet() -> CGFloat {
        return screenWidth * CGFloat(screen - self.displayInfo.screenDisplayed) + self.dragOffset.width
    }
    
    func dragToRotation(translation : CGSize) -> Angle {
        
        return Angle(degrees: Double(translation.width/4.16))

    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(self.angle(), axis: (x: 0, y:1 , z:0), anchor: self.edge())
            .offset(x: self.offSet() , y: 0)
//            .animation(.linear)
            .animation(.easeOut).transition(.slide)
            .disabled(!(self.displayInfo.screenDisplayed == screen))
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GameScoreView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch) (3rd generation)"))
                .previewDisplayName("iPad Pro (11-inch) (3rd generation)")
            
            GameScoreView()
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))
                .previewDisplayName("iPhone X")
                .previewInterfaceOrientation(.landscapeLeft)
        }
        .environmentObject(GlobalDisplayInfo())
//        .environmentObject(Game(withTestPlayers: ()))
        .environmentObject(Game())
    }
}

//extension AnyTransition {
//    static var scaleAndOffset: AnyTransition {
//        AnyTransition.asymmetric(
//            insertion: .scale(scale: 0, anchor: .bottom),
//            removal: .offset(x: -600, y: 00)
//        )
//    }
//}


