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
    @EnvironmentObject var displayInfo : GlobalDisplayInfo

    @State private var gameName = ""
    @State private var recentGames = RecentGames.load()
    @State private var hiddenGames = RecentGames.hiddenIDs()
    @State private var isDragging = false
    // Darts chosen : its variants are picked on their own screen
    @State private var showsDartsVariants = false
    @FocusState private var fieldFocused : Bool

    let frameHeight = CGFloat(90)
    // 4 rows of 3 : everything fits without scrolling
    let maxChoices = 12

    var gridItemLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 10)]

    var backColor: Color {
        colorScheme == .dark ? .midnightBlue : .offWhite
    }

    // Library games matching what is typed, or the most played games when nothing is typed yet
    var choices : [GameChoice] {
        if gameName.isEmpty {
            // Most played games first, then the rest of the library : a tap is enough to start.
            // The variants of darts come with Darts, the games thrown to the trash are only found when typed
            let recentIDs = Set(recentGames.map { GameLibrary.rules(named: $0.name).id })
            let recents = recentGames.map { choice(name: $0.name, isRecent: true) }
            let library = GameLibrary.games
                .filter { !recentIDs.contains($0.id) && !hiddenGames.contains($0.id) && $0.darts == nil }
                .map { choice(name: $0.name, isRecent: false) }
            return Array((recents + library).prefix(maxChoices))
        }

        let recentMatches = recentGames
            .filter { GameLibrary.rules(named: $0.name).matches(gameName) }
            .map { choice(name: $0.name, isRecent: true) }
        let libraryMatches = GameLibrary.suggestions(for: gameName)
            .filter { game in !recentMatches.contains { GameRules.normalized($0.name) == GameRules.normalized(game.name) } }
            .map { choice(name: $0.name, isRecent: false) }

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

                if showsDartsVariants {
                    dartsVariants(height: geometry.size.height)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    // In the middle of the screen, as the names of the players
                    VStack {
                        gameCard
                            .padding(.vertical)

                        if !choices.isEmpty {
                            HStack {
                                ZStack {
                                    Divider().frame(height: 1).background(Color.gray).padding()
                                }
                                Text(L("OR")).foregroundColor(.gray)
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
                                            RecentGames.trash(name: choice.name)
                                            reload()
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding()
                        }
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
        .coordinateSpace(name: GameChoiceView.coordinateSpace)
        // The screen stays built beside the others : it gets ready when the players slide to it
        .onChange(of: displayInfo.screenDisplayed) { _, screen in
            if screen == .gameChoice {
                reload()
                // Keyboard first only when there is nothing to pick
                if choices.isEmpty {
                    fieldFocused = true
                }
            } else {
                fieldFocused = false
                showsDartsVariants = false
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

                TextField(L("Which game?"), text: $gameName)
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

    // The variants of darts, each with a few words under it so that no one picks the wrong one
    func dartsVariants(height: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .light))
                    Text(L("Darts"))
                        .font(Font.system(size: 30, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(.gray)
                .frame(width: 350)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        showsDartsVariants = false
                    }
                }

                ForEach(DartsVariant.allCases, id: \.self) { variant in
                    let rules = GameLibrary.variant(variant)
                    let isPlayable = rules.supports(playerCount: game.playerScores.count)
                    VStack(spacing: 6) {
                        ZStack {
                            // Same gradient as the games and the previous players
                            LinearGradient(Color(hex: 0x136a8a), Color(hex: 0x267871))
                            Text(rules.displayName)
                                .font(Font.system(size: 30, weight: .light, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                        .frame(width: 350, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.offWhite, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)

                        Text(isPlayable ? variant.summary : rules.playerCountHint)
                            .font(Font.system(size: 13, weight: .light, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 330)
                    }
                    .opacity(isPlayable ? 1 : 0.5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isPlayable {
                            start(rules)
                        }
                    }
                }
            }
            .padding()
            // In the middle of the screen when it fits, scrolling on the small ones
            .frame(maxWidth: .infinity, minHeight: height)
        }
    }

    func choice(name: String, isRecent: Bool) -> GameChoice {
        let rules = GameLibrary.rules(named: name)
        let isPlayable = !rules.isInLibrary || rules.supports(playerCount: game.playerScores.count)
        return GameChoice(name: name, title: rules.displayName, isRecent: isRecent, hint: isPlayable ? nil : rules.playerCountHint)
    }

    func reload() {
        recentGames = RecentGames.load()
        hiddenGames = RecentGames.hiddenIDs()
    }

    // An empty name plays with the universal score entry
    func choose(name: String) {
        let rules = GameLibrary.rules(named: name)
        if rules.isDartsFamily {
            fieldFocused = false
            withAnimation {
                showsDartsVariants = true
            }
            return
        }
        start(rules)
    }

    // The game is chosen : on to the scores
    func start(_ rules: GameRules) {
        fieldFocused = false
        game.choose(rules: rules)
        gameName = ""
        withAnimation {
            displayInfo.screenDisplayed = .scoreCards
        }
        if GameRequests.shouldOffer(rules) {
            displayInfo.gameToRequest = rules.name
        }
    }
}

struct GameChoice {
    // Key of the game in the library and the recent games
    var name : String
    // Shown, in the language of the app
    var title : String
    // Recent games leave the recent games when thrown to the trash, library games leave the choices
    var isRecent : Bool
    // Why a library game can't be played with this number of players
    var hint : String?
}

struct GameChoiceView: View {
    
    static let coordinateSpace = "gameEntry"
    
    var choice : GameChoice
    // Size of the whole entry screen : the trash sits at its bottom center
    var containerSize : CGSize
    @Binding var isDragging : Bool
    var onTap : () -> Void
    var onTrash : () -> Void
    
    @State private var dragOffset = CGSize.zero
    // A long press lifts the game, then it can be dragged to the trash
    @State private var isLifted = false
    @State private var isAboveTrash = false
    @State private var trashFeedbackPlayed = false
    
    var body: some View {
        ZStack {
            if isAboveTrash {
                LinearGradient(Color(hex: 0xCB356B),Color(hex: 0xBD3F32))
            } else {
                // Same gradient as the previous players
                LinearGradient(Color(hex: 0x136a8a),Color(hex: 0x267871))
            }
            
            VStack(spacing: 0) {
                Text(choice.title)
                    .font(Font.system(size: 40, weight: .light, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .foregroundColor(Color.white)
                if let hint = choice.hint {
                    Text(hint)
                        .font(Font.system(size: 12, weight: .light, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(Color.white)
                }
            }
            .padding(choice.hint == nil ? 16 : 8)
        }
        .frame(height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isAboveTrash ? Color.offRed : Color.offWhite, lineWidth: isAboveTrash ? 2 : 1)
        )
        .scaleEffect(isLifted ? 1.08 : 1)
        .offset(dragOffset)
        .opacity(choice.hint == nil ? 1 : 0.5)
        .zIndex(isLifted ? 1 : 0)
        .onTapGesture {
            if choice.hint == nil {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.3, maximumDistance: .infinity) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.easeOut(duration: 0.15)) {
                isLifted = true
                isDragging = true
            }
        } onPressingChanged: { pressing in
            // Lifted and released without moving : back in place
            if !pressing && isLifted && dragOffset == .zero {
                drop()
            }
        }
        .simultaneousGesture(trashGesture)
        .shadow(color: Color.black.opacity(isLifted ? 0.45 : 0.3), radius: isLifted ? 16 : 10, x: 0, y: 10)
        .transition(.asymmetric(insertion: .opacity, removal: .scale))
    }
    
    var trashGesture: some Gesture {
        DragGesture(coordinateSpace: .named(GameChoiceView.coordinateSpace))
            .onChanged { value in
                guard isLifted else { return }
                dragOffset = value.translation
                let aboveTrash = abs(value.location.x - containerSize.width / 2) < 50
                    && value.location.y > containerSize.height - 80
                if aboveTrash && !trashFeedbackPlayed {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    trashFeedbackPlayed = true
                } else if !aboveTrash {
                    trashFeedbackPlayed = false
                }
                isAboveTrash = aboveTrash
            }
            .onEnded { _ in
                guard isLifted else { return }
                if isAboveTrash {
                    onTrash()
                }
                drop()
            }
    }
    
    func drop() {
        trashFeedbackPlayed = false
        withAnimation {
            dragOffset = .zero
            isLifted = false
            isAboveTrash = false
            isDragging = false
        }
    }
}

struct GameEntryView_Previews: PreviewProvider {
    static var previews: some View {
        GameEntryView()
            .environmentObject(Game(withTestPlayers: ()))
            .environmentObject(GlobalDisplayInfo())
    }
}
