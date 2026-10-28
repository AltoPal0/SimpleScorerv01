//
//  GameRules.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation

struct GameRules: Identifiable, Hashable {

    let id: String
    let name: String
    var aliases: [String] = []

    // Every player scores once per round : a missing score is filled with 0 to keep rows aligned
    var roundsInSync = true
    var lowestScoreWins = false

    // false for a game typed by the user that is not in the library (universal score entry)
    var isInLibrary = true

    static let universal = GameRules(id: "universal", name: "", isInLibrary: false)

    static func custom(named name: String) -> GameRules {
        GameRules(id: "custom." + GameRules.normalized(name), name: name, isInLibrary: false)
    }

    var displayName: String {
        name.isEmpty ? "Game" : name
    }

    func matches(_ query: String) -> Bool {
        let query = GameRules.normalized(query)
        guard !query.isEmpty else { return false }

        return ([name] + aliases).contains { candidate in
            // Match from the beginning of any word : "qui" finds "6 qui prend"
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
        GameRules(id: "molkky", name: "Mölkky", aliases: ["Molky", "Molkky"]),
        GameRules(id: "belote", name: "Belote"),
        GameRules(id: "coinche", name: "Coinche", aliases: ["Belote coinchée"]),
        GameRules(id: "tarot", name: "Tarot"),
        GameRules(id: "yams", name: "Yams", aliases: ["Yahtzee", "Yatzy", "Yam's"]),
        GameRules(id: "skyjo", name: "Skyjo", lowestScoreWins: true),
        GameRules(id: "scrabble", name: "Scrabble"),
        GameRules(id: "rami", name: "Rami", aliases: ["Rummy"], lowestScoreWins: true),
        GameRules(id: "uno", name: "Uno"),
        GameRules(id: "6nimmt", name: "6 qui prend", aliases: ["6 nimmt", "Six qui prend"], lowestScoreWins: true),
        GameRules(id: "petanque", name: "Pétanque"),
        GameRules(id: "catan", name: "Catan", roundsInSync: false),
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
