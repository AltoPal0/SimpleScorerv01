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
// 162 card points per deal (dix de der included), 250 for a capot

struct CoincheDeal {
    
    enum Scoring: String, Codable {
        // The taking team scores the contract announced, a contract down gives 160 to the other team
        case announced
        // The contract plus the card points rounded to the ten
        case pointsMade
    }
    
    static let contracts = [80, 90, 100, 110, 120, 130, 140, 150, 160, Coinche.capot]
    
    var takerTeam = 0
    var contract = 80
    // 1, 2 when coinchée, 4 when surcoinchée
    var multiplier = 1
    // Card points of the taking team, the defense has the rest of the 162
    var takerPoints = 0
    var takerIsCapot = false
    // Team holding belote-rebelote, +20 when the players count it
    var beloteTeam: Int?
    
    // House rules
    var scoring = Scoring.announced
    var defenseScores = false
    var countsBelote = false
    
    var beloteBonus: (taker: Int, defense: Int) {
        guard countsBelote, let beloteTeam = beloteTeam else { return (0, 0) }
        return beloteTeam == takerTeam ? (20, 0) : (0, 20)
    }
    
    var isMade: Bool {
        if contract == Coinche.capot {
            return takerIsCapot
        }
        return takerIsCapot || takerPoints + beloteBonus.taker >= contract
    }
    
    // Card points left to the defense, rounded to the ten so that the two teams share 160
    var roundedDefensePoints: Int {
        takerIsCapot ? 0 : 160 - min(160, Int((Double(takerPoints) / 10).rounded()) * 10)
    }
    
    // Points scored by team 0 and team 1
    func teamScores() -> [Int] {
        var taker = 0
        var defense = 0
        
        switch (scoring, isMade) {
        case (.announced, true):
            taker = contract * multiplier
            defense = defenseScores ? roundedDefensePoints : 0
        case (.announced, false):
            // A capot down costs its stake of 250
            defense = (contract == Coinche.capot ? Coinche.capot : 160) * multiplier
        case (.pointsMade, true) where multiplier > 1:
            taker = (takerIsCapot ? Coinche.capot : 160) + contract * multiplier
        case (.pointsMade, true):
            taker = (takerIsCapot ? Coinche.capot : 160 - roundedDefensePoints) + contract
            defense = defenseScores ? roundedDefensePoints : 0
        case (.pointsMade, false):
            defense = 160 + contract * multiplier
        }
        
        taker += beloteBonus.taker
        defense += beloteBonus.defense
        return takerTeam == 0 ? [taker, defense] : [defense, taker]
    }
}

enum Coinche {
    static let capot = 250
    static let target = 2000
    
