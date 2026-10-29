//
//  GlobalDisplayInfo.swift
//  SimpleScorerv01
//
//  Created by Dev on 5/26/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

class GlobalDisplayInfo: ObservableObject {
    
    @Published var screenDisplayed = ScreenType.gameSetup {
        didSet {
            if oldValue != screenDisplayed {
                previousScreen = oldValue
            }
        }
    }
    // Screen left by the last move : with the one displayed, the only ones seen while the screens slide
    var previousScreen = ScreenType.gameSetup
    @Published var indexOFTextfieldFocused : Int = 1000
    // Gradients still free for new players, as indices in the gradiants palette
    @Published var gradientIndices = Array(gradiants.indices).shuffled()
    @Published var scoreCardSize = CardSize.compact
    @Published var showBottomButtons = true
    // Player tapped to enter a whole round (deal, mène) : the round entry sheet is shown when set
    @Published var roundEntryPlayerID : UUID? {
        didSet {
            if roundEntryPlayerID == nil {
                roundEntryPreselects = true
            }
        }
    }
    // false when opened by New round : no player was chosen, the taker of Tarot starts empty
    var roundEntryPreselects = true
    // Game typed by the players and missing from the library : they are offered to ask for it
    @Published var gameToRequest : String?
    // Large screens : the columns of scores and the cards side by side, the columns screen alone is skipped
    @Published var isDualLayout = false
    // The bar with the name of the game and its options : hidden while playing, a short pull on the cards shows it
    @Published var showsGameHeader = false

    func setSizeAndScroll (nbrPlayers : Int/*, screenSize : CGSize*/) {
        
        let screenAera = Double(UIScreen.main.bounds.size.width * UIScreen.main.bounds.size.height)
        let cardAera = 325 * 135 * 1.3
        
        // SCoreCards View
        self.scoreCardSize = .normal
        
        if Double(nbrPlayers + 1) * cardAera > screenAera {
//            print(nbrPlayers * 325 * 135)
//            print(screenAera)
//            print(cardAera)
            self.scoreCardSize = .compact
        }
        
        if nbrPlayers == 0 {
            self.screenDisplayed = .gameSetup
        }
        
//        self.shouldScroll = true
        
        // All Scores View        
    }
}

// Moves between the screens, the same for the arrows at the bottom and the swipes from the edges
extension GlobalDisplayInfo {

    // Screen on the left, nil when there is nothing to go to yet
    func screenOnLeft(game: Game) -> ScreenType? {
        switch screenDisplayed {
        case .allScores:
            return nil
        case .scoreCards:
            // Large screens : the columns are already next to the cards
            return isDualLayout ? nil : .allScores
        case .gameChoice:
            // Back to the scores once a game is chosen
            return game.rules == nil ? nil : .scoreCards
        case .playerNames:
            return game.playerScores.isEmpty || game.nbrPlayersUnanmed() > 0 ? nil : .gameChoice
        case .gameSetup:
            guard !game.playerScores.isEmpty else { return nil }
            // A game already going on : straight back to its scores
            return game.rules != nil && game.nbrPlayersUnanmed() == 0 ? .scoreCards : .playerNames
        case .history:
            return .gameSetup
        }
    }

    // Screen on the right, nil when there is none
    func screenOnRight(game: Game) -> ScreenType? {
        switch screenDisplayed {
        case .allScores: return .scoreCards
        // Once the game is going on : back to the setup, where the scores are reset
        case .scoreCards: return .gameSetup
        case .gameChoice: return .playerNames
        case .playerNames: return .gameSetup
        case .gameSetup: return .history
        case .history: return nil
        }
    }

    // Play from the setup : the first thing still missing, the players' names then the game, or the scores
    func screenAfterSetup(game: Game) -> ScreenType {
        if game.nbrPlayersUnanmed() > 0 {
            return .playerNames
        }
        return game.rules == nil ? .gameChoice : .scoreCards
    }

    func moveLeft(game: Game) {
        if let screen = screenOnLeft(game: game) {
            withAnimation {
                screenDisplayed = screen
            }
        }
    }

    func moveRight(game: Game) {
        if let screen = screenOnRight(game: game) {
            withAnimation {
                screenDisplayed = screen
            }
        }
    }
}
