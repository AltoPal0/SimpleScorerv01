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
    
    @Binding var orderedByScores : Bool
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 20)]
    
    var body: some View {
        ZStack{
            ScrollView {
                ScrollViewReader { value in
                    LazyVGrid(columns: gridItemLayout, spacing: 20) {
                        ForEach(game.playerScores.sorted(by: { pScore1, pScore2 in
                            
                            pScore1.totalScore() > pScore2.totalScore() && self.orderedByScores
                            ||
                            game.indexOf(player: pScore1.player)! < game.indexOf(player: pScore2.player)!

                        })) { playerScore in
                            ScoreCardView(playerScore:playerScore, scrollReaderProxy: value, orderByScores: $orderedByScores).id(playerScore.id)
                        }
                    }
                }
                .padding(20)
                
            }
//            .refreshable {
//                withAnimation {
//                    self.orderedByScores.toggle()
//                }
//            }
        }
    }
}



struct ScoreCardsGridView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreCardsGridView(orderedByScores: .constant(false))
            .environmentObject(GlobalDisplayInfo())
            .environmentObject(Game(withTestPlayers: ()))
//            .previewInterfaceOrientation(.landscapeLeft)
    }
}
