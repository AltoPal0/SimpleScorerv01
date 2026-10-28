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
    
    var next: OrderBy {
        switch self {
        case .scoreUp : return .scoreDown
        case .scoreDown : return .players
        case .players : return .scoreUp
        }
    }
    
    var label: String {
        switch self {
        case .scoreUp : return "Highest first"
        case .scoreDown : return "Lowest first"
        case .players : return "Table order"
        }
    }
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
    // Short message naming the new order after a pull
    @State private var orderToast : String?
    
    func showOrderToast() {
        let order = orderedBy
        withAnimation {
            orderToast = order.label
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // A newer pull keeps its own message
            if orderedBy == order {
                withAnimation {
                    orderToast = nil
                }
            }
        }
    }
    
    // Cards of the round games never show the bottom bar
    var baseCardHeight: CGFloat {
        game.entersRounds || displayInfo.scoreCardSize == .compact ? 90 : 135
    }
    
    func layout(in size: CGSize) -> CardLayout {
        // Room for the bottom arrows and the New round button
        let reserved = CGFloat(70) + (game.entersRounds ? 100 : 0)
        return CardLayout.compute(width: size.width, height: size.height - reserved,
                                  players: game.playerScores.count, baseCardHeight: baseCardHeight)
    }
    
    // Same font for every name : what is left once the avatar and the widest total have their room
    func cardNames(for layout: CardLayout) -> CardNames {
        let scale = layout.scale
        let avatar = 135 * scale * 2 / 3
        let widestTotal = game.playerScores
            .map { CardNames.width(of: "\(game.total(for: $0))", size: 50 * scale, weight: .bold) }
            .max() ?? 0
        return CardNames.compute(players: game.playerScores.map { $0.player },
                                 availableWidth: layout.cardWidth - avatar - widestTotal - 40 * scale - 10,
                                 scale: scale)
    }
    
    var body: some View {
        GeometryReader { geometry in
        let layout = self.layout(in: geometry.size)
        ZStack{
            ScrollView {
                ScrollViewReader { value in
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(layout.cardWidth), spacing: CardLayout.spacing), count: layout.columns),
                              spacing: CardLayout.spacing) {
                        
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
                .environment(\.cardScale, layout.scale)
                .environment(\.cardNames, cardNames(for: layout))
                .padding(.vertical, CardLayout.spacing)
                .frame(maxWidth: .infinity)

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
            // Pulling down changes the order of the cards, not a real refresh
            .refreshable {
                withAnimation {
                    orderedBy = orderedBy.next
                }
                showOrderToast()
            }
            .onDrop(of: [UTType.text], delegate: DropResetDelegate {
                withAnimation {
                    draggedCard = nil
                    cardMoved = false
                }
            })
            
            if let toast = orderToast {
                VStack {
                    Text(toast)
                        .font(Font.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.offWhite)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                        .padding(.top, 12)
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .allowsHitTesting(false)
            }
            
//            if displayEditView {
//                EditView(playerIdx: idxForEditView, displayEditView: $displayEditView)
//                    .transition(.move(edge: .leading))
//                    .zIndex(50)
//            }
        }
        }
        .sheet(isPresented: $displayEditView) {
                    EditView(playerIdx: idxForEditView, displayEditView: $displayEditView)
                }
    }
}

struct NewRoundButton: View {
    var action : () -> Void

    var body: some View {
        // Discreet like the arrows at the bottom : the scores stay the main thing
        Label("New round", systemImage: "plus.circle")
            .font(.system(.title2, design: .rounded))
            .foregroundColor(.gray)
            // Just the width of its label
            .padding(.horizontal, 24)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                action()
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
