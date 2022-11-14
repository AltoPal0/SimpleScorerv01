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
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    @EnvironmentObject var game : Game
    
    @State private var shouldScroll = true
    @State var movingEdge = Edge.trailing
    @State var orderedByScores = false
    
    // PlayerEntry
    @State private var showPlayerEntry = false
    
    @State var dragOffset = CGSize.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if colorScheme == .dark {
                    Color.midnightBlue.edgesIgnoringSafeArea(.all).zIndex(-1)
                } else {
                    Color.offWhite.edgesIgnoringSafeArea(.all).zIndex(-1)
                }
                
                AllScoresView_new()
                    .modifier(cubeRotation(dragOffset: $dragOffset, screen: .allScores, screenWidth: geometry.size.width))
                
                GameSetupView(showPlayerEntry: self.$showPlayerEntry)
                    .modifier(cubeRotation(dragOffset: $dragOffset, screen: .gameSetup, screenWidth: geometry.size.width))
                
                ScoreCardsGridView( orderedByScores: $orderedByScores)
                    .onLongPressGesture {
                        withAnimation {
                            orderedByScores.toggle()
                        }
                    }
                    .modifier(cubeRotation(dragOffset: $dragOffset, screen: .scoreCards, screenWidth: geometry.size.width))
                
                TopSwiperView(dragOffset: $dragOffset, showPlayerEntry: $showPlayerEntry)
                
                if self.showPlayerEntry {
                    PlayersEntryView(isVisible: self.$showPlayerEntry)
                }
            }
            
        }
    }
}

struct cubeRotation: ViewModifier {
    
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    
    @Binding var dragOffset : CGSize
    
    let screen : ScreenType
    
    let screenWidth : CGFloat
    
    func angle() -> Angle {
        return Angle(degrees: 90 * Double(screen - self.displayInfo.screenDisplayed)) + self.dragToRotation(translation: self.dragOffset)
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
        return screenWidth * CGFloat(screen - self.displayInfo.screenDisplayed) + self.dragOffset.width*1.2
    }
    
    func dragToRotation(translation : CGSize) -> Angle {
        
        return Angle(degrees: Double(translation.width/4.16))

    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(self.angle(), axis: (x: 0, y:1 , z:0.0001), anchor: self.edge())
            .offset(x: self.offSet() , y: 0)
            .disabled(!(self.displayInfo.screenDisplayed == screen))
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GameScoreView()
                .previewDevice("iPhone X")
                .previewDisplayName("iPhone X")
            GameScoreView()
                .previewDevice("iPad Pro (11-inch) (2nd generation)")
                .previewDisplayName("iPad Pro")
            GameScoreView()
                .previewDevice("iPhone SE (2nd generation)")
                .previewDisplayName("iPhone SE")
            GameScoreView()
                .previewDevice("iPhone 13 mini")
                .previewDisplayName("iPhone mini")
            GameScoreView()
                .previewDevice("iPhone 14 Pro Max")
                .previewDisplayName("iPhone Pro Max")
        }
        .environmentObject(GlobalDisplayInfo())
        .environmentObject(Game(withTestPlayers: ()))
        //        .environmentObject(Game())
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


