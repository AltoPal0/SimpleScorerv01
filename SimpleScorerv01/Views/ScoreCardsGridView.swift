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
    
    @State var orderedByScores = false
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 20)]
    
    var body: some View {
        ZStack{
            ScrollView {
                PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                    withAnimation {
                        self.orderedByScores.toggle()
                    }
                }
                ScrollViewReader { value in
                    LazyVGrid(columns: gridItemLayout, spacing: 20) {
                        
                        ReorderableForEach(items: game.playerScores.sorted(by: { pScore1, pScore2 in
                            
                            pScore1.totalScore() > pScore2.totalScore() && self.orderedByScores
                            ||
                            game.indexOf(player: pScore1.player)! < game.indexOf(player: pScore2.player)!
                            
                        })) { playerScore in
                            ScoreCardView(playerScore:playerScore, scrollReaderProxy: value, orderByScores: $orderedByScores).id(playerScore.id)
                        } moveAction: { from, to in
                            game.playerScores.move(fromOffsets: from, toOffset: to)
                        }
                    }
                }
                .padding(20)
                
            }.coordinateSpace(name: "pullToRefresh")
        }
    }
}

struct PullToRefresh: View {

    var coordinateSpaceName: String
    var onRefresh: ()->Void

    @State var needRefresh: Bool = false

    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < 10) {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                } else {
                    Text("⇡↻⇣").font(.system(.largeTitle, design: .rounded)).foregroundColor(.gray)
                }
                Spacer()
            }
        }.padding(.top, -50)
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
