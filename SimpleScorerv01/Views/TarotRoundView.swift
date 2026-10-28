//
//  TarotRoundView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct TarotRoundView: View {

    @EnvironmentObject var game : Game

    @State var takerID : UUID
    var onConfirm : ([UUID : Int]) -> Void

    @State private var deal = TarotDeal()
    @State private var pointsEntered = false
    // 5 players : the called king, the taker himself when he plays alone
    @State private var partnerID : UUID

    init(takerID: UUID, onConfirm: @escaping ([UUID : Int]) -> Void) {
        self._takerID = State(initialValue: takerID)
        self._partnerID = State(initialValue: takerID)
        self.onConfirm = onConfirm
    }

    var isFivePlayers : Bool {
        game.playerScores.count == 5
    }

    var points : [UUID : Int] {
        var deal = deal
        deal.taker = game.indexOf(playerID: takerID) ?? 0
        deal.partner = isFivePlayers ? game.indexOf(playerID: partnerID) : nil

        let scores = deal.scores(playerCount: game.playerScores.count)
        var points = [UUID : Int]()
        for (index, playerScore) in game.playerScores.enumerated() {
            points[playerScore.player.id] = scores[index]
        }
        return points
    }

    var pointsCaption : String {
        let difference = deal.points - deal.required
        return "needs \(deal.required) · \(difference >= 0 ? "+" : "")\(difference)"
    }

    var body: some View {
        RoundEntryLayout(title: "Tarot") {
            RoundSection(title: "Taker") {
                PlayerPickRow(players: game.playerScores, selected: $takerID)
            }

            if isFivePlayers {
                RoundSection(title: "Called king") {
                    PlayerPickRow(players: game.playerScores, selected: $partnerID)
                }
            }

            RoundSection(title: "Contract") {
                ChoiceChips(items: TarotDeal.Contract.allCases, selection: $deal.contract, minimumWidth: 150) { $0.name }
            }

            RoundSection(title: "Oudlers") {
                ChoiceChips(items: [0, 1, 2, 3], selection: $deal.bouts) { "\($0)" }
            }

            RoundSection(title: "Attack points") {
                PointsKeypadEntry(text: pointsEntered ? "\(deal.points)" : "—",
                                  caption: pointsEntered ? pointsCaption : "needs \(deal.required)",
                                  maximum: 91) { points in
                    deal.points = points
                    pointsEntered = true
                }
            }

            RoundSection(title: "Petit au bout") {
                ChoiceChips(items: game.options.tarotPetitDefense ? [TarotDeal.Side.none, .attack, .defense] : [TarotDeal.Side.none, .attack],
                            selection: $deal.petitAuBout, minimumWidth: 100) {
                    switch $0 {
                    case .none: return "—"
                    case .attack: return "Attack"
                    case .defense: return "Defense"
                    }
                }
            }

            RoundSection(title: "Poignée") {
                ChoiceChips(items: TarotDeal.poignees, selection: $deal.poignee, minimumWidth: 80) {
                    switch $0 {
                    case 20: return "Simple"
                    case 30: return "Double"
                    case 40: return "Triple"
                    default: return "—"
                    }
                }
            }
        } preview: {
            RoundPreview(points: pointsEntered ? points : [:],
                         caption: pointsEntered ? (deal.isMade ? "Contract made" : "Contract down") : nil)
        } confirm: {
            ConfirmBar(isEnabled: pointsEntered) {
                onConfirm(points)
            }
        }
        .onChange(of: takerID) {
            partnerID = takerID
        }
    }
}
