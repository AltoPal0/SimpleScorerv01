//
//  GameSnapshot.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation

// The game being played, saved on the device : an interrupted game starts again where it was
struct GameSnapshot: Codable {

    struct SavedPlayer: Codable {
        var id: UUID
        var name: String
        var initials: String
        var gradientIndex: Int?
        var points: [Int]
        // Darts : the hits of each turn, nil for the other games
        var marks: [[Int]]? = nil
    }

    var players: [SavedPlayer]
    // nil until the game is chosen, "" for the universal entry without name
    var gameName: String?
    // History entry of the game, so that it goes on instead of starting a new one
    var recordID: UUID?
    var recordDate: Date

    static let key = "currentGame"

    static func load() -> GameSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(GameSnapshot.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: GameSnapshot.key)
        }
    }
}
