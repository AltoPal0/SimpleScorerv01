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

// Width of a column in the player editor
var columnWidth: CGFloat = 60

// Sizes of the columns : bigger when there is room, always much taller than wide
struct ColumnMetrics {
    
    static let spacing = CGFloat(8)
    static let minimumWidth = CGFloat(52)
    static let maximumWidth = CGFloat(120)
    // A column is at least this many times taller than wide
    static let minimumRatio = CGFloat(3)
    
    var width = minimumWidth
    var headerHeight = minimumWidth + 10
    var totalHeight = minimumWidth * 0.9
    var rowHeight = minimumWidth / 2
    var pointsHeight = CGFloat(0)
    
    var columnHeight: CGFloat {
        headerHeight + pointsHeight + totalHeight
    }
    
    static func compute(width: CGFloat, height: CGFloat, players: Int, rounds: Int) -> ColumnMetrics {
        guard players > 0, width > 0, height > 0 else { return ColumnMetrics() }
        
        let fitting = (width - spacing * CGFloat(players - 1)) / CGFloat(players)
        let largest = min(maximumWidth, height / minimumRatio)
        let columnWidth = max(minimumWidth, min(fitting, largest))
        
        var metrics = ColumnMetrics(
            width: columnWidth,
            headerHeight: columnWidth + 10,
            totalHeight: columnWidth * 0.9,
            rowHeight: columnWidth / 2)
        
        // The rounds, never shorter than a column should be, never taller than the screen : then it scrolls
        let frame = metrics.headerHeight + metrics.totalHeight
        let shortest = max(0, columnWidth * minimumRatio - frame)
        let tallest = max(metrics.rowHeight, height - frame)
        metrics.pointsHeight = min(max(CGFloat(rounds) * metrics.rowHeight, shortest), tallest)
        return metrics
    }
}

struct AllScoresView_new: View {
    
    @EnvironmentObject var game : Game
    
    @State private var showKeypad = false
    @State var scoreEdit = (playerIdx: 0, round: 0, mode: ScoreEditMode.addition)
    @State private var molkkyAlert : Game.MolkkyWarning?
    
    // Room for the arrows at the bottom
    static let bottomRoom = CGFloat(70)
    static let margin = CGFloat(16)
    // Wide enough for the shadow of the columns : a cut shadow draws the edge of a box
    static let sideMargin = CGFloat(24)
    static let bottomMargin = CGFloat(32)
    
    // Cells and totals ask for the keypad through this : Mölkky warnings come first
    var keypadRequest: Binding<Bool> {
        Binding(
            get: { showKeypad },
            set: { show in
                guard show else {
                    showKeypad = false
                    return
                }
                if scoreEdit.mode == .addition, game.playerScores.indices.contains(scoreEdit.playerIdx),
                   let warning = game.molkkyWarning(for: game.playerScores[scoreEdit.playerIdx]) {
                    molkkyAlert = warning
                } else {
                    showKeypad = true
                }
            })
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let metrics = ColumnMetrics.compute(
                    width: geometry.size.width - 2 * AllScoresView_new.sideMargin,
                    height: geometry.size.height - AllScoresView_new.margin - AllScoresView_new.bottomRoom,
                    players: game.playerScores.count,
                    rounds: game.maxNbrOfRounds)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Initials
                        HStack(spacing: ColumnMetrics.spacing) {
                            ForEach(0..<game.playerScores.count, id: \.self) { idx in
                                AvatarView(user: game.playerScores[idx].player)
                                    .padding(7)
                                    .frame(width: metrics.width, height: metrics.headerHeight)
                            }
                        }
                        
                        // Points, scrolling together when they don't fit
                        ScrollView(.vertical, showsIndicators: false) {
                            HStack(alignment: .top, spacing: ColumnMetrics.spacing) {
                                ForEach(0..<game.playerScores.count, id: \.self) { playerIndex in
                                    PointsRows(playerIndex: playerIndex, metrics: metrics, showKeypad: keypadRequest, scoreEdit: $scoreEdit)
                                }
                            }
                        }
                        .frame(height: metrics.pointsHeight)
                        
                        // Totals
                        HStack(spacing: ColumnMetrics.spacing) {
                            ForEach(0..<game.playerScores.count, id: \.self) { idx in
                                TotalRows(playerIndex: idx, metrics: metrics, showKeyPad: keypadRequest, scoreEdit: $scoreEdit)
                            }
                        }
                    }
                    // Drawn behind the content at its exact size : nothing gets cut
                    .background(alignment: .top) {
                        HStack(spacing: ColumnMetrics.spacing) {
                            ForEach(0..<game.playerScores.count, id: \.self) { idx in
                                ColumnBack(player: game.playerScores[idx].player, metrics: metrics)
                            }
                        }
                    }
                    .padding(.horizontal, AllScoresView_new.sideMargin)
                    .padding(.top, AllScoresView_new.margin)
                    .padding(.bottom, AllScoresView_new.bottomMargin)
                    .frame(minWidth: geometry.size.width)
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
        .alert(molkkyAlertTitle, isPresented: Binding(
            get: { molkkyAlert != nil },
            set: { if !$0 { molkkyAlert = nil } })) {
                if molkkyAlert == .eliminated {
                    Button("Keep playing") {
                        game.keepEliminatedPlaying()
                        showKeypad = true
                    }
                    Button("Cancel", role: .cancel) {}
                } else {
                    Button("OK") {
                        showKeypad = true
                    }
                }
            } message: {
                Text(molkkyAlertMessage)
            }
    }
    
    var editedPlayer: PlayerScore? {
        game.playerScores[optional: scoreEdit.playerIdx]
    }
    
    var molkkyAlertTitle: String {
        guard let warning = molkkyAlert, let player = editedPlayer else { return "" }
        return game.molkkyWarningTitle(warning, for: player)
    }
    
    var molkkyAlertMessage: String {
        guard let warning = molkkyAlert, let player = editedPlayer else { return "" }
        return game.molkkyWarningMessage(warning, for: player)
    }
}

