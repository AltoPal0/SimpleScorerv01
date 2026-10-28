//
//  GlobalDisplayInfo.swift
//  SimpleScorerv01
//
//  Created by Dev on 5/26/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

class GlobalDisplayInfo: ObservableObject {
    
    @Published var screenDisplayed = ScreenType.gameSetup
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

