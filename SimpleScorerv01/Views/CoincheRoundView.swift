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

    var fullDeal : CoincheDeal {
        var deal = deal
        deal.beloteTeam = belote < 0 ? nil : belote
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
                ChoiceChips(items: [false, true], selection: $deal.takerIsCapot, minimumWidth: 150) { $0 ? "Capot" : "Card points" }
                if !deal.takerIsCapot {
                    PointsDial(value: $deal.takerPoints, range: 0...162,
                               caption: "defense \(162 - deal.takerPoints)")
                }
            }

            RoundSection(title: "Belote · Rebelote") {
                ChoiceChips(items: [-1, 0, 1], selection: $belote, minimumWidth: 100) { $0 < 0 ? "—" : game.coincheTeamName($0) }
            }
        } preview: {
            RoundPreview(points: points, caption: fullDeal.isMade ? "Contract made" : "Contract down")
        } confirm: {
            ConfirmBar(isEnabled: true) {
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
