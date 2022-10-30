//
//  AllScoresView_new.swift
//  SimpleScorerv01
//
//  Created by Dev on 4/10/22.
//  Copyright © 2022 Stephane Giloppe. All rights reserved.
//

import SwiftUI

enum ScoreEditMode {
    case
    modification ,
    addition
}

var columnWidth: CGFloat = 80
var rowHeight: CGFloat = 80


struct AllScoresView_new: View {
    
    @EnvironmentObject var game : Game
    @State private var scrollViewContentSize: CGSize = .zero
    
    @State private var showKeypad = false
    
    @State var scoreEdit = (playerIdx: 0, round: 0, mode: ScoreEditMode.addition)
    
    var body: some View {
        ZStack{
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    ZStack {
                        
                        //background colors
                        HStack {
                            ForEach(0..<game.playerScores.count, id: \.self) { idx in
                                ColumnBack(player: game.playerScores[idx].player).padding(.horizontal,2)
                            }
                        }
                        .frame(maxHeight: scrollViewContentSize.height + 180)
                        
                        VStack (alignment: .center){
                            
                            // Initials
                            HStack() {
                                ForEach(0..<game.playerScores.count, id: \.self) { idx in
                                    AvatarView(user: game.playerScores[idx].player)
                                        .frame(width:columnWidth-10)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal,7)
                                }
                            }
                            
                            
                            //Points
                            ScrollView([.vertical]) {
                                HStack{
                                    ForEach(0..<game.playerScores.count, id: \.self) { playerIndex in
                                        PointsRows(maxNbrOfRounds: $game.maxNbrOfRounds, pointList: game.playerScores[playerIndex].pointsList, playerIndex: playerIndex, showKeypad: $showKeypad, scoreEdit: $scoreEdit)
                                            .padding(.horizontal,2)
                                        
                                    }.background(
                                        GeometryReader { geo -> Color in
                                            DispatchQueue.main.async {
                                                scrollViewContentSize = geo.size
                                            }
                                            return Color.clear
                                        }
                                    )
                                }
                            }
                            .frame(maxHeight: scrollViewContentSize.height)
                            
                            // Totals
                            HStack {
                                ForEach(0..<game.playerScores.count, id: \.self) { idx in
                                    TotalRows(totalScore: game.playerScores[idx].totalScore(), playerIndex: idx, showKeyPad: $showKeypad, scoreEdit: $scoreEdit)
                                        .frame(maxHeight: rowHeight)
                                        .padding(.horizontal,2)
                                }
                            }
                        }
                    }
                    .frame(minWidth: geometry.size.width)
                    .padding(.vertical, 25)
                }
            }
            if showKeypad {
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

struct ColumnBack: View {
    var player : Player
    
    var body: some View {
        ZStack {
            player.colorGradient.frame(width: columnWidth)
                .clipShape(Rectangle()).cornerRadius(14)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
            VStack {
                EmptyView()
                    .border(width: 1, edge: .bottom, color: .white)
                    .frame(width: columnWidth, height: rowHeight)
                    .padding(.vertical, 10)
                
                Spacer()
                
                EmptyView()
                    .border(width: 1, edge: .top, color: .white)
                    .frame(width: columnWidth, height: rowHeight)
            }
            
        }
    }
}

struct TotalRows: View {
    var totalScore: Int
    var playerIndex : Int
    @Binding var showKeyPad : Bool
    @Binding var scoreEdit : (playerIdx: Int, round: Int, mode: ScoreEditMode)
    
    var body: some View {
        LazyHGrid(
            rows: Array(
                repeating: .init(),
                count: 1
            )
        ) {
            Text("\(totalScore)")
                .font(Font.system(size: fontSize(nbrChar: String(totalScore).count, fontSize: 25)
                                  , weight: .bold
                                  , design: .rounded))
                .frame(width: columnWidth)
                .foregroundColor(.white)
                .onTapGesture(count: 1, perform: {
                    scoreEdit.playerIdx = playerIndex
                    scoreEdit.mode = .addition
                    self.showKeyPad = true
                })
        }
    }
}


struct PointsRows: View {
    @Binding var maxNbrOfRounds : Int
    var pointList: [Points]
    var playerIndex: Int
    
    @Binding var showKeypad : Bool
    
    @Binding var scoreEdit : (playerIdx: Int, round: Int, mode: ScoreEditMode)
    
    var body: some View {
        LazyHGrid(
            rows: Array(
                repeating: .init(.fixed(columnWidth/2)),
                count: maxNbrOfRounds
            )
        ) {
            ForEach(0..<maxNbrOfRounds, id: \.self) { round in
                Rectangle()
                    .fill(Color.white)
                    .opacity(0.1 + 0.2 * CGFloat(round % 2))
                    .frame(width: columnWidth)
                    .padding(.vertical, 0)
                    .overlay(
                        Cell(playerIndex: playerIndex, round: round, showKeypad: $showKeypad, scoreEdit: $scoreEdit)
                            .foregroundColor(Color.white)
                    )
            }
        }
    }
}

struct Cell: View {
    @EnvironmentObject var game : Game
    var playerIndex : Int
    var round : Int
    
    @State private var showingActionSheet = false
    
    @Binding var showKeypad : Bool
    @Binding var scoreEdit : (playerIdx: Int, round: Int, mode: ScoreEditMode)
    
    var body: some View {
        if game.playerScores[playerIndex].pointsList[optional: round] != nil {
            Text(game.playerScores[playerIndex].pointsList[round].score.description)
                .onTapGesture(count: 1, perform: {
                    self.showingActionSheet = true
                })
                .actionSheet(isPresented: $showingActionSheet) {
                    ActionSheet(title: Text("Edit score").font(.system(.headline, design: .rounded)), buttons: [
                        .default(Text("Modify")) {
                            scoreEdit.playerIdx = playerIndex
                            scoreEdit.mode = .modification
                            scoreEdit.round = round
                            self.showKeypad = true
                        },
                        .destructive(Text("Delete")) {
                            game.deletePointsFor(player: game.playerScores[playerIndex].player, round: round)
                        },
                        .cancel()
                    ])
                }
        }
    }
}

struct AllScoresView_new_Previews: PreviewProvider {
    static var previews: some View {
        AllScoresView_new()
            .environmentObject(Game(withTestPlayers: ()))
    }
}

extension Collection {
    
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
    
}

