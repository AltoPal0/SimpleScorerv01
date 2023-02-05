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
    @State var indexOfTopPlayer = 0
    @State var screenSize = CGSize.zero
    @State var isDragging = false
    
    var gridItemLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 10)]
    
    var backColor: Color {
        if colorScheme == .dark {
            return .midnightBlue
        } else {
            return .offWhite
        }
    }
    
    @State var previousPlayers =  try! JSONDecoder().decode([SavedPlayer].self, from: UserDefaults.standard.data(forKey: "previousPlayers") ?? JSONEncoder().encode([SavedPlayer]()))
    //    @State var previousPlayers = [SavedPlayer(name : "Stephane",counter : 3),SavedPlayer(name : "Sophie",counter : 1),SavedPlayer(name : "Chloe",counter : 1),SavedPlayer(name : "Gaby",counter : 2)]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backColor.edgesIgnoringSafeArea(.all).zIndex(-25)
                
                if isDragging {
                    VStack {
                        Spacer()
                        
                        Image(systemName: "trash.circle")
                            .font(.system(size: 40, weight: .ultraLight, design: .default))
                            .foregroundColor(Color.offRed)
                            .contentShape(Rectangle()).frame(width: 60)
                            .padding()
                    }.transition(.opacity)
                }
                
                VStack{
                    
                    ZStack{
                        ForEach(game.playerScores) { playerScore in
                            if playerScore.player.name == Player.defaultName {
                                NameCardView(
                                    playerScore: playerScore,
                                    index: self.game.playerScores.firstIndex(where: {$0.player.id == playerScore.player.id})!,
                                    focusedCard: $focusedCard,
                                    entryViewVisible: $isVisible,
                                    indexOfTopPlayer: $indexOfTopPlayer,
                                    numberOfPreviousPlayers: previousPlayers.count
                                )
                                .padding(.vertical)
                                .transition(.slide)
                            }
                        }
                    }
                    
                    if previousPlayers.count > 0 && !game.allPreviousPlayersSelected() {
                        HStack {
                            ZStack{
                                Divider().frame(height: 1).background(Color.gray).padding()
                            }
                            Text("OR").foregroundColor(.gray)
                            ZStack {
                                Divider().frame(height: 1).background(Color.gray).padding()
                            }
                        }
                        
                        LazyVGrid(columns: gridItemLayout,alignment: .center, spacing: 0) {
                            let maxPrevious = min(9,previousPlayers.count)
                            ForEach(0..<maxPrevious, id: \.self) { idx in
                                previousPlayerView(savedPlayers: $previousPlayers, focusedCard: $focusedCard, name: previousPlayers[idx].name, entryViewVisible: $isVisible, indexOfTopPlayer: $indexOfTopPlayer, geoProxy: geometry, isDragging: $isDragging)
                                    .padding(.vertical,2)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

struct previousPlayerView: View {
    @EnvironmentObject var game : Game
    @Binding var savedPlayers : [SavedPlayer]
    
    var focusedCard: FocusState<UUID?>.Binding
    var name : String
    @Binding var entryViewVisible : Bool
    
    @State var uuid : UUID?
    @State var grad : LinearGradient?
    
    @Binding var indexOfTopPlayer : Int
    
    @GestureState private var dragOffset = CGSize.zero
    @State private var isAboveTrash = false
    @State var geoProxy : GeometryProxy
    @Binding var isDragging : Bool
    
    @State private var startFeedbackPlayed = false
    @State private var trashFeedbackPlayed = false
    
    var body: some View {
        ZStack {
            
            ZStack {
                if !isAboveTrash {
                    LinearGradient(Color(hex: 0x136a8a),Color(hex: 0x267871))
                } else {
                    LinearGradient(Color(hex: 0xCB356B),Color(hex: 0xBD3F32))
                }
                
//                LinearGradient(Color(hex: 0x136a8a),Color(hex: 0x267871))
                
                Text(name)
                    .opacity(game.listNames().contains(name) ? 0.4 : 1)
                    .font(Font.system(size: 40, weight: .light, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .foregroundColor(Color.white)
                    .padding()
                
                Text(game.listNames().contains(name) ? "✓" : "")
                    .font(Font.system(size: 40, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .foregroundColor(Color.green)
            }
            .frame(height: 60)
            .clipShape(Rectangle()).cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isAboveTrash ? Color.offRed : Color.offWhite, lineWidth: isAboveTrash ? 2 : 1)
            )
            .offset(dragOffset)
            .opacity(game.listNames().contains(name) ? 0.5 : 1)
//            .scaleEffect(isAboveTrash ? 0.8 : 1, anchor: .bottom)
            .gesture(!game.listNames().contains(name) ?
                     DragGesture(coordinateSpace: .global)
                .updating($dragOffset) { value, state, transaction in
                    state.height = value.translation.height
                    state.width = value.translation.width
                    print("\(value.location.y) - \(geoProxy.size.height)")
                }
                .onChanged({ value in
                    if !startFeedbackPlayed {
                        let impactMed = UIImpactFeedbackGenerator(style: .soft)
                        impactMed.impactOccurred()
                        startFeedbackPlayed = true
                    }
                    if value.location.x > (geoProxy.size.width / 2) - 35
                        && value.location.x < (geoProxy.size.width / 2) + 35
                        && value.location.y > (geoProxy.size.height) - 30 {
                        if !trashFeedbackPlayed {
                            let impactMed = UIImpactFeedbackGenerator(style: .soft)
                            impactMed.impactOccurred()
                            trashFeedbackPlayed = true
                        }
                        isAboveTrash = true
                        withAnimation {
                            isDragging = true
                            
                        }
                        
                    } else {
                        isAboveTrash = false
                        trashFeedbackPlayed = false
                        withAnimation{
                            isDragging = true
                            
                        }
                    }
                    
                })
                    .onEnded({ (value) in
                        startFeedbackPlayed = false
                        trashFeedbackPlayed = false
                        if isAboveTrash {
                            self.savedPlayers.remove(at: self.savedPlayers.firstIndex(where: {$0.name == name})! )
                            UserDefaults.standard.set(try! JSONEncoder().encode(savedPlayers), forKey: "previousPlayers")
                            
                        }
                        withAnimation{
                            isAboveTrash = false
                            isDragging = false
                        }
                    }) : nil
            )
            .onTapGesture {
                
                var indexOfPlayer : Int {
                    if focusedCard.wrappedValue == nil {
                        return indexOfTopPlayer
                    } else {
                        return game.indexOf(playerID: focusedCard.wrappedValue!)!
                    }
                }
                
                withAnimation {
                    if game.listNames().contains(name) {
                        let indexOfPlayerUnSelecting = game.playerScores.firstIndex { pScore in
                            pScore.player.name == name
                        }
                        game.playerScores[indexOfPlayerUnSelecting!].player.name = Player.defaultName
                    } else {
                        game.playerScores[indexOfPlayer].player.name = name
                    }
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
                                self.indexOfTopPlayer = game.indexOf(playerID: pScore.player.id)!
                                
                                if focusedCard.wrappedValue != nil || game.allPreviousPlayersSelected() {
                                    self.focusedCard.wrappedValue = pScore.player.id
                                }
                                
                            }
                        }
                    }
                    
                }
            }
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
        }.transition(.asymmetric(insertion: .opacity, removal: .scale))
    }
    
    
}

struct NameCardView : View {
    
    @EnvironmentObject var game : Game
    
    var playerScore : PlayerScore
    var index : Int
    
    let frameHeight = CGFloat(90)
    
    @State var username = ""
    var focusedCard: FocusState<UUID?>.Binding
    @Binding var entryViewVisible : Bool
    @Binding var indexOfTopPlayer : Int
    
    //Hack
    @State var numberOfPreviousPlayers : Int
    
    
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
                if numberOfPreviousPlayers == 0 {
                    focusedCard.wrappedValue = playerScore.player.id
                }
                self.indexOfTopPlayer = game.indexOf(playerID: playerScore.player.id)!
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
