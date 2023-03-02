//
//  EditView.swift
//  SimpleScorerv01
//
//  Created by Dev on 5/2/23.
//  Copyright © 2023 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct EditView: View {
    
    @EnvironmentObject var game : Game
    @State private var scrollViewContentSize: CGSize = .zero
    
    @State private var showKeypad = false
    
    @State var scoreEdit = (playerIdx: 0, round: 0, mode: ScoreEditMode.addition)
    
    var playerIdx : Int
    var frameWidth = CGFloat(100)
    @Binding var displayEditView : Bool
    
    @State private var showingActionSheet = false
    @State private var username = ""
    @State private var editName = false
    
    @FocusState private var focusedField: Field?
    
    private enum Field:Int, Hashable {
        case  name
    }
    
    var body: some View {
        ZStack{
            game.playerScores[playerIdx].player.colorGradient.edgesIgnoringSafeArea(.all)
            
            VStack{
                
                
                HStack{
                    Image(systemName: "x.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color.offWhite)
                        .background(Circle().foregroundColor(Color .clear))
                        .onTapGesture {
                            withAnimation{
                                displayEditView = false
                            }
                        }.padding()
                    Spacer()
                }
                
                Spacer()
            }
            VStack {
                if editName {
                    // Name
                    ZStack {
                        
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.offWhite, lineWidth: 1)
//                            .background(Color.black.opacity(0.3))
                            .frame(height: frameWidth)
                        
                        TextField(game.playerScores[playerIdx].player.name, text: $username,onEditingChanged: {change in },
                                  onCommit: {
                            withAnimation{
                                game.playerScores[playerIdx].player.name = username.capitalized.trimmingCharacters(in: .whitespacesAndNewlines)
                                self.editName = false
                                self.game.avatarInitialsForPlayers()
                            }
                        })
                            .focused($focusedField, equals: .name)
                            .multilineTextAlignment(.center)
                            .font(Font.system(size: 80, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                            .foregroundColor(Color .offWhite)
                        
                    }
                }
                
                ZStack {
                    VStack {
                        // Initials
                        AvatarView(user: game.playerScores[playerIdx].player)
                            .padding(7)
                            .border(width: 1, edge: .bottom, color: .white)
                            .frame(height: frameWidth)
                            .onTapGesture {
                                withAnimation{
                                    self.editName = true
                                }
                                self.focusedField = .name
                            }
                        
                        //Points
                        ScrollView([.vertical]) {
                            VStack{
                                ForEach(game.playerScores[playerIdx].pointsList, id: \.self) { points in
                                    Cell(playerIndex: playerIdx, round: points.round, showKeypad: $showKeypad, scoreEdit: $scoreEdit)
                                        .frame(minWidth: frameWidth, minHeight: 50)
                                        .foregroundColor(Color.white)
                                        .background(Color.white.opacity(0.1 + 0.2 * CGFloat(points.round % 2)))
                                    
                                }
                            }
                        }
                        
                        // Totals
                        HStack {
                            let totalScore = game.playerScores[playerIdx].totalScore()
                            Text("\(totalScore < 10000 ? String(totalScore) : String(totalScore / 1000)+"K")")
                                .font(Font.system(size: fontSize(nbrChar: String(totalScore).count, fontSize: 50)
                                                  , weight: .bold
                                                  , design: .rounded))
                                .scaledToFit()
                                .minimumScaleFactor(0.4)
                                .frame(width: columnWidth)
                                .foregroundColor(.white)
                                .onTapGesture(count: 1, perform: {
                                    scoreEdit.playerIdx = playerIdx
                                    scoreEdit.mode = .addition
                                    self.showKeypad = true
                                })
                            
                        }
                        .border(width: 1, edge: .top, color: .white)
                        .frame(maxHeight: frameWidth)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.offWhite, lineWidth: 1)
                    )
                }
                .frame(width: frameWidth)
                .padding()
            }
            
            if showKeypad {
                ZStack{
                    Color.black.edgesIgnoringSafeArea(.all).opacity(0.5)
                    VStack {
                        Spacer()
                        
                        ScoreCorrectionView(editMode: scoreEdit.mode, playerIndex: scoreEdit.playerIdx, round: scoreEdit.round, showKeypad: $showKeypad)
                            .frame(maxWidth: 350, maxHeight: 300)
                            .padding(.bottom,50)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(playerIdx: 0, displayEditView: .constant(true))
            .environmentObject(Game(withTestPlayers: ()))
    }
}
