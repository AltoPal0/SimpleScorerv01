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
    @State var orderedByScores = false
    
    // PlayerEntry
    @State private var showPlayerEntry = false
    
    @State var dragOffset = CGSize.zero
    
    // The game can't be played with this number of players (Coinche with 5...)
    @State private var playerCountAlert = false
    
    // The game played stays on top of the scores screens
    var showGameHeader: Bool {
        self.game.rules != nil && self.displayInfo.screenDisplayed < .gameSetup && !self.showPlayerEntry
    }
    
    // Width of the columns of scores : 64 per column with its spacing, and the side margins
    func columnsWidth() -> CGFloat {
        CGFloat(self.game.playerScores.count) * 72 + 48
    }
    
    // Enough room for the columns next to the cards (iPad)
    func isDual(width: CGFloat) -> Bool {
        width >= 900 && !self.game.playerScores.isEmpty && columnsWidth() <= width * 0.45
    }
    
    var body: some View {
        GeometryReader { geometry in
            let dual = self.isDual(width: geometry.size.width)
            ZStack {
                if colorScheme == .dark {
                    Color.midnightBlue.edgesIgnoringSafeArea(.all).zIndex(-1)
                } else {
                    Color.offWhite.edgesIgnoringSafeArea(.all).zIndex(-1)
                }
                VStack(spacing: 0) {
                    if self.showGameHeader {
                        GameHeaderView()
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }
                    
                    ZStack {
                        if dual {
                            HStack(spacing: 0) {
                                AllScoresView_new()
                                    .frame(width: self.columnsWidth())
                                ScoreCardsGridView()
                            }
                            .modifier(cubeRotation(dragOffset: $dragOffset, screen: .scoreCards, screenWidth: geometry.size.width))
                        } else {
                            AllScoresView_new()
                                .modifier(cubeRotation(dragOffset: $dragOffset, screen: .allScores, screenWidth: geometry.size.width))
                            
                            ScoreCardsGridView()
                                .modifier(cubeRotation(dragOffset: $dragOffset, screen: .scoreCards, screenWidth: geometry.size.width))
                        }
                        
                        GameSetupView(showPlayerEntry: self.$showPlayerEntry)
                            .modifier(cubeRotation(dragOffset: $dragOffset, screen: .gameSetup, screenWidth: geometry.size.width))
                        
                        HistoryView()
                            .modifier(cubeRotation(dragOffset: $dragOffset, screen: .history, screenWidth: geometry.size.width))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: self.showGameHeader)
                .onAppear { self.updateDualLayout(dual) }
                // Leaving the setup for the scores : the number of players must suit the game
                .onChange(of: self.displayInfo.screenDisplayed) { previous, screen in
                    if previous == .gameSetup && screen < .gameSetup && self.game.hasWrongPlayerCount {
                        self.playerCountAlert = true
                    }
                }
                // A player removed (or added) on the scores screens : at once
                .onChange(of: self.game.playerScores.count) {
                    if self.displayInfo.screenDisplayed < .gameSetup && self.game.hasWrongPlayerCount {
                        self.playerCountAlert = true
                    }
                }
                .onChange(of: dual) { self.updateDualLayout(dual) }
                
                TopSwiperView(dragOffset: $dragOffset, showPlayerEntry: $showPlayerEntry, orderByScores: $orderedByScores)
                if self.displayInfo.showBottomButtons {
                    BottomButtonsView(showPlayerEntry: $showPlayerEntry)
                }
                
                if self.showPlayerEntry {
                    NameEntryView(isVisible: self.$showPlayerEntry)
                } else if self.game.needsGameChoice() && self.displayInfo.screenDisplayed < .gameSetup {
                    GameEntryView()
                        .transition(.opacity)
                }
            }
            
        }
        .alert("\(self.game.rules?.name ?? "") is played with \(self.game.rules?.playerCountHint ?? "")",
               isPresented: self.$playerCountAlert) {
            Button("Change game") {
                self.game.rules = nil
            }
            Button("Back to players") {
                withAnimation {
                    self.displayInfo.screenDisplayed = .gameSetup
                }
            }
            Button("Enter scores freely", role: .cancel) {}
        } message: {
            Text("There are \(self.game.playerScores.count) players : the scores of \(self.game.rules?.name ?? "") can't be counted.")
        }
        .alert("\(self.displayInfo.gameToRequest ?? "") isn't in \(AppConfig.appName) yet",
               isPresented: Binding(
                get: { self.displayInfo.gameToRequest != nil },
                set: { if !$0 { self.displayInfo.gameToRequest = nil } }),
               presenting: self.displayInfo.gameToRequest) { name in
            Button("Ask for it") {
                Task { await GameRequests.request(game: name) }
            }
            Button("Not now", role: .cancel) {
                GameRequests.markOffered(name)
            }
        } message: { _ in
            Text("Ask for its own score sheet and get a notification when it's ready. Meanwhile, scores are entered freely.")
        }
        .sheet(isPresented: Binding(
            get: { self.displayInfo.roundEntryPlayerID != nil },
            set: { if !$0 { self.displayInfo.roundEntryPlayerID = nil } })) {
                if let playerID = self.displayInfo.roundEntryPlayerID {
                    RoundEntryView(playerID: playerID)
                        .environmentObject(self.game)
                        .environmentObject(self.displayInfo)
                }
            }
    }
}

extension GameScoreView {
    func updateDualLayout(_ dual: Bool) {
        self.displayInfo.isDualLayout = dual
        // The columns are already next to the cards
        if dual && self.displayInfo.screenDisplayed == .allScores {
            self.displayInfo.screenDisplayed = .scoreCards
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


