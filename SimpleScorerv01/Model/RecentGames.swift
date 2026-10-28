//
//  RecentGames.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation

struct SavedGame: Codable, Equatable {
    var name: String
    var counter: Int
    var lastPlayed: Date
}

// Games played on this device, most recent first
enum RecentGames {

    static let key = "recentGames"

    static func load() -> [SavedGame] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let games = try? JSONDecoder().decode([SavedGame].self, from: data)
        else {
            return []
        }
        return games
    }

    static func save(_ games: [SavedGame]) {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func record(name: String) {
        guard !name.isEmpty else { return }

        var games = load()
        let key = GameRules.normalized(name)
        if let idx = games.firstIndex(where: { GameRules.normalized($0.name) == key }) {
            var game = games.remove(at: idx)
            game.counter += 1
            game.lastPlayed = Date()
            games.insert(game, at: 0)
        } else {
            games.insert(SavedGame(name: name, counter: 1, lastPlayed: Date()), at: 0)
        }
        save(games)
    }

    static func remove(name: String) {
        save(load().filter { $0.name != name })
    }
}
