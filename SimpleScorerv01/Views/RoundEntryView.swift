//
//  RoundEntryView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Entry of a whole round (deal, mène) for the games scoring all the players at once
struct RoundEntryView: View {

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo

    // Player whose card was tapped : winner, taker or scoring team to start with
    var playerID : UUID

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.midnightBlue : Color.offWhite).edgesIgnoringSafeArea(.all)

            switch game.activeKind {
            case .tarot:
                TarotRoundView(takerID: displayInfo.roundEntryPreselects ? playerID : nil, onConfirm: confirm)
            case .coinche:
                CoincheRoundView(playerID: playerID, onConfirm: confirm)
            case .uno:
                UnoRoundView(winnerID: playerID, onConfirm: confirm)
            case .petanque:
                PetanqueRoundView(scorerID: playerID, onConfirm: confirm)
            case .gangOfFour:
                GangOfFourRoundView(winnerID: playerID, onConfirm: confirm)
            case .cabo:
                CaboRoundView(callerID: playerID, onConfirm: confirm)
            case .darts:
                // From the New round button : the next player in turn
                CricketRoundView(throwerID: displayInfo.roundEntryPreselects ? playerID : game.cricketNextThrower ?? playerID) { points, marks in
                    withAnimation {
                        game.addRound(points: points, marks: marks)
                    }
                    // The board stays for the next player, until someone wins
                    if game.winner() != nil {
                        displayInfo.roundEntryPlayerID = nil
                    }
                }
            default:
                EmptyView()
            }
        }
    }

    func confirm(points : [UUID : Int]) {
        withAnimation {
            game.addRound(points: points)
        }
        displayInfo.roundEntryPlayerID = nil
    }
}

// MARK: - Uno

struct UnoRoundView: View {

    @EnvironmentObject var game : Game

    @State var winnerID : UUID
    var onConfirm : ([UUID : Int]) -> Void

    // Card points left in each loser's hand
    @State private var handPoints : [UUID : CGFloat] = [:]
    @State private var editedID : UUID?
    @State private var sign = CGFloat(1)

    var losers : [PlayerScore] {
        game.playerScores.filter { $0.player.id != winnerID }
    }

    var winnerPoints : Int {
        Int(losers.reduce(CGFloat(0)) { $0 + (handPoints[$1.player.id] ?? 0) })
    }
    
    // Official : the winner scores all the hands. House rule : everyone keeps the points of his hand
    var points : [UUID : Int] {
        guard game.options.unoLowestWins else {
            return [winnerID : winnerPoints]
        }
        var points = [UUID : Int]()
        for playerScore in losers {
            points[playerScore.player.id] = Int(handPoints[playerScore.player.id] ?? 0)
        }
        return points
    }

    var body: some View {
        RoundEntryLayout(title: "Uno") {
            RoundSection(title: L("Out of cards")) {
                PlayerPickRow(players: game.playerScores, selected: $winnerID)
            }

            RoundSection(title: L("Cards left")) {
                VStack(spacing: 8) {
                    ForEach(losers) { playerScore in
                        PointsRow(playerScore: playerScore,
                                  value: Int(handPoints[playerScore.player.id] ?? 0),
                                  isEdited: editedID == playerScore.player.id)
                        .onTapGesture {
                            editedID = playerScore.player.id
                        }
                    }
                }

                if let editedID = editedID {
                    HStack(spacing: 8) {
                        ChoiceChip(label: "+\(Uno.actionCard)", isSelected: false) {
                            handPoints[editedID, default: 0] += CGFloat(Uno.actionCard)
                        }
                        ChoiceChip(label: "+\(Uno.wildCard)", isSelected: false) {
                            handPoints[editedID, default: 0] += CGFloat(Uno.wildCard)
                        }
                    }
                    KeyPadView(valueDisplayed: Binding(
                        get: { handPoints[editedID] ?? 0 },
                        set: { handPoints[editedID] = $0 }), sign: $sign)
                    .frame(height: 180)
                    .cornerRadius(14)
                }
            }
        } preview: {
            RoundPreview(points: points)
        } confirm: {
            ConfirmBar(isEnabled: game.options.unoLowestWins || winnerPoints > 0) {
                onConfirm(points)
            }
        }
        .onAppear {
            editedID = losers.first?.player.id
        }
        .onChange(of: winnerID) {
            handPoints[winnerID] = nil
            if editedID == winnerID {
                editedID = losers.first?.player.id
            }
        }
    }
}

