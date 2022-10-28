//
//  ScoreCorrectionView.swift
//  SimpleScorerv01
//
//  Created by Dev on 18/10/22.
//  Copyright © 2022 Stephane Giloppe. All rights reserved.
//

import SwiftUI



struct ScoreCorrectionView: View {
    
    @EnvironmentObject var game : Game
    
    var editMode : ScoreEditMode
    var playerIndex : Int
    var round : Int
    
    @Binding var showKeypad : Bool
    
    var display : String {
        if editMode == ScoreEditMode.modification {
            return "\(String(game.playerScores[playerIndex].pointsList[round].score)) ⇢ \(self.sign >= 0 ? "" : "-") \( String(format: "%.0f",abs(pointsScored)))"
        } else {
            return "\(game.playerScores[playerIndex].totalScore()) \(self.sign >= 0 ? "+" : "-") \(String(format: "%.0f",abs(pointsScored)))"
        }
    }
    
    @State var sign = CGFloat(1)
    @State var pointsScored = CGFloat(0)
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                
                game.playerScores[playerIndex].player.colorGradient
                
                VStack {
                    HStack {
                        Image(systemName: "xmark").foregroundColor(Color.white)
                            .contentShape(Rectangle()).frame(width: 60, height: 60)
                            .offset(x: -10, y: -10)
                            .onTapGesture(count: 1, perform: {
                                showKeypad = false
                                sign = 1
                                pointsScored = 0
                            })
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                
                VStack (spacing:0){
                    
                    HStack {
                        Spacer()
                        
                        Text(display)
                            .font(Font.system(
                                size: fontSize(nbrChar: display.count - 2, fontSize: 50),
                                weight: .bold,
                                design: .rounded))
                            .scaledToFill()
                            .minimumScaleFactor(0.9)
                            .lineLimit(1)
                            .foregroundColor(Color .offWhite)
                            .padding(.horizontal,20)
                        
                        Spacer()
                        
                        Rectangle().fill(Color.offWhite.opacity(0.5))
                            .border(width: 1, edge: .leading, color: .offWhite)
                            .overlay(Image(systemName: "checkmark").foregroundColor(Color.white))
                            .frame(minWidth:70, maxWidth:70, maxHeight: .infinity)
                            .onTapGesture {
                                if editMode == .modification {
                                    game.modifyPointsFor(player: game.playerScores[playerIndex].player, round: round, points: Int(pointsScored * sign))
                                    showKeypad = false
                                    sign = 1
                                    pointsScored = 0
                                } else {
                                    game.addPointsFor(player: game.playerScores[playerIndex].player, points: Int(pointsScored * sign))
                                    showKeypad = false
                                    sign = 1
                                    pointsScored = 0
                                }
                            }
                    }
                    .frame(height: geo.size.height/3)
                    
                    KeyPadView(valueDisplayed: $pointsScored, sign: $sign)
                    
                }
                
            }
            .clipShape(Rectangle()).cornerRadius(14)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
            
        }
    }
}

struct ScoreCorrectionView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreCorrectionView(editMode: .modification, playerIndex: 0, round: 0, showKeypad: .constant(true))
            .environmentObject(Game(withTestPlayers: ()))
            .frame(width: 300, height: 200)
    }
}
