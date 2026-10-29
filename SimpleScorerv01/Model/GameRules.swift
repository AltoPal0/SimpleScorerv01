//
//  GameRules.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation

enum GameKind {
    case
    universal ,
    molkky ,
    coinche ,
    tarot ,
    scrabble ,
    uno ,
    petanque ,
    gangOfFour ,
    cabo ,
    darts
}

// The darts games most played, picked once Darts is chosen
enum DartsVariant: String, CaseIterable {
    case x501, x301, cricket, aroundTheClock, shanghai

    // Counting down to 0 : the score shown is what is left
    var countsDown: Bool {
        self == .x501 || self == .x301
    }

    // So that no one picks the wrong one
    var summary: String {
        switch self {
        case .x501: return L("From 501 down to exactly 0, each turn takes off its points. Over 0 is a bust.")
        case .x301: return L("The same from 301 : a shorter game.")
        case .cricket: return L("Close 15 to 20 and the bull with 3 marks each, on a board : the points are counted.")
        case .aroundTheClock: return L("Hit 1 to 20 in order, then the bull. The arrows move the player to the number reached.")
        case .shanghai: return L("7 rounds, aim at the number of the round. Single, double and triple at once : Shanghai!")
        }
    }
}

struct GameRules: Identifiable, Hashable {

    let id: String
    let name: String
    var aliases: [String] = []
    var kind = GameKind.universal

    // Every player scores once per round : a missing score is filled with 0 to keep rows aligned
    var roundsInSync = true
    var lowestScoreWins = false

    // Score that ends the game, nil when the players decide when to stop
    var target: Int?
    var playerCounts = 1...20

    // false for a game typed by the user that is not in the library (universal score entry)
    var isInLibrary = true
    // Darts : the variant played, nil for the darts family whose variant is still to choose
    var darts: DartsVariant? = nil

    static let universal = GameRules(id: "universal", name: "", isInLibrary: false)

    static func custom(named name: String) -> GameRules {
        GameRules(id: "custom." + GameRules.normalized(name), name: name, isInLibrary: false)
    }

    // In the language of the app : the name itself is the key of the game, in the recent games and the snapshot
    var displayName: String {
        if name.isEmpty {
            return L("Game")
        }
        return isInLibrary ? L(name) : name
    }

    // Darts, before its variant is chosen
    var isDartsFamily: Bool {
        kind == .darts && darts == nil
    }

    // Points of a whole round are entered at once for all the players (deal, mène)
    var entersRounds: Bool {
        [.coinche, .tarot, .uno, .petanque, .gangOfFour, .cabo].contains(kind) || darts == .cricket
    }

    func supports(playerCount: Int) -> Bool {
        playerCounts.contains(playerCount) && (kind != .coinche || playerCount == 2 || playerCount == 4)
    }

    var playerCountHint: String {
        kind == .coinche ? L("2 or 4 players") : L("%ld–%ld players", playerCounts.lowerBound, playerCounts.upperBound)
    }

    func total(of points: [Int]) -> Int {
        switch kind {
        case .molkky:
            // Going over 50 sends the player back to 25
            return points.reduce(0) { total, points in
                total + points > Molkky.target ? Molkky.fallback : total + points
            }
        case .cabo:
            return Cabo.total(of: points)
        case .darts where darts == .aroundTheClock:
            return min(points.reduce(0, +), Darts.clockTargets)
        default:
            return points.reduce(0, +)
        }
    }

    func matches(_ query: String) -> Bool {
        let query = GameRules.normalized(query)
        guard !query.isEmpty else { return false }

        return ([name] + aliases).contains { candidate in
            // Match from the beginning of any word : "coin" finds "Belote coinchée"
            let words = GameRules.normalized(candidate).split(separator: " ")
            return words.indices.contains { words[$0...].joined(separator: " ").hasPrefix(query) }
        }
    }

    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GameLibrary {

    static let games: [GameRules] = [
        GameRules(id: "molkky", name: "Mölkky", aliases: ["Molky", "Molkky"], kind: .molkky, roundsInSync: false, target: Molkky.target),
        GameRules(id: "coinche", name: "Coinche", aliases: ["Belote coinchée", "Contrée"], kind: .coinche, target: Coinche.target, playerCounts: 2...4),
        GameRules(id: "tarot", name: "Tarot", kind: .tarot, playerCounts: 3...5),
        GameRules(id: "scrabble", name: "Scrabble", kind: .scrabble, playerCounts: 2...4),
        GameRules(id: "uno", name: "Uno", kind: .uno, target: 500, playerCounts: 2...10),
        GameRules(id: "petanque", name: "Pétanque", aliases: ["Boules"], kind: .petanque, target: 13, playerCounts: 2...4),
        GameRules(id: "gangoffour", name: "Gang of 4", aliases: ["Gang of Four", "Gang"], kind: .gangOfFour, lowestScoreWins: true, target: 100, playerCounts: 3...4),
        GameRules(id: "cabo", name: "Cabo", aliases: ["Gabot", "Gabo"], kind: .cabo, lowestScoreWins: true, target: 100, playerCounts: 2...4),
        GameRules(id: "darts", name: "Darts", aliases: ["Fléchettes", "Dart"], kind: .darts, playerCounts: Darts.playerCounts),
    ] + dartsVariants

    // Played once picked on the screen of the variants, or typed
    static let dartsVariants: [GameRules] = [
        GameRules(id: "darts.501", name: "Darts 501", aliases: ["501", "Fléchettes 501"], kind: .darts, target: 501, playerCounts: Darts.playerCounts, darts: .x501),
        GameRules(id: "darts.301", name: "Darts 301", aliases: ["301", "Fléchettes 301"], kind: .darts, target: 301, playerCounts: Darts.playerCounts, darts: .x301),
        GameRules(id: "darts.cricket", name: "Cricket", aliases: ["Darts Cricket", "Fléchettes Cricket"], kind: .darts, playerCounts: Darts.playerCounts, darts: .cricket),
        GameRules(id: "darts.clock", name: "Around the Clock", aliases: ["Tour de l'horloge", "Horloge", "Clock"], kind: .darts, roundsInSync: false, target: Darts.clockTargets, playerCounts: Darts.playerCounts, darts: .aroundTheClock),
        GameRules(id: "darts.shanghai", name: "Shanghai", kind: .darts, playerCounts: Darts.playerCounts, darts: .shanghai),
    ]

    static func variant(_ variant: DartsVariant) -> GameRules {
        dartsVariants.first { $0.darts == variant }!
    }

    static func suggestions(for query: String) -> [GameRules] {
        games.filter { $0.matches(query) }
    }

    // Library game with this exact name or alias, otherwise a custom game
    static func rules(named name: String) -> GameRules {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .universal }

        let key = GameRules.normalized(name)
        if let game = games.first(where: { game in
            ([game.name] + game.aliases).contains { GameRules.normalized($0) == key }
        }) {
            return game
        }
        return .custom(named: name.prefix(1).uppercased() + name.dropFirst())
    }
}