// MARK: - Pétanque

struct PetanqueRoundView: View {

    @EnvironmentObject var game : Game

    @State var scorerID : UUID
    var onConfirm : ([UUID : Int]) -> Void

    @State private var points = 1

    var body: some View {
        RoundEntryLayout(title: "Pétanque") {
            RoundSection(title: L("Wins the mène")) {
                PlayerPickRow(players: game.playerScores, selected: $scorerID)
            }

            RoundSection(title: L("Points")) {
                ChoiceChips(items: Array(1...Petanque.maxPointsPerMene), selection: $points) { "\($0)" }
            }
        } preview: {
            RoundPreview(points: [scorerID : points])
        } confirm: {
            ConfirmBar(isEnabled: true) {
                onConfirm([scorerID : points])
            }
        }
    }
}

// MARK: - Cricket

// The board : a tap on a number adds a mark to the player throwing. Each turn is saved once done, a line of the scores
struct CricketRoundView: View {

    @EnvironmentObject var game : Game

    @State var throwerID : UUID
    var onConfirm : ([UUID : Int], [UUID : [Int]]) -> Void

    // Marks of this turn on each number
    @State private var hits = Array(repeating: 0, count: Darts.cricketNumbers.count)
    // Numbers tapped, the last one goes first when undone
    @State private var taps : [Int] = []

    var players : [PlayerScore] { game.playerScores }

    var throwerIndex : Int {
        players.firstIndex { $0.player.id == throwerID } ?? 0
    }

    var savedMarks : [[Int]] {
        players.map { game.cricketMarks(for: $0) }
    }

    // The marks of everyone once this turn is added
    var boardMarks : [[Int]] {
        var marks = savedMarks
        marks[throwerIndex] = zip(marks[throwerIndex], hits).map { $0 + $1 }
        return marks
    }

    // For the player, or for the opponents still open when cut-throat
    var points : [UUID : Int] {
        var points = [UUID : Int]()
        for (scorer, value) in Darts.cricketPoints(hits: hits, player: throwerIndex, marks: savedMarks, cutThroat: game.options.cricketCutThroat) {
            points[players[scorer].player.id] = value
        }
        return points
    }

    func addHit(on index : Int) {
        let isBull = Darts.cricketNumbers[index] == 25
        guard hits.reduce(0, +) < Darts.maxMarksPerTurn,
              !isBull || hits[index] < Darts.maxBullMarksPerTurn else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        hits[index] += 1
        taps.append(index)
    }

    func undoHit() {
        guard let index = taps.popLast() else { return }
        hits[index] -= 1
    }

    // Another player picked : his turn starts from nothing
    func clearTurn() {
        hits = Array(repeating: 0, count: Darts.cricketNumbers.count)
        taps = []
    }

