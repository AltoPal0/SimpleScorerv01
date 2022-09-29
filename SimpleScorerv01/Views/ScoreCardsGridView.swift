//
//  ScoreCardsGridView.swift
//  SimpleScorerv01
//
//  Created by Dev on 7/9/22.
//  Copyright © 2022 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct ScoreCardsGridView: View {
    
//    let screenWidth : CGFloat
    
    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    
    private var gridItemLayout = [GridItem(.adaptive(minimum: 300, maximum: 325), spacing: 20)]
    
    var body: some View {
        ZStack{
            ScrollView {
                LazyVGrid(columns: gridItemLayout, spacing: 20) {
                    ForEach((0..<self.game.playerScores.count), id: \.self) {
                        ScoreCardView(
                            playerScore:self.game.playerScores[$0],
                            index: $0
                        )
                    }
                }.padding()
            }//.animation(.none, value: 0)
        }
    }
}


struct ScoreCardsGridView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreCardsGridView()
            .environmentObject(GlobalDisplayInfo())
            .environmentObject(Game(withTestPlayers: ()))
//            .previewInterfaceOrientation(.landscapeLeft)
    }
}
