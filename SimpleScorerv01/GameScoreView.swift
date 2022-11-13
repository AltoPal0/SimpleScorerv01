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
    
    @EnvironmentObject var game : Game
    @State private var shouldScroll = true
    @State var movingEdge = Edge.trailing
    
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
    
    var body: some View {
        
        ZStack {
            if colorScheme == .dark {
                Color.midnightBlue.edgesIgnoringSafeArea(.all).zIndex(-1)
            } else {
                Color.offWhite.edgesIgnoringSafeArea(.all).zIndex(-1)
            }
            if displayInfo.screenDisplayed == .allScores {
                AllScoresView_new()
                    .transition(.move(edge: .leading))
            }
            
            if displayInfo.screenDisplayed == .gameSetup {
                GameSetupView(showPlayerEntry: self.$showPlayerEntry)
                    .transition(.move(edge: .trailing))
            }
            
            if displayInfo.screenDisplayed == .scoreCards {
                ScoreCardsGridView()
                    .transition(.opacity)
            }
            
            BottomButtonsView(movingEdge: $movingEdge, showPlayerEntry: $showPlayerEntry)
            //
            //                if self.showImagePicker {
            //                    CircleImagePickerView(isPresented: self.$showImagePicker, selectedImage: self.$imagePicked, source: self.pickerSource)
            //                        .edgesIgnoringSafeArea(.all)
            //                }
            //
            if self.showPlayerEntry {
                PlayersEntryView(isVisible: self.$showPlayerEntry)
            }
            
        }
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


