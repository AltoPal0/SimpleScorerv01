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

// Games played on this device, the most played first, as the previous players
enum RecentGames {

    static let key = "recentGames"
    // Games of the library dragged to the trash : no longer offered, still found when typed
    static let hiddenKey = "hiddenGames"

    static func load() -> [SavedGame] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let games = try? JSONDecoder().decode([SavedGame].self, from: data)
        else {
            return []
        }
        return games.sorted { $0.counter != $1.counter ? $0.counter > $1.counter : $0.lastPlayed > $1.lastPlayed }
    }

    static func save(_ games: [SavedGame]) {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func record(name: String) {
        guard !name.isEmpty else { return }
        // Played again : offered again
        unhide(id: GameLibrary.rules(named: name).id)

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

    // MARK: - Trash

    static func hiddenIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: hiddenKey) ?? [])
    }

    // Out of the recent games, and out of the library offered when it's one of its games
    static func trash(name: String) {
        remove(name: name)
        let rules = GameLibrary.rules(named: name)
        if rules.isInLibrary {
            UserDefaults.standard.set(Array(hiddenIDs().union([rules.id])), forKey: hiddenKey)
        }
    }

    static func unhide(id: String) {
        var hidden = hiddenIDs()
        if hidden.remove(id) != nil {
            UserDefaults.standard.set(Array(hidden), forKey: hiddenKey)
        }
    }
}
