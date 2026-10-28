//
//  GameEntryView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Asked once the players are named : which game are we playing ?
struct GameEntryView: View {

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var game : Game

    @State private var gameName = ""
    @State private var recentGames = RecentGames.load()
    @State private var isDragging = false
    @FocusState private var fieldFocused : Bool

    let frameHeight = CGFloat(90)
    let maxChoices = 9

    var gridItemLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 10)]

    var backColor: Color {
        colorScheme == .dark ? .midnightBlue : .offWhite
    }

    // Library games matching what is typed, or the recent games when nothing is typed yet
    var choices : [GameChoice] {
        if gameName.isEmpty {
            return recentGames.prefix(maxChoices).map { GameChoice(name: $0.name, isRecent: true) }
        }

        let recentMatches = recentGames
            .filter { GameLibrary.rules(named: $0.name).matches(gameName) }
            .map { GameChoice(name: $0.name, isRecent: true) }
        let libraryMatches = GameLibrary.suggestions(for: gameName)
            .filter { game in !recentMatches.contains { GameRules.normalized($0.name) == GameRules.normalized(game.name) } }
            .map { GameChoice(name: $0.name, isRecent: false) }

        return Array((recentMatches + libraryMatches).prefix(maxChoices))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backColor.edgesIgnoringSafeArea(.all)

                if isDragging {
                    VStack {
                        Spacer()
                        Image(systemName: "trash.circle")
                            .font(.system(size: 40, weight: .ultraLight, design: .default))
                            .foregroundColor(Color.offRed)
                            .padding()
                    }.transition(.opacity)
                }

                VStack {
                    gameCard
                        .padding(.vertical)

                    if !choices.isEmpty {
                        HStack {
                            ZStack {
                                Divider().frame(height: 1).background(Color.gray).padding()
                            }
                            Text("OR").foregroundColor(.gray)
                            ZStack {
                                Divider().frame(height: 1).background(Color.gray).padding()
                            }
                        }

                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 0) {
                            ForEach(choices, id: \.name) { choice in
                                GameChoiceView(choice: choice, containerSize: geometry.size, isDragging: $isDragging) {
                                    choose(name: choice.name)
                                } onTrash: {
                                    withAnimation {
                                        RecentGames.remove(name: choice.name)
                                        recentGames = RecentGames.load()
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding()
                    }

                    Spacer()
                }
            }
        }
        .coordinateSpace(name: GameChoiceView.coordinateSpace)
        .onAppear {
            // Same as for players : keyboard first only when there is nothing to pick
            if recentGames.isEmpty {
                fieldFocused = true
            }
        }
    }

    var gameCard: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange, Color.purple]), startPoint: UnitPoint(x: 0.2, y: 0.2), endPoint: UnitPoint(x: 0.8, y: 0.8))

            HStack {
                Image(systemName: "dice")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(.offWhite)
                    .frame(width: 60)
                    .padding(.leading, 10)

                TextField("Which game?", text: $gameName)
                    .font(Font.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundColor(.offWhite)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($fieldFocused)
                    .onSubmit {
                        choose(name: gameName)
                    }

                Spacer()

                Rectangle().fill(Color.clear)
                    .border(width: 1, edge: .leading, color: .offWhite)
                    .contentShape(Rectangle())
                    .overlay(
                        Text("✓")
                            .foregroundColor(Color.offWhite)
                            .font(Font.system(size: 30, design: .rounded))
                    )
                    .frame(width: 80, height: frameHeight)
                    .onTapGesture {
                        choose(name: gameName)
                    }
            }
        }
        .frame(width: 350, height: frameHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.offWhite, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
    }

    // An empty name plays with the universal score entry
    func choose(name: String) {
        fieldFocused = false
        withAnimation {
            game.choose(rules: GameLibrary.rules(named: name))
        }
    }
}

struct GameChoice {
    var name : String
    // Recent games can be dragged to the trash, library games cannot
    var isRecent : Bool
}

struct GameChoiceView: View {
    
    static let coordinateSpace = "gameEntry"
    
    var choice : GameChoice
    // Size of the whole entry screen : the trash sits at its bottom center
    var containerSize : CGSize
    @Binding var isDragging : Bool
    var onTap : () -> Void
    var onTrash : () -> Void
    
    @GestureState private var dragOffset = CGSize.zero
    @State private var isAboveTrash = false
    @State private var trashFeedbackPlayed = false
    
    var body: some View {
        ZStack {
            if isAboveTrash {
                LinearGradient(Color(hex: 0xCB356B),Color(hex: 0xBD3F32))
            } else if choice.isRecent {
                LinearGradient(Color(hex: 0x136a8a),Color(hex: 0x267871))
            } else {
                LinearGradient(Color(hex: 0xf12711),Color(hex: 0xf5af19))
            }
            
            Text(choice.name)
                .font(Font.system(size: 40, weight: .light, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
                .foregroundColor(Color.white)
                .padding()
        }
        .frame(height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isAboveTrash ? Color.offRed : Color.offWhite, lineWidth: isAboveTrash ? 2 : 1)
        )
        .offset(dragOffset)
        .gesture(choice.isRecent ? trashGesture : nil)
        .onTapGesture(perform: onTap)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
        .transition(.asymmetric(insertion: .opacity, removal: .scale))
    }
    
    var trashGesture: some Gesture {
        DragGesture(coordinateSpace: .named(GameChoiceView.coordinateSpace))
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onChanged { value in
                let aboveTrash = abs(value.location.x - containerSize.width / 2) < 50
                    && value.location.y > containerSize.height - 80
                if aboveTrash && !trashFeedbackPlayed {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    trashFeedbackPlayed = true
                } else if !aboveTrash {
                    trashFeedbackPlayed = false
                }
                isAboveTrash = aboveTrash
                withAnimation { isDragging = true }
            }
            .onEnded { _ in
                if isAboveTrash {
                    onTrash()
                }
                trashFeedbackPlayed = false
                withAnimation {
                    isAboveTrash = false
                    isDragging = false
                }
            }
    }
}

struct GameEntryView_Previews: PreviewProvider {
    static var previews: some View {
        GameEntryView()
            .environmentObject(Game(withTestPlayers: ()))
    }
}
