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
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 10)]
    
    var backColor: Color {
        if colorScheme == .dark {
            return .midnightBlue
        } else {
            return .offWhite
        }
    }
    
    @State var previousPlayers = UserDefaults.standard.array(forKey: "previousPlayers") as? [String]
    //    @State var previousPlayers = ["Stephane","Sophie","Chloe"]
    
    var body: some View {
        ZStack {
            backColor.edgesIgnoringSafeArea(.all).zIndex(-25)
            
            VStack{
                
                ZStack{
                    ForEach(game.playerScores) { playerScore in
                        if playerScore.player.name == Player.defaultName {
                            EntryView(
                                playerScore: playerScore,
                                index: self.game.playerScores.firstIndex(where: {$0.player.id == playerScore.player.id})!,
                                focusedCard: $focusedCard,
                                entryViewVisible: $isVisible
                            )
                            .padding()
                            .transition(.slide)
                        }
                    }
                }
                
                
                if previousPlayers != nil {
                    HStack {
                        ZStack{
                            Divider().frame(height: 1).background(Color.gray).padding()
                        }
                        Text("OR").foregroundColor(.gray)
                        ZStack {
                            Divider().frame(height: 1).background(Color.gray).padding()
                        }
                    }
                    
                    LazyVGrid(columns: gridItemLayout, spacing: 0) {
                        ForEach(0..<previousPlayers!.count, id: \.self) { idx in
                            previousPlayerView(focusedCard: $focusedCard, name: previousPlayers![idx], entryViewVisible: $isVisible).padding()
                        }
                    }
                }
            }
        }
    }
}

struct previousPlayerView: View {
    @EnvironmentObject var game : Game
    
    var focusedCard: FocusState<UUID?>.Binding
    var name : String
    @Binding var entryViewVisible : Bool
    
    @State var isSelected = false
    
    @State var uuid : UUID?
    @State var grad : LinearGradient?
    
    var body: some View {
        
        ZStack {
            LinearGradient.gradDefault
            Text(name)
                .opacity(isSelected ? 0.4 : 1)
                .font(Font.system(size: 40, weight: .light, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .foregroundColor(Color.offWhite)
                .padding()
            
            Text(isSelected ? "✓" : "")
                .font(Font.system(size: 40, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .foregroundColor(Color.green)
        }
        .frame(height: 60)
        .clipShape(Rectangle()).cornerRadius(14)
        .onTapGesture {
            let indexOfPlayer = game.indexOf(playerID: focusedCard.wrappedValue!)!
            
            withAnimation {
                if isSelected {
                    let indexOfPlayerUnSelecting = game.indexOf(playerID: self.uuid!)
                    game.playerScores[indexOfPlayerUnSelecting!].player.name = Player.defaultName
                } else {
                    self.uuid = focusedCard.wrappedValue!
                    game.playerScores[indexOfPlayer].player.name = name
                }
                isSelected.toggle()
            }
            
            if self.game.nbrPlayersUnanmed() == 0 {
                self.entryViewVisible = false
                self.game.avatarInitialsForPlayers()
                game.updatePreviousPlayers()
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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.offWhite, lineWidth: 1)
        )
        .opacity(isSelected ? 0.5 : 0.8)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
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
        let binding = Binding<String>(get: {
            self.username
        }, set: {
            self.username = $0.capitalized.trimmingCharacters(in: .whitespacesAndNewlines)
            // do whatever you want here
        })
        ZStack {
            
            playerScore.player.colorGradient

            HStack {
                
                AvatarView(user: playerScore.player)
                    .padding(10)
                
                TextField(Player.defaultName, text: binding, onCommit:{
                    self.username = binding.wrappedValue
                    commitName()
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
                        Text(self.game.nbrPlayersUnanmed() == 1 ? "✓" : " ⇢")
                            .foregroundColor(Color.offWhite)
                            .font(Font.system(size: 30, design: .rounded))
                    )
                    .frame(width: 80, height: self.frameHeight)
                    .onTapGesture {
                        commitName()
                    }
            }
        }
        .frame(width:350, height: self.frameHeight)
        .clipShape(Rectangle()).cornerRadius(14)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
        
        .onAppear{
            if self.game.indexOfPlayerWithNoName(playerScore: playerScore) == 0 {
                focusedCard.wrappedValue = playerScore.player.id
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.offWhite, lineWidth: 1)
        )
        .modifier(cardStackMove(playerScore: playerScore))
    }
    
    func commitName()  {
        
        if self.username == "" {
            self.username = "P\(index+1)"
        }
        
        withAnimation {
            game.playerScores[index].player.name = username
        }
        
        if self.game.nbrPlayersUnanmed() == 0 {
            self.entryViewVisible = false
            self.game.avatarInitialsForPlayers()
            self.game.updatePreviousPlayers()
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
