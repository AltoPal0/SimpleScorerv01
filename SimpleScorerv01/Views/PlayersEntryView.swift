//
//  PlayersEntryView.swift
//  SimpleScorerv01
//
//  Created by Dev on 6/4/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct PlayersEntryView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var game : Game
    @Binding var isVisible : Bool
    
    var frameHeight = CGFloat(90)
    
    @State private var username : String = ""
    
    @State private var cardViews = [CardView]()
    
    var body: some View {
        ZStack {
            
            if colorScheme == .dark {
                Color.midnightBlue.edgesIgnoringSafeArea(.all).zIndex(-1).zIndex(-Double(self.cardViews.count+1))
            } else {
                Color.offWhite.edgesIgnoringSafeArea(.all).zIndex(-1).zIndex(-Double(self.cardViews.count+1))
            }
            
            ZStack {
                ForEach(cardViews, id: \.playerScore.id) { cardView in
                    cardView
                        .frame(width:350, height: self.frameHeight)
                        .clipShape(Rectangle()).cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
                        .overlay(
                            HStack {
                                Rectangle().fill(Color.clear).frame(width: self.frameHeight, height: self.frameHeight)
                                
                                SATextField(tag: self.index(for: cardView.playerScore)!, placeholder: "Player #\(self.game.playerScores.firstIndex(where: { $0.id == cardView.playerScore.id })!+1)"
                                    , returnKey: self.cardViews.last?.playerScore.id == cardView.playerScore.id ? .done : .next
                                    , changeHandler: { (newString) in
                                    self.username = newString.capitalized.trimmingCharacters(in: .whitespacesAndNewlines)
                                    }
                                    , onCommitHandler: {
                                        if self.username == "" {
                                            self.username = "P\(self.game.playerScores.firstIndex(where: { $0.id == cardView.playerScore.id })!+1)"
                                        }
                                        self.commitNameAndMove(forIndex: self.game.playerScores.firstIndex(where: { $0.id == cardView.playerScore.id })!)
                                    })
                                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                                    .background(Color.offWhite.opacity(0.5))
                               

                                Rectangle().fill(Color.clear)
//                                    .border(width: 1, edge: .leading, color: .offWhite)
//                                    .overlay(Image(systemName: "chevron.right").foregroundColor(Color.white))
                                    .frame(width: 60, height: self.frameHeight)
//                                    .onTapGesture {
//                                        self.commitNameAndMove(forIndex: self.game.playerScores.firstIndex(where: { $0.id == cardView.playerScore.id })!)
//                                }
                            }
                        )
                        .zIndex(self.zIndex(for: cardView.playerScore))
                        .offset(self.offset(for: cardView.playerScore))
                        .scaleEffect(self.scale(for: cardView.playerScore))
                        .padding()
                        .animation(Animation .spring(), value: self.offset(for: cardView.playerScore))
                }
            }
            .offset(x: 0, y: -30)
            .onAppear {
                self.buildCardViews()
            }
        }
    }
    
    func commitNameAndMove(forIndex i : Int) {

        self.game.playerScores[i].player.name = self.username
        self.username = ""
        
        if self.cardViews.count > 0 {
            self.cardViews.removeFirst()
        }

        if self.cardViews.count == 0 {
            self.isVisible = false
            self.game.avatarInitialsForPlayers()
            AppStoreReviewManager.requestReviewIfAppropriate()
        }
        
    }
    
    private func buildCardViews () {
  
        for playerScore in game.playerScores {
            let index = self.game.playerScores.firstIndex(where: { $0.id == playerScore.id })
            
            if self.game.playerScores[index!].player.name == Player.defaultName {
                self.cardViews.append(CardView(playerScore: self.$game.playerScores[index!], username: self.$username,isFirstResponder: index == 0))
            }
        }
    }
    
    private func index(for playerScore: PlayerScore) -> Int? {

        guard let index = self.cardViews.firstIndex(where: { $0.playerScore.id == playerScore.id }) else {
            return nil
        }
        
//        print("\(playerScore.player.name) - \(self.cardViews.count) - \(index)")
           

        return index
    }
    
    private func zIndex(for playerScore: PlayerScore) -> Double {

        guard let cardIndex = index(for: playerScore) else {
            return 0.0
        }

        return -Double(cardIndex)
    }

    private func offset(for playerScore: PlayerScore) -> CGSize {

        guard let cardIndex = index(for: playerScore) else {
            return CGSize()
        }
        
        return CGSize(width: 0, height: -20 * CGFloat(cardIndex))
    }
    
    private func scale(for playerScore: PlayerScore) -> CGFloat {

        guard let cardIndex = index(for: playerScore) else {
            return 1
        }

        return max(CGFloat(100 - (cardIndex)*10)/100, 10/100)
    }
    
    private func isTopCard(cardView: CardView) -> Bool {

        guard let index = cardViews.firstIndex(where: { $0.id == cardView.id }) else {
            return false
        }

        return index == 0
    }
}

struct CardView: Identifiable, View {
    
    let id = UUID()
    @Binding var playerScore : PlayerScore
    @Binding var username : String
    let frameHeight = CGFloat(90)
    @State var isFirstResponder : Bool
    
    var body: some View {
        ZStack {
            
            playerScore.player.colorGradient
            
            VStack {
                
                Spacer()
                
                HStack {
                    
                    AvatarView(user: playerScore.player)
                        .padding(10)
                        .frame(width: self.frameHeight, height: self.frameHeight)
                    
                    Spacer()
                    
//                    Rectangle().fill(Color.clear)
//                        .border(width: 1, edge: .leading, color: .offWhite)
//                        .overlay(Image(systemName: "chevron.right").foregroundColor(Color.white))
//                        .frame(width: 60, height: self.frameHeight)
                    
                }
                Spacer()
            }
        }
    }
}

struct PlayersEntryView_Previews: PreviewProvider {
    static var previews: some View {
        PlayersEntryView(isVisible: .constant(true)).environmentObject(Game(withTestEmptyNamePlayers: ()))
    }
}
