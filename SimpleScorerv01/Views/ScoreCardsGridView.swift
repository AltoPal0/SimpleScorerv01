//
//  LazyVGridTest.swift
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
    
    private var gridItemLayout = Array(repeating: GridItem(.adaptive(minimum: 325, maximum: 325), spacing: 84), count: Int(((UIScreen.main.bounds.width) / 325).rounded(.down)))
    
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
                }
            }
            
            // bottom Scroll Buttons
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "arrow.left.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color.gray)
                        .background(Color.clear.opacity(0))
                        .onTapGesture {
                            self.displayInfo.screenDisplayed = .allScores
                            
                        }.padding()
                    Spacer()
                    Image(systemName: "arrow.right.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color.gray)
                        .background(Color.clear.opacity(0))
                        .onTapGesture {
                            self.displayInfo.screenDisplayed = .gameSetup
                        }.padding()
                }
            }
        }
    }
}


struct LazyVGridTest_Previews: PreviewProvider {
    static var previews: some View {
        ScoreCardsGridView()
            .environmentObject(GlobalDisplayInfo())
            .environmentObject(Game(withTestPlayers: ()))
    }
}
