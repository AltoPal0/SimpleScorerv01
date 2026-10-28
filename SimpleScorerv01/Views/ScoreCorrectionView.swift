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
            if game.playerScores[playerIndex].pointsList[optional: round] != nil {
                return "\(game.total(for: game.playerScores[playerIndex])) \(self.sign >= 0 ? "+" : "-") \(String(format: "%.0f",abs(pointsScored)))"
            } else {
                return " • \(self.sign >= 0 ? "+" : "-") \(String(format: "%.0f",abs(pointsScored)))"
            }
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
                                size: 30,
                                weight: .bold,
                                design: .rounded))
//                            .scaledToFill()
                            .minimumScaleFactor(0.9)
                            .lineLimit(2)
                            .foregroundColor(Color .offWhite)
                            .padding(.horizontal,20)
                        
                        Spacer()
                        
                        Rectangle().fill(Color.offWhite.opacity(0.5))
                            .border(width: 1, edge: .leading, color: .offWhite)
                            .overlay(Image(systemName: "checkmark").foregroundColor(Color.white))
                            .frame(minWidth:70, maxWidth:70, maxHeight: .infinity)
                            .onTapGesture {
                                commit(Int(pointsScored * sign))
                            }
                    }
                    .frame(height: geo.size.height/3)
                    
                    // The keypad of the game, as on the cards
                    if game.activeKind == .molkky {
                        MolkkyPadView { points in
                            commit(points)
                        }
                    } else {
                        KeyPadView(valueDisplayed: $pointsScored, sign: $sign,
                                   extraKey: game.activeKind == .scrabble ? "+50" : nil,
                                   onExtraKey: { pointsScored += 50 })
                    }
                    
                }
                
            }
            .clipShape(Rectangle()).cornerRadius(14)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
            
        }
    }
}

extension ScoreCorrectionView {
    func commit(_ points: Int) {
        if editMode == .modification {
            game.modifyPointsFor(player: game.playerScores[playerIndex].player, round: round, points: points)
        } else if game.playerScores[playerIndex].pointsList[optional: round] != nil {
            game.addPointsFor(player: game.playerScores[playerIndex].player, points: points)
        } else {
            // modification of an empty cell is like addition at specific round
            game.addPointsFor(player: game.playerScores[playerIndex].player, points: points, round: round)
        }
        showKeypad = false
        sign = 1
        pointsScored = 0
    }
}

struct ScoreCorrectionView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreCorrectionView(editMode: .modification, playerIndex: 0, round: 0, showKeypad: .constant(true))
            .environmentObject(Game(withTestPlayers: ()))
            .frame(width: 300, height: 200)
    }
}
