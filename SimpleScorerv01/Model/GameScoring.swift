//
//  GameScoring.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation

// MARK: - Mölkky

enum Molkky {
    static let target = 50
    static let fallback = 25
    static let missesToBeOut = 3

    // A throw of 0 is a miss : 3 in a row and the player is out
    static func consecutiveMisses(_ points: [Int]) -> Int {
        points.reversed().prefix { $0 == 0 }.count
    }
}

// MARK: - Coinche
// "Points faits" scoring : 162 card points per deal (dix de der included), 250 for a capot

struct CoincheDeal {

    static let contracts = [80, 90, 100, 110, 120, 130, 140, 150, 160, Coinche.capot]

    var takerTeam = 0
    var contract = 80
    // 1, 2 when coinchée, 4 when surcoinchée
    var multiplier = 1
    // Card points of the taking team, the defense has the rest of the 162
    var takerPoints = 81
    var takerIsCapot = false
    // Team holding belote-rebelote : +20 whatever the result of the contract
    var beloteTeam: Int?

    var isMade: Bool {
        if contract == Coinche.capot {
            return takerIsCapot
        }
        return takerIsCapot || takerPoints + (beloteTeam == takerTeam ? 20 : 0) >= contract
    }

    // Points scored by team 0 and team 1
    func teamScores() -> [Int] {
        var taker = 0
        var defense = 0

        if !isMade {
            defense = 160 + contract * multiplier
        } else if multiplier > 1 {
            taker = (takerIsCapot ? Coinche.capot : 160) + contract * multiplier
        } else if takerIsCapot {
            taker = Coinche.capot + contract
        } else {
            // Card points rounded to the ten, the two teams still share 160
            let rounded = min(160, Int((Double(takerPoints) / 10).rounded()) * 10)
            taker = rounded + contract
            defense = 160 - rounded
        }

        var scores = takerTeam == 0 ? [taker, defense] : [defense, taker]
        if let beloteTeam = beloteTeam {
            scores[beloteTeam] += 20
        }
        return scores
    }
}

enum Coinche {
    static let capot = 250
    static let target = 2000

    // With 4 players, partners sit face to face : 1st & 3rd against 2nd & 4th
    static func team(ofPlayerAt index: Int) -> Int {
        index % 2
    }
}

// MARK: - Tarot
// French federation scoring (FFT), without chelem

struct TarotDeal {

    enum Contract: Int, CaseIterable {
        case petite = 1, garde = 2, gardeSans = 4, gardeContre = 6

        var name: String {
            switch self {
            case .petite: return "Petite"
            case .garde: return "Garde"
            case .gardeSans: return "Garde sans"
            case .gardeContre: return "Garde contre"
            }
        }
    }

    enum Side {
        case none, attack, defense
    }

    static let requiredPoints = [56, 51, 41, 36]
    static let poignees = [0, 20, 30, 40]

    var taker = 0
    // 5 players : the called partner, the taker himself when he called his own king
    var partner: Int?
    var contract = Contract.garde
    var bouts = 1
    var points = 51
    var petitAuBout = Side.none
    var poignee = 0

    var required: Int {
        TarotDeal.requiredPoints[bouts]
    }

    var isMade: Bool {
        points >= required
    }

    // What one defender pays (negative when the attack lost)
    var dealValue: Int {
        let sign = isMade ? 1 : -1
        var value = (25 + abs(points - required)) * sign
        switch petitAuBout {
        case .attack: value += 10
        case .defense: value -= 10
        case .none: break
        }
        // The poignée goes to the side that wins the deal, it is not multiplied
        return value * contract.rawValue + poignee * sign
    }

    func scores(playerCount: Int) -> [Int] {
        let value = dealValue
        var scores = Array(repeating: -value, count: playerCount)

        if playerCount == 5, let partner = partner, partner != taker {
            scores[taker] = 2 * value
            scores[partner] = value
        } else {
            scores[taker] = (playerCount - 1) * value
        }
        return scores
    }
}

// MARK: - Uno
// The winner of the round scores the cards left in the other hands, first to 500 wins

enum Uno {
    static let actionCard = 20
    static let wildCard = 50
}

// MARK: - Pétanque

enum Petanque {
    static let maxPointsPerMene = 6
}
