//
//  ScoreCardsGridView.swift
//  SimpleScorerv01
//
//  Created by Dev on 7/9/22.
//  Copyright © 2022 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

enum OrderBy {
    case
    scoreUp ,
    scoreDown ,
    players
}

struct ScoreCardsGridView: View {
    
    //    let screenWidth : CGFloat
    
    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    
    @State var orderedBy = OrderBy.players
    
    @State var displayEditView = false
    @State private var draggedCard : PlayerScore?
    @State private var cardMoved = false
    @State var idxForEditView = 0
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 20)]
    
    var body: some View {
        ZStack{
            ScrollView {
                PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                    withAnimation {
                        switch orderedBy {
                        case .scoreUp : orderedBy = .scoreDown
                        case .scoreDown : orderedBy = .players
                        case .players : orderedBy = .scoreUp
                        }
                    }
                }
                ScrollViewReader { value in
                    LazyVGrid(columns: gridItemLayout, spacing: 20) {
                        
                        ReorderableForEach(items: game.playerScores.sorted(by: { pScore1, pScore2 in
                            
                            game.total(for: pScore1) > game.total(for: pScore2) && self.orderedBy == .scoreUp
                            ||
                            game.total(for: pScore1) < game.total(for: pScore2) && self.orderedBy == .scoreDown
                            ||
                            game.indexOf(player: pScore1.player)! < game.indexOf(player: pScore2.player)!
                            
                        }), draggingItem: $draggedCard, hasChangedLocation: $cardMoved) { playerScore in
                            ScoreCardView(playerScore:playerScore, scrollReaderProxy: value, indexForEditView: $idxForEditView, displayEditView: $displayEditView ).id(playerScore.id)
                        } moveAction: { from, to in
                            game.playerScores.move(fromOffsets: from, toOffset: to)
                        }
                    }
                }
                .padding(20)

                // Games scoring all the players at once : the round is entered for the whole table
                if game.entersRounds, let firstPlayer = game.playerScores.first?.player {
                    NewRoundButton {
                        displayInfo.roundEntryPlayerID = firstPlayer.id
                    }
                    .padding(.horizontal, 20)
                    // Room for the bottom arrows
                    .padding(.bottom, 80)
                }

            }
            .coordinateSpace(name: "pullToRefresh")
            .onDrop(of: [UTType.text], delegate: DropResetDelegate {
                withAnimation {
                    draggedCard = nil
                    cardMoved = false
                }
            })
            
//            if displayEditView {
//                EditView(playerIdx: idxForEditView, displayEditView: $displayEditView)
//                    .transition(.move(edge: .leading))
//                    .zIndex(50)
//            }
        }
        .sheet(isPresented: $displayEditView) {
                    EditView(playerIdx: idxForEditView, displayEditView: $displayEditView)
                }
    }
}

struct NewRoundButton: View {
    var action : () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange, Color.purple]), startPoint: UnitPoint(x: 0.2, y: 0.2), endPoint: UnitPoint(x: 0.8, y: 0.8)))
            .overlay(
                Text("NEW ROUND")
                    .fontWeight(.semibold)
                    .font(.system(.title, design: .rounded))
                    .foregroundColor(Color .offWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.offWhite, lineWidth: 1)
            )
            .frame(maxWidth: 600)
            .frame(height: 80)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                action()
            }
    }
}

struct PullToRefresh: View {

    var coordinateSpaceName: String
    var onRefresh: ()->Void

    @State var needRefresh: Bool = false
    @State private var degrees = 0.0

    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
                Spacer()
                    .onAppear {
                        needRefresh = true
                        withAnimation{
                            degrees = degrees + 180
                        }
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
//                    ProgressView()
                    Text("⇡↻⇣").font(.system(.largeTitle, design: .rounded)).foregroundColor(.gray)
                        .rotationEffect(.degrees(degrees))
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
