//
//  HandRoundViews.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// MARK: - Gang of Four

struct GangOfFourRoundView: View {

    @EnvironmentObject var game : Game

    @State var winnerID : UUID
    var onConfirm : ([UUID : Int]) -> Void

    // Cards left in the hand of each player still holding some
    @State private var cardsLeft = [UUID : Int]()

    var losers : [PlayerScore] {
        game.playerScores.filter { $0.player.id != winnerID }
    }

    var points : [UUID : Int] {
        var points = [UUID : Int]()
        for playerScore in losers {
            points[playerScore.player.id] = GangOfFour.penalty(cardsLeft: cardsLeft[playerScore.player.id] ?? 0)
        }
        return points
    }

    // Nobody else ends with an empty hand
    var isComplete : Bool {
        losers.allSatisfy { (cardsLeft[$0.player.id] ?? 0) > 0 }
    }

    var body: some View {
        RoundEntryLayout(title: "Gang of 4") {
            RoundSection(title: L("Out of cards")) {
                PlayerPickRow(players: game.playerScores, selected: $winnerID)
            }

            RoundSection(title: L("Cards left")) {
                VStack(spacing: 8) {
                    ForEach(losers) { playerScore in
                        HandRow(playerScore: playerScore,
                                value: cardsLeft[playerScore.player.id],
                                unit: L("cards"),
                                request: KeypadRequest(maximum: GangOfFour.cards, extraKey: "", onExtraKey: {}) { cards in
                                    cardsLeft[playerScore.player.id] = cards
                                })
                    }
                }
            }
        } preview: {
            RoundPreview(points: points)
        } confirm: {
            ConfirmBar(isEnabled: isComplete) {
                onConfirm(points)
            }
        }
        .onChange(of: winnerID) {
            cardsLeft[winnerID] = nil
        }
    }
}

// MARK: - Cabo

struct CaboRoundView: View {

    @EnvironmentObject var game : Game

    @State var callerID : UUID
    var onConfirm : ([UUID : Int]) -> Void

    // Total of the cards in each hand
    @State private var hands = [UUID : Int]()
    @State private var kamikazeID : UUID?

    var points : [UUID : Int] {
        let players = game.playerScores
        let roundPoints = Cabo.roundPoints(
            hands: players.map { hands[$0.player.id] ?? 0 },
            caller: players.firstIndex { $0.player.id == callerID } ?? 0,
            kamikaze: players.firstIndex { $0.player.id == kamikazeID })

        var points = [UUID : Int]()
        for (index, playerScore) in players.enumerated() {
            points[playerScore.player.id] = roundPoints[index]
        }
        return points
    }

    // A kamikaze decides alone, otherwise every hand is needed
    var isComplete : Bool {
        kamikazeID != nil || game.playerScores.allSatisfy { hands[$0.player.id] != nil }
    }

    var callerCaption : String? {
        guard kamikazeID == nil, isComplete else { return nil }
        return (points[callerID] ?? 0) == 0 ? L("Cabo made") : L("Cabo failed · + %ld", Cabo.failedCallPenalty)
    }

    var body: some View {
        RoundEntryLayout(title: "Cabo") {
            RoundSection(title: L("Called Cabo")) {
                PlayerPickRow(players: game.playerScores, selected: $callerID)
            }

            RoundSection(title: L("Hands")) {
                VStack(spacing: 8) {
                    ForEach(game.playerScores) { playerScore in
                        HandRow(playerScore: playerScore,
                                value: hands[playerScore.player.id],
                                unit: L("points"),
                                request: KeypadRequest(maximum: 99, extraKey: "", onExtraKey: {}) { total in
                                    hands[playerScore.player.id] = total
                                })
                    }
                }
            }

            RoundSection(title: L("Kamikaze · %@", game.options.caboKamikazeHand)) {
                ChoiceChips(items: [nil] + game.playerScores.map { Optional($0.player.id) },
                            selection: $kamikazeID, minimumWidth: 80) { id in
                    game.playerScores.first { $0.player.id == id }?.player.name ?? "—"
                }
            }
        } preview: {
            RoundPreview(points: isComplete ? points : [:], caption: callerCaption)
        } confirm: {
            ConfirmBar(isEnabled: isComplete) {
                onConfirm(points)
            }
        }
    }
}

// A player and what is left in the hand, tapped to type it on the keypad.
// Reads the keypad itself : it only exists inside the RoundEntryLayout
struct HandRow: View {
    @Environment(\.presentKeypad) var presentKeypad
    
    var playerScore : PlayerScore
    var value : Int?
    var unit : String
    var request : KeypadRequest

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
            if let value = value {
                Text("\(value)")
                    .font(Font.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundColor(.offWhite)
                Text(unit)
                    .font(Font.system(size: 13, weight: .light, design: .rounded))
                    .foregroundColor(.offWhite)
            } else {
                Image(systemName: "keyboard")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.offWhite)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 56)
        .background(playerScore.player.colorGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.offWhite, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            presentKeypad(request)
        }
    }
}