    var body: some View {
        RoundEntryLayout(title: "Cricket") {
            RoundSection(title: L("Throwing")) {
                PlayerPickRow(players: players, selected: $throwerID)
            }

            VStack(spacing: 6) {
                // Who each column is, with his score once the turn is added
                HStack(spacing: 6) {
                    Color.clear.frame(width: 56, height: 1)
                    ForEach(players) { playerScore in
                        VStack(spacing: 0) {
                            Text(playerScore.player.initials)
                                .font(Font.system(size: 15, weight: .semibold, design: .rounded))
                            Text("\(game.total(for: playerScore) + (points[playerScore.player.id] ?? 0))")
                                .font(Font.system(size: 13, weight: .light, design: .rounded))
                        }
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                    }
                }
                ForEach(Array(Darts.cricketNumbers.enumerated()), id: \.offset) { index, number in
                    let closedByAll = boardMarks.allSatisfy { $0[index] >= Darts.marksToClose }
                    HStack(spacing: 6) {
                        Text(Darts.cricketLabel(number))
                            .font(Font.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                            .frame(width: 56, alignment: .leading)
                        ForEach(Array(players.enumerated()), id: \.element.id) { playerIndex, playerScore in
                            CricketMarkCell(marks: boardMarks[playerIndex][index],
                                            turnMarks: playerIndex == throwerIndex ? hits[index] : 0,
                                            playerScore: playerScore,
                                            isThrowing: playerIndex == throwerIndex)
                        }
                    }
                    .opacity(closedByAll ? 0.35 : 1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        addHit(on: index)
                    }
                }
            }

            ChoiceChip(label: "↺ " + L("Undo"), isSelected: false, fullWidth: true) {
                undoHit()
            }
            .opacity(taps.isEmpty ? 0.4 : 1)
        } preview: {
            RoundPreview(points: points,
                         caption: L("Next : %@", players[(throwerIndex + 1) % players.count].player.name))
        } confirm: {
            ConfirmBar(isEnabled: true) {
                onConfirm(points, [throwerID : hits])
                clearTurn()
                throwerID = game.cricketNextThrower ?? throwerID
            }
        }
        .onChange(of: throwerID) {
            clearTurn()
        }
    }
}

// The marks of a player on a number : /, ✕, then ⓧ once closed. Those of this round are brighter
struct CricketMarkCell: View {
    var marks : Int
    var turnMarks : Int
    var playerScore : PlayerScore
    var isThrowing : Bool

    var symbol : String? {
        switch min(marks, Darts.marksToClose) {
        case 1: return "line.diagonal"
        case 2: return "xmark"
        case 3: return "xmark.circle"
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isThrowing ? AnyShapeStyle(playerScore.player.colorGradient) : AnyShapeStyle(Color.gray.opacity(0.12)))
            if let symbol = symbol {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: turnMarks > 0 ? .heavy : .regular))
                    .foregroundColor(isThrowing ? .offWhite : .gray)
            }
            // Marks over 3 : the points scored
            if marks > Darts.marksToClose {
                Text("+\(marks - Darts.marksToClose)")
                    .font(Font.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isThrowing ? .offWhite : .gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}

// MARK: - Shared components

struct RoundEntryLayout<Content: View, Preview: View, Confirm: View>: View {
    
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    
    var title : String
    @ViewBuilder var content : Content
    @ViewBuilder var preview : Preview
    @ViewBuilder var confirm : Confirm
    
    // Keypad asked by a PointsKeypadEntry, shown at the bottom like the keyboard of iOS
    @State private var keypad : KeypadRequest?
    @State private var typedPoints = CGFloat(0)
    @State private var sign = CGFloat(1)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.gray)
                        .padding()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            displayInfo.roundEntryPlayerID = nil
                        }
                }
                .padding([.horizontal, .top])
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        content
                    }
                    .padding()
                }
                
                VStack(spacing: 12) {
                    preview
                    confirm
                }
                .padding()
            }
            .environment(\.presentKeypad) { request in
                typedPoints = 0
                withAnimation(KeypadPanel.spring) {
                    keypad = request
                }
            }
            
            if let keypad = keypad {
                KeypadPanel(request: keypad, typedPoints: $typedPoints, sign: $sign) {
                    withAnimation(KeypadPanel.spring) {
                        self.keypad = nil
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
    }
}

// What a PointsKeypadEntry needs from the keypad
struct KeypadRequest {
    var maximum : Int
    // Replaces the ＋∕− key, e.g. the capot of Coinche, empty for none
    var extraKey : String
    var onExtraKey : () -> Void
    var onValue : (Int) -> Void
}

private struct PresentKeypadKey: EnvironmentKey {
    static let defaultValue : (KeypadRequest) -> Void = { _ in }
}

extension EnvironmentValues {
    var presentKeypad : (KeypadRequest) -> Void {
        get { self[PresentKeypadKey.self] }
        set { self[PresentKeypadKey.self] = newValue }
    }
}

// The keypad of the cards, over the bottom of the screen, framed by the gradient of the app
struct KeypadPanel: View {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.85)
    
    var request : KeypadRequest
    @Binding var typedPoints : CGFloat
    @Binding var sign : CGFloat
    var onDone : () -> Void
    
    var body: some View {
        BottomPanel(onDone: onDone) {
            KeyPadView(valueDisplayed: Binding(
                get: { typedPoints },
                set: { value in
                    typedPoints = min(value, CGFloat(request.maximum))
                    request.onValue(Int(typedPoints))
                }),
                       sign: $sign,
                       extraKey: request.extraKey,
                       onExtraKey: {
                // No extra key for this game : the key stays blank and inactive
                guard !request.extraKey.isEmpty else { return }
                typedPoints = 0
                request.onExtraKey()
            })
            .font(.system(size: 24, design: .rounded))
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding([.horizontal, .bottom], 8)
        }
    }
}

