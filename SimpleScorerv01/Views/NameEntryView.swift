//
//  NameEntryView.swift
//  SimpleScorerv01
//
//  Created by Dev on 19/11/22.
//  Copyright © 2022 Stephane Giloppe. All rights reserved.
//

import SwiftUI

enum Focusable: Hashable {
  case none
  case row(id: UUID)
}

struct NameEntryView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var game : Game
    @Binding var isVisible : Bool
    
    @FocusState var focusedCard: UUID?
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Color.midnightBlue.edgesIgnoringSafeArea(.all).zIndex(-25)
            } else {
                Color.offWhite.edgesIgnoringSafeArea(.all).zIndex(-25)
            }

            ForEach(game.playerScores) { playerScore in
                if playerScore.player.name == Player.defaultName {
                EntryView(playerScore: playerScore, index: self.game.playerScores.firstIndex(where: {$0.player.id == playerScore.player.id})!, focusedCard: $focusedCard, entryViewVisible: $isVisible)
                        .padding()
                        .transition(.slide)
                }
            }
        }
    }
}

struct EntryView : View {
    
    @EnvironmentObject var game : Game

    var playerScore : PlayerScore
    var index : Int
    
    let frameHeight = CGFloat(90)
    
    @State var username = ""
    var focusedCard: FocusState<UUID?>.Binding
    @Binding var entryViewVisible : Bool
    
    
    var body: some View {
        ZStack {
            
            playerScore.player.colorGradient
            
            VStack {
                
                Spacer()
                
                HStack {
                    
                    Text(self.game.indexOfPlayerWithNoName(playerScore: playerScore).description)
                    
                    AvatarView(user: playerScore.player)
                        .padding(10)
                        
                    TextField(Player.defaultName, text: $username, onCommit:{
                        withAnimation {
                            commitName()
                        }
                    })
                        .font(Font.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundColor(.offWhite)
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .focused(focusedCard, equals: playerScore.player.id)
                    
                    Spacer()
                    
                    Rectangle().fill(Color.clear)
                        .border(width: 1, edge: .leading, color: .offWhite)
                        .overlay(
                            Text("✓")
                                .foregroundColor(Color.offWhite)
                                .font(Font.system(size: 30, design: .rounded))
                        )
                        .frame(width: 80, height: self.frameHeight)
                        .onTapGesture {
                            withAnimation {
                                commitName()
                            }
                        }
                    
                }
                Spacer()
            }
        }
        .frame(width:350, height: self.frameHeight)
        .clipShape(Rectangle()).cornerRadius(14)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
        .modifier(cardStackMove(playerScore: playerScore))
        .onAppear{
            if self.game.indexOfPlayerWithNoName(playerScore: playerScore) == 0 {
                focusedCard.wrappedValue = playerScore.player.id
            }
        }
        .onDisappear{
            
            
        }
    }
    
    func commitName()  {

        if self.username == "" {
            self.username = "P\(index+1)"
        }
        game.playerScores[index].player.name = username
        
        if !self.game.needsNameEntry() {
            self.entryViewVisible = false
            self.game.avatarInitialsForPlayers()
            AppStoreReviewManager.requestReviewIfAppropriate()
        } else {
            DispatchQueue.main.async() {
                for pScore in game.playerScores {
                    if self.game.indexOfPlayerWithNoName(playerScore: pScore) == 0 {
                        self.focusedCard.wrappedValue = pScore.player.id
                    }
                }
            }
        }
        
    }
    
}

struct cardStackMove: ViewModifier {
    
    @EnvironmentObject var game : Game
    var playerScore : PlayerScore
    
    private func indexNoName (for playerScore: PlayerScore) -> Int? {
        return self.game.indexOfPlayerWithNoName(playerScore: playerScore)
    }
    
    private func index(for playerScore: PlayerScore) -> Int? {
        guard let index = self.game.playerScores.firstIndex(where: { $0.id == playerScore.id})
            else {
            return 0
        }
        return index
    }
    
    private func zIndex(for playerScore: PlayerScore) -> Double {

        guard let cardIndex = indexNoName(for: playerScore) else {
            return 0.0
        }

        return -Double(cardIndex)
    }

    private func offset(for playerScore: PlayerScore) -> CGSize {

        guard let cardIndex = indexNoName(for: playerScore) else {
            return CGSize()
        }
        
        return CGSize(width: 0, height: -20 * CGFloat(cardIndex))
    }
    
    private func scale(for playerScore: PlayerScore) -> CGFloat {

        guard let cardIndex = indexNoName(for: playerScore) else {
            return 1
        }

        return max(CGFloat(100 - (cardIndex)*10)/100, 10/100)
    }
    
    func body(content: Content) -> some View {
        content
            .zIndex(self.zIndex(for: playerScore))
            .offset(self.offset(for: playerScore))
            .scaleEffect(self.scale(for: playerScore))
    }
    
}



struct NameEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NameEntryView(isVisible: .constant(true))
            .environmentObject(Game(withTestEmptyNamePlayers: ()))
    }
}
