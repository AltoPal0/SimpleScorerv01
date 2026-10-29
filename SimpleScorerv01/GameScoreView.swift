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
    
    @State var dragOffset = CGSize.zero
    
    // The game can't be played with this number of players (Coinche with 5...)
    @State private var playerCountAlert = false
    
    // The game played stays on top of the scores screens
    var showGameHeader: Bool {
        self.game.rules != nil && self.displayInfo.screenDisplayed <= .scoreCards
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
                        
                        // Between the setup and the scores : the names of the players, then the game
                        GameEntryView()
                            .modifier(cubeRotation(dragOffset: $dragOffset, screen: .gameChoice, screenWidth: geometry.size.width))
                        
                        NameEntryView(isVisible: self.namesEntered)
                            .modifier(cubeRotation(dragOffset: $dragOffset, screen: .playerNames, screenWidth: geometry.size.width))
                        
                        GameSetupView()
                            .modifier(cubeRotation(dragOffset: $dragOffset, screen: .gameSetup, screenWidth: geometry.size.width))
                        
                        HistoryView()
                            .modifier(cubeRotation(dragOffset: $dragOffset, screen: .history, screenWidth: geometry.size.width))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: self.showGameHeader)
                .onAppear { self.updateDualLayout(dual) }
                // Leaving the setup for the scores : the number of players must suit the game
                .onChange(of: self.displayInfo.screenDisplayed) { previous, screen in
                    if (previous == .gameSetup || previous == .playerNames) && screen <= .scoreCards && self.game.hasWrongPlayerCount {
                        self.playerCountAlert = true
                    }
                }
                // A player removed (or added) on the scores screens : at once
                .onChange(of: self.game.playerScores.count) {
                    if self.displayInfo.screenDisplayed <= .scoreCards && self.game.hasWrongPlayerCount {
                        self.playerCountAlert = true
                    }
                }
                // No game anymore while on the scores (Change game) : the game is chosen again
                .onChange(of: self.game.needsGameChoice()) { _, needsGame in
                    if needsGame && self.displayInfo.screenDisplayed <= .scoreCards {
                        withAnimation {
                            self.displayInfo.screenDisplayed = .gameChoice
                        }
                    }
                }
                .onChange(of: dual) { self.updateDualLayout(dual) }
                
                TopSwiperView(dragOffset: $dragOffset, orderByScores: $orderedByScores)
                if self.displayInfo.showBottomButtons {
                    BottomButtonsView()
                }
            }
            
        }
        .alert(L("%@ is played with %@", self.game.rules?.displayName ?? "", self.game.rules?.playerCountHint ?? ""),
               isPresented: self.$playerCountAlert) {
            Button(L("Change game")) {
                self.game.rules = nil
            }
            Button(L("Back to players")) {
                withAnimation {
                    self.displayInfo.screenDisplayed = .gameSetup
                }
            }
            Button(L("Enter scores freely"), role: .cancel) {}
        } message: {
            Text(L("There are %ld players : the scores of %@ can't be counted.", self.game.playerScores.count, self.game.rules?.displayName ?? ""))
        }
        .alert(L("%@ isn't in %@ yet", self.displayInfo.gameToRequest ?? "", AppConfig.appName),
               isPresented: Binding(
                get: { self.displayInfo.gameToRequest != nil },
                set: { if !$0 { self.displayInfo.gameToRequest = nil } }),
               presenting: self.displayInfo.gameToRequest) { name in
            Button(L("Ask for it")) {
                Task { await GameRequests.request(game: name) }
            }
            Button(L("Not now"), role: .cancel) {
                GameRequests.markOffered(name)
            }
        } message: { _ in
            Text(L("Ask for its own score sheet and get a notification when it's ready. Meanwhile, scores are entered freely."))
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
    // Every player has a name : the game is chosen next, unless it already is
    var namesEntered: Binding<Bool> {
        Binding(
            get: { self.displayInfo.screenDisplayed == .playerNames },
            set: { visible in
                guard !visible else { return }
                withAnimation {
                    self.displayInfo.screenDisplayed = self.game.rules == nil ? .gameChoice : .scoreCards
                }
            })
    }
    
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
    
    // Jumping over screens (setup to scores) : those in between stay hidden
    var isSeen: Bool {
        screen == self.displayInfo.screenDisplayed || screen == self.displayInfo.previousScreen
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(self.angle(), axis: (x: 0, y:1 , z:0.0001), anchor: self.edge())
            .offset(x: self.offSet() , y: 0)
            .opacity(self.isSeen ? 1 : 0)
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