// Panel over the bottom of the screen, like the keyboard of iOS, framed by the gradient of the app
struct BottomPanel<Content: View>: View {
    var onDone : () -> Void
    @ViewBuilder var content : Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(L("Done"))
                    .font(Font.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onDone)
            }
            content
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(Color.offWhite)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .stroke(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange, Color.purple]), startPoint: .leading, endPoint: .trailing).opacity(0.5), lineWidth: 2)
                .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
    }
}

struct RoundSection<Content: View>: View {
    var title : String
    // Title and content on one line, to save height
    var inline = false
    @ViewBuilder var content : Content
    
    var titleText: some View {
        Text(title.uppercased())
            .font(Font.system(size: 15, weight: .light, design: .rounded))
            .foregroundColor(.gray)
    }
    
    var body: some View {
        if inline {
            HStack(spacing: 12) {
                titleText
                content
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                titleText
                content
            }
        }
    }
}

// Avatars of the players, the selected one stands out
struct PlayerPickRow: View {
    var players : [PlayerScore]
    @Binding var selected : UUID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(players) { playerScore in
                    let isSelected = playerScore.player.id == selected
                    VStack(spacing: 4) {
                        AvatarView(user: playerScore.player)
                            .background(Circle().fill(playerScore.player.colorGradient))
                            .frame(width: 56, height: 56)
                        Text(playerScore.player.name)
                            .font(Font.system(size: 13, weight: isSelected ? .semibold : .light, design: .rounded))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .frame(maxWidth: 70)
                    }
                    .scaleEffect(isSelected ? 1.1 : 0.9)
                    .opacity(isSelected ? 1 : 0.45)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selected = playerScore.player.id
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
    }
}

// Avatars of the players, several can be picked
struct PlayerMultiPickRow: View {
    var players : [PlayerScore]
    @Binding var selected : Set<UUID>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(players) { playerScore in
                    let isSelected = selected.contains(playerScore.player.id)
                    VStack(spacing: 4) {
                        AvatarView(user: playerScore.player)
                            .background(Circle().fill(playerScore.player.colorGradient))
                            .frame(width: 48, height: 48)
                        Text(playerScore.player.name)
                            .font(Font.system(size: 13, weight: isSelected ? .semibold : .light, design: .rounded))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .frame(maxWidth: 64)
                    }
                    .scaleEffect(isSelected ? 1.1 : 0.9)
                    .opacity(isSelected ? 1 : 0.45)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            if isSelected {
                                selected.remove(playerScore.player.id)
                            } else {
                                selected.insert(playerScore.player.id)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
    }
}

struct ChoiceChip: View {
    var label : String
    var isSelected : Bool
    var fullWidth = false
    var action : () -> Void