struct ColumnBack: View {
    var player : Player
    var metrics : ColumnMetrics
    
    var body: some View {
        player.colorGradient
            .frame(width: metrics.width, height: metrics.columnHeight)
            .overlay(alignment: .top) {
                // Lines under the initials and above the total
                VStack(spacing: 0) {
                    Color.clear.frame(height: metrics.headerHeight)
                    Rectangle().fill(Color.white).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Color.white).frame(height: 1)
                    Color.clear.frame(height: metrics.totalHeight)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.offWhite, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 8)
    }
}

struct TotalRows: View {
    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    
    var playerIndex : Int
    var metrics : ColumnMetrics
    @Binding var showKeyPad : Bool
    @Binding var scoreEdit : (playerIdx: Int, round: Int, mode: ScoreEditMode)
    
    var totalText: String {
        let playerScore = game.playerScores[playerIndex]
        if game.isEliminated(playerScore) {
            return "✕"
        }
        let total = game.total(for: playerScore)
        return abs(total) < 10000 ? String(total) : String(total / 1000) + "K"
    }
    
    var body: some View {
        Text(totalText)
            .font(Font.system(size: metrics.width * 0.42, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .padding(.horizontal, 4)
            .foregroundColor(.white)
            .frame(width: metrics.width, height: metrics.totalHeight)
            .contentShape(Rectangle())
            .onTapGesture(count: 1, perform: {
                if game.entersRounds {
                    displayInfo.roundEntryPlayerID = game.playerScores[playerIndex].player.id
                } else {
                    scoreEdit.playerIdx = playerIndex
                    scoreEdit.mode = .addition
                    self.showKeyPad = true
                }
            })
    }
}

struct PointsRows: View {
    @EnvironmentObject var game : Game
    
    var playerIndex: Int
    var metrics : ColumnMetrics
    
    @Binding var showKeypad : Bool
    @Binding var scoreEdit : (playerIdx: Int, round: Int, mode: ScoreEditMode)
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<game.maxNbrOfRounds, id: \.self) { round in
                Rectangle()
                    .fill(Color.white)
                    .opacity(0.1 + 0.2 * CGFloat(round % 2))
                    .frame(width: metrics.width, height: metrics.rowHeight)
                    .overlay(
                        Cell(playerIndex: playerIndex, round: round, showKeypad: $showKeypad, scoreEdit: $scoreEdit, width: metrics.width)
                            .font(.system(size: metrics.rowHeight * 0.5, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(Color.white)
                    )
            }
        }
    }
}

struct Cell: View {
    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    var playerIndex : Int
    var round : Int
    
    @State private var showingActionSheet = false
    @State private var isHighlighted = false
    
    @Binding var showKeypad : Bool
    @Binding var scoreEdit : (playerIdx: Int, round: Int, mode: ScoreEditMode)
    
    var width : CGFloat?
    
    var roundExists : Bool {
        if game.playerScores[optional: playerIndex]?.pointsList[optional: round] != nil  {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        
        Text(roundExists ? game.playerScores[playerIndex].pointsList[round].score.description : "•")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(count: 1, perform: {
                if roundExists {
                    withAnimation{
                        self.showingActionSheet = true
                    }
                } else if game.entersRounds {
                    // A missing score of a round game : the whole round is entered
                    displayInfo.roundEntryPlayerID = game.playerScores[playerIndex].player.id
                } else {
                    scoreEdit.playerIdx = playerIndex
                    scoreEdit.mode = .addition
                    scoreEdit.round = round
                    self.showKeypad = true
                }
            })
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(title: Text("Edit score").font(.system(.headline, design: .rounded)), buttons: [
                    .default(Text("Modify")) {
                        scoreEdit.playerIdx = playerIndex
                        if roundExists {
                            scoreEdit.mode = .modification
                        } else {
                            scoreEdit.mode = .addition
                        }
                        scoreEdit.round = round
                        self.showKeypad = true
                    },
                    .destructive(Text("Delete")) {
                        withAnimation {
                            if roundExists {
                                game.deletePointsFor(player: game.playerScores[playerIndex].player, round: round)
                            }
                        }
                    },
                    .cancel()
                ])
            }
            
    }
}


struct AllScoresView_new_Previews: PreviewProvider {
    static var previews: some View {
        AllScoresView_new()
            .environmentObject(Game(withTestPlayers: ()))
            .environmentObject(GlobalDisplayInfo())
    }
}

extension Collection {
    
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
    
}

