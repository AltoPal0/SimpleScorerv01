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
    @Published var gradients = gradiants.shuffled()
    @Published var scoreCardSize = CardSize.compact

    func setSizeAndScroll (nbrPlayers : Int/*, screenSize : CGSize*/) {
        
        let screenAera = Double(UIScreen.main.bounds.size.width * UIScreen.main.bounds.size.height)
        let cardAera = 325 * 135 * 1.3
        
        // SCoreCards View
        self.scoreCardSize = .normal
        
        if Double(nbrPlayers + 1) * cardAera > screenAera {
            print(nbrPlayers * 325 * 135)
            print(screenAera)
            print(cardAera)
            self.scoreCardSize = .compact
        }
        
        if nbrPlayers == 0 {
            self.screenDisplayed = .gameSetup
        }
        
//        self.shouldScroll = true
        
        // All Scores View        
    }
}