    var body: some View {
        Text(label)
            .font(Font.system(size: 18, weight: isSelected ? .semibold : .regular, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(isSelected ? .offWhite : .gray)
            .padding(.horizontal, 12)
            .frame(minWidth: 44, maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? LinearGradient(Color(hex: 0xf12711), Color(hex: 0xf5af19))
                          : LinearGradient(Color.clear, Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.offWhite : Color.gray.opacity(0.5), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
}

struct ChoiceChips<Item: Hashable>: View {
    var items : [Item]
    @Binding var selection : Item
    // Wider for long labels
    var minimumWidth = CGFloat(64)
    // Fixed number of chips per line, all the same width
    var columns : Int? = nil
    var label : (Item) -> String
    
    var gridItems: [GridItem] {
        if let columns = columns {
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
        }
        return [GridItem(.adaptive(minimum: minimumWidth), spacing: 8)]
    }
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 8) {
            ForEach(items, id: \.self) { item in
                ChoiceChip(label: label(item), isSelected: item == selection, fullWidth: columns != nil) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selection = item
                    }
                }
            }
        }
    }
}

// One choice per line, for long labels
struct ChoiceList<Item: Hashable>: View {
    var items : [Item]
    @Binding var selection : Item
    var label : (Item) -> String
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                ChoiceChip(label: label(item), isSelected: item == selection, fullWidth: true) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selection = item
                    }
                }
            }
        }
    }
}

// Card points behind an "Add score" button : the keypad comes up at the bottom of the screen
struct PointsKeypadEntry: View {
    @Environment(\.presentKeypad) var presentKeypad
    
    var text : String
    var caption : String?
    var maximum : Int
    // Replaces the ＋∕− key, e.g. the capot of Coinche
    var extraKey : String = ""
    var onExtraKey : () -> Void = {}
    var onValue : (Int) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            if !text.isEmpty {
                Text(text)
                    .font(Font.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
            }
            if let caption = caption {
                Text(caption)
                    .font(Font.system(size: 15, weight: .light, design: .rounded))
                    .foregroundColor(.gray)
            }
            ChoiceChip(label: L("Add score"), isSelected: true) {
                presentKeypad(KeypadRequest(maximum: maximum, extraKey: extraKey, onExtraKey: onExtraKey, onValue: onValue))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// One player with a value, used for the hands of Uno losers
struct PointsRow: View {
    var playerScore : PlayerScore
    var value : Int
    var isEdited : Bool

    var body: some View {
        HStack {
            AvatarView(user: playerScore.player)
                .frame(width: 40, height: 40)
            Text(playerScore.player.name)
                .font(Font.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.offWhite)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
            Text("\(value)")
                .font(Font.system(size: 25, weight: .bold, design: .rounded))
                .foregroundColor(.offWhite)
        }
        .padding(.horizontal, 10)
        .frame(height: 56)
        .background(playerScore.player.colorGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.offWhite, lineWidth: isEdited ? 3 : 1)
        )
        .opacity(isEdited ? 1 : 0.7)
    }
}

// What each player will get once the round is confirmed
struct RoundPreview: View {
    @EnvironmentObject var game : Game
    var points : [UUID : Int]
    var caption : String?

    var body: some View {
        VStack(spacing: 6) {
            if let caption = caption {
                Text(caption.uppercased())
                    .font(Font.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
            }
            HStack(spacing: 6) {
                ForEach(game.playerScores) { playerScore in
                    let value = points[playerScore.player.id] ?? 0
                    VStack(spacing: 2) {
                        Text(playerScore.player.initials)
                            .font(Font.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.offWhite)
                            .lineLimit(1)
                        Text(value > 0 ? "+\(value)" : "\(value)")
                            .font(Font.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.offWhite)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(playerScore.player.colorGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(value == 0 ? 0.5 : 1)
                }
            }
        }
    }
}

struct ConfirmBar: View {
    var isEnabled : Bool
    var action : () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange, Color.purple]), startPoint: UnitPoint(x: 0.2, y: 0.2), endPoint: UnitPoint(x: 0.8, y: 0.8)))
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.offWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.offWhite, lineWidth: 1)
            )
            .frame(height: 64)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Rectangle())
            .onTapGesture {
                if isEnabled {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    action()
                }
            }
    }
}