    // 2 players are 2 teams, with 4 players : 1st & 2nd against 3rd & 4th
    static func team(ofPlayerAt index: Int, playerCount: Int) -> Int {
        playerCount == 4 ? index / 2 : index
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
        
        // Fits 4 on a line
        var shortName: String {
            switch self {
            case .gardeSans: return "G.S"
            case .gardeContre: return "G.C"
            default: return name
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
    // Players who declared a misère : 10 points from each other player, whatever the contract
    var miseres = [Int]()
    
    static let misere = 10

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
        
        for player in miseres where scores.indices.contains(player) {
            for index in scores.indices {
                scores[index] += index == player ? TarotDeal.misere * (playerCount - 1) : -TarotDeal.misere
            }
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

// MARK: - Gang of Four
// The player out of cards ends the round, the others score the cards left, more for many cards

enum GangOfFour {
    static let cards = 16
    
    static func penalty(cardsLeft: Int) -> Int {
        switch cardsLeft {
        case ...0: return 0
        case 1...7: return cardsLeft
        case 8...10: return cardsLeft * 2
        case 11...13: return cardsLeft * 3
        default: return min(cardsLeft, cards) * 4
        }
    }
    
    // The direction of play changes every round, clockwise first
    static func isClockwise(round: Int) -> Bool {
        round % 2 == 0
    }
}

// MARK: - Cabo
// Lowest total wins, the game ends when someone goes over 100

enum Cabo {
    static let target = 100
    static let fallback = 50
    static let failedCallPenalty = 10
    static let kamikaze = 50
    
    // Exactly 100 brings the player back to 50, once in the game
    static func total(of points: [Int]) -> Int {
        var total = 0
        var fellBack = false
        for points in points {
            total += points
            if total == target && !fellBack {
                total = fallback
                fellBack = true
            }
        }
        return total
    }
    
    // Points of a round : the caller scores 0 with the lowest hand, a tie or worse costs 10 more.
    // Kamikaze (two 12 and two 13) : 0 for that player, 50 for the others
    static func roundPoints(hands: [Int], caller: Int, kamikaze: Int?) -> [Int] {
        if let kamikaze = kamikaze {
            return hands.indices.map { $0 == kamikaze ? 0 : Cabo.kamikaze }
        }
        var points = hands
        if hands.indices.contains(caller) {
            let others = hands.indices.filter { $0 != caller }.map { hands[$0] }
            let callerIsLowest = others.allSatisfy { hands[caller] < $0 }
            points[caller] = callerIsLowest ? 0 : hands[caller] + failedCallPenalty
        }
        return points
    }
}

// MARK: - Darts

enum Darts {
    static let playerCounts = 1...8
    // Around the clock : 1 to 20, then the bull
    static let clockTargets = 21
    // Shanghai : one round per number, from 1 to 7
    static let shanghaiRounds = 7

    // Cricket : 20 down to 15, then the bull scoring 25. 3 marks close a number
    static let cricketNumbers = [20, 19, 18, 17, 16, 15, 25]
    static let marksToClose = 3
    // 3 darts, a triple each : no bull triple, so 6 marks at most on the bull
    static let maxMarksPerTurn = 9
    static let maxBullMarksPerTurn = 6

    static func cricketLabel(_ number: Int) -> String {
        number == 25 ? L("Bull") : "\(number)"
    }

    // The marks of a player on each number, all turns added
    static func cricketMarks(of turns: [[Int]]) -> [Int] {
        var marks = Array(repeating: 0, count: cricketNumbers.count)
        for turn in turns {
            for index in marks.indices where turn.indices.contains(index) {
                marks[index] += turn[index]
            }
        }
        return marks
    }

    // Points of the turn of a player : the marks over 3 score while an opponent hasn't closed the number.
    // For the player himself, or for the opponents still open when the game is cut-throat
    static func cricketPoints(hits: [Int], player: Int, marks: [[Int]], cutThroat: Bool) -> [Int: Int] {
        var points = [Int: Int]()
        for (index, number) in cricketNumbers.enumerated() where hits.indices.contains(index) {
            let before = marks[player][index]
            let extra = max(0, before + hits[index] - marksToClose) - max(0, before - marksToClose)
            guard extra > 0 else { continue }
            let open = marks.indices.filter { $0 != player && marks[$0][index] < marksToClose }
            if cutThroat {
                for opponent in open {
                    points[opponent, default: 0] += extra * number
                }
            } else if !open.isEmpty {
                points[player, default: 0] += extra * number
            }
        }
        return points
    }

    // Shanghai : the hits are singles, doubles and triples of the number of the round
    static func shanghaiPoints(number: Int, hits: [Int]) -> Int {
        number * hits.enumerated().reduce(0) { $0 + $1.element * ($1.offset + 1) }
    }

    // A single, a double and a triple in the same turn
    static func isShanghai(_ hits: [Int]) -> Bool {
        hits.count == 3 && hits.allSatisfy { $0 > 0 }
    }

    // 501 and 301 : a turn going under 0, or leaving 1 when the game ends on a double, is a bust and counts nothing
    static func countdownTotal(of points: [Int], start: Int, doubleOut: Bool) -> Int {
        var total = 0
        for points in points {
            let left = start - (total + points)
            if left < 0 || (doubleOut && left == 1) {
                continue
            }
            total += points
        }
        return total
    }
}

// MARK: - Pétanque

enum Petanque {
    static let maxPointsPerMene = 6
}
