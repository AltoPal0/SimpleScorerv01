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
    cabo
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

    static let universal = GameRules(id: "universal", name: "", isInLibrary: false)

    static func custom(named name: String) -> GameRules {
        GameRules(id: "custom." + GameRules.normalized(name), name: name, isInLibrary: false)
    }

    var displayName: String {
        name.isEmpty ? "Game" : name
    }

    // Points of a whole round are entered at once for all the players (deal, mène)
    var entersRounds: Bool {
        [.coinche, .tarot, .uno, .petanque, .gangOfFour, .cabo].contains(kind)
    }

    func supports(playerCount: Int) -> Bool {
        playerCounts.contains(playerCount) && (kind != .coinche || playerCount == 2 || playerCount == 4)
    }

    var playerCountHint: String {
        kind == .coinche ? "2 or 4 players" : "\(playerCounts.lowerBound)–\(playerCounts.upperBound) players"
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
        GameRules(id: "gangoffour", name: "Gang of Four", aliases: ["Gang of 4", "Gang"], kind: .gangOfFour, lowestScoreWins: true, target: 100, playerCounts: 3...4),
        GameRules(id: "cabo", name: "Cabo", aliases: ["Gabot", "Gabo"], kind: .cabo, lowestScoreWins: true, target: 100, playerCounts: 2...4),
    ]

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
