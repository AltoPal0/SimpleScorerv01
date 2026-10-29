//
//  GameRecord.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation
import SwiftData

// A player as saved in the history, with his final total computed by the rules of the game
struct RecordedPlayer: Codable, Hashable {
    var name: String
    var initials: String
    var gradientIndex: Int?
    var points: [Int]
    var total: Int
    // Darts : the hits of each turn, nil for the other games
    var marks: [[Int]]? = nil
}

// One game of the history : saved from the first points, updated with every score
@Model
final class GameRecord {

    @Attribute(.unique) var id: UUID
    var gameName: String
    var gameID: String
    var date: Date
    var lowestScoreWins: Bool
    // Players as JSON : sturdier than an array of structs in SwiftData on iOS 17
    var playersData: Data

    init(id: UUID, gameName: String, gameID: String, date: Date, lowestScoreWins: Bool, players: [RecordedPlayer]) {
        self.id = id
        self.gameName = gameName
        self.gameID = gameID
        self.date = date
        self.lowestScoreWins = lowestScoreWins
        self.playersData = (try? JSONEncoder().encode(players)) ?? Data()
    }

    var players: [RecordedPlayer] {
        get { (try? JSONDecoder().decode([RecordedPlayer].self, from: playersData)) ?? [] }
        set { playersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    // Best first
    var ranking: [RecordedPlayer] {
        players.sorted { lowestScoreWins ? $0.total < $1.total : $0.total > $1.total }
    }
}

final class HistoryStore {

    static let shared = HistoryStore()

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: GameRecord.self)
        } catch {
            // The app keeps working without history rather than crashing
            print("History unavailable :", error)
            container = try! ModelContainer(for: GameRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }

    @MainActor
    func save(id: UUID, gameName: String, gameID: String, date: Date, lowestScoreWins: Bool, players: [RecordedPlayer]) {
        let context = container.mainContext
        let descriptor = FetchDescriptor<GameRecord>(predicate: #Predicate { $0.id == id })

        if let record = try? context.fetch(descriptor).first {
            record.gameName = gameName
            record.gameID = gameID
            record.lowestScoreWins = lowestScoreWins
            record.players = players
        } else {
            context.insert(GameRecord(id: id, gameName: gameName, gameID: gameID, date: date, lowestScoreWins: lowestScoreWins, players: players))
        }
        try? context.save()
    }

    @MainActor
    func delete(id: UUID) {
        let context = container.mainContext
        try? context.delete(model: GameRecord.self, where: #Predicate { $0.id == id })
        try? context.save()
    }
}
