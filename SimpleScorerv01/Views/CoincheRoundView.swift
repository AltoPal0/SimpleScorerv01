//
//  CoincheRoundView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct CoincheRoundView: View {

    @EnvironmentObject var game : Game

    var playerID : UUID
    var onConfirm : ([UUID : Int]) -> Void

    @State private var deal = CoincheDeal()

    // Belote holder as a chip : nil, team 0 or team 1
    @State private var belote = -1

    // Card points of the taking team, typed on the keypad
    @State private var pointsEntered = false

    // The deal with the house rules of the players
    var fullDeal : CoincheDeal {
        var deal = deal
        deal.beloteTeam = belote < 0 ? nil : belote
        deal.scoring = game.options.coincheScoring
        deal.defenseScores = game.options.coincheDefenseScores
        deal.countsBelote = game.options.coincheBelote
        return deal
    }

    var teamScores : [Int] {
        fullDeal.teamScores()
    }

    // Every member of a team gets the team points
    var points : [UUID : Int] {
        var points = [UUID : Int]()
        for playerScore in game.playerScores {
            points[playerScore.player.id] = teamScores[game.coincheTeam(of: playerScore)]
        }
        return points
    }

    var pointsText : String {
        if deal.takerIsCapot { return "Capot" }
        return pointsEntered ? "\(deal.takerPoints)" : "—"
    }

    var body: some View {
        RoundEntryLayout(title: "Coinche") {
            RoundSection(title: "Taking team") {
                ChoiceChips(items: [0, 1], selection: $deal.takerTeam, minimumWidth: 150) { game.coincheTeamName($0) }
            }

            RoundSection(title: "Contract") {
                ChoiceChips(items: CoincheDeal.contracts, selection: $deal.contract) {
                    $0 == Coinche.capot ? "Capot" : "\($0)"
                }
                ChoiceChips(items: [1, 2, 4], selection: $deal.multiplier, minimumWidth: 100) {
                    switch $0 {
                    case 2: return "Coinchée"
                    case 4: return "Surcoinchée"
                    default: return "—"
                    }
                }
            }

            RoundSection(title: "Points of \(game.coincheTeamName(deal.takerTeam))") {
                PointsKeypadEntry(text: pointsText,
                                  caption: pointsEntered && !deal.takerIsCapot ? "defense \(162 - deal.takerPoints)" : nil,
                                  maximum: 162,
                                  extraKey: "Capot",
                                  onExtraKey: {
                    deal.takerPoints = 162
                    deal.takerIsCapot = true
                    pointsEntered = true
                }) { points in
                    deal.takerPoints = points
                    deal.takerIsCapot = false
                    pointsEntered = true
                }
            }
            
            if game.options.coincheBelote {
                RoundSection(title: "Belote · Rebelote") {
                    ChoiceChips(items: [-1, 0, 1], selection: $belote, minimumWidth: 100) { $0 < 0 ? "—" : game.coincheTeamName($0) }
                }
            }
        } preview: {
            RoundPreview(points: pointsEntered ? points : [:],
                         caption: pointsEntered ? (fullDeal.isMade ? "Contract made" : "Contract down") : nil)
        } confirm: {
            ConfirmBar(isEnabled: pointsEntered) {
                onConfirm(points)
            }
        }
        .onAppear {
            if let playerScore = game.playerScores.first(where: { $0.player.id == playerID }) {
                deal.takerTeam = game.coincheTeam(of: playerScore)
            }
        }
    }
}
