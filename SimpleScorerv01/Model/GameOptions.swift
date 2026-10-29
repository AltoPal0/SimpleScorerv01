//
//  GameOptions.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation

// House rules of a game, remembered on the device for the next games
struct GameOptions: Codable, Equatable {

    // Score ending the game, nil to keep the one of the rules
    var target: Int?
    // Mölkky : 3 misses in a row and the player is out
    var molkkyMissesOut = true
    // Uno : each player scores the cards left in his own hand and the lowest score wins
    var unoLowestWins = false
    // Coinche
    var coincheScoring = CoincheDeal.Scoring.announced
    var coincheDefenseScores = false
    var coincheBelote = false
    // Tarot : the defense can score the petit au bout, often luck so off by default
    var tarotPetitDefense = false
    // Cabo with a 54 cards deck : the kamikaze hand is four kings, two 12 and two 13 with the Cabo deck
    var caboKamikazeFourKings = true
    // Darts 501 and 301 : the last dart is a double, so 1 left is a bust as well
    var dartsDoubleOut = true
    
    init() {}
    
    // Options saved by an older version lack the newer keys : they keep their default
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        target = try container.decodeIfPresent(Int.self, forKey: .target)
        molkkyMissesOut = try container.decodeIfPresent(Bool.self, forKey: .molkkyMissesOut) ?? true
        unoLowestWins = try container.decodeIfPresent(Bool.self, forKey: .unoLowestWins) ?? false
        coincheScoring = try container.decodeIfPresent(CoincheDeal.Scoring.self, forKey: .coincheScoring) ?? .announced
        coincheDefenseScores = try container.decodeIfPresent(Bool.self, forKey: .coincheDefenseScores) ?? false
        coincheBelote = try container.decodeIfPresent(Bool.self, forKey: .coincheBelote) ?? false
        tarotPetitDefense = try container.decodeIfPresent(Bool.self, forKey: .tarotPetitDefense) ?? false
        caboKamikazeFourKings = try container.decodeIfPresent(Bool.self, forKey: .caboKamikazeFourKings) ?? true
        dartsDoubleOut = try container.decodeIfPresent(Bool.self, forKey: .dartsDoubleOut) ?? true
    }

    // Targets the players can pick, empty when the game has no target to change
    static func targets(for kind: GameKind) -> [Int] {
        switch kind {
        case .coinche: return [1000, 1500, 2000]
        case .uno: return [250, 500]
        case .petanque: return [11, 13, 15]
        default: return []
        }
    }

    static func hasOptions(_ kind: GameKind) -> Bool {
        kind == .molkky || kind == .uno || kind == .coinche || kind == .tarot || kind == .cabo || kind == .darts || !targets(for: kind).isEmpty
    }

    var caboKamikazeHand: String {
        caboKamikazeFourKings ? L("four kings") : L("two 12 and two 13")
    }
    
    static func key(for rules: GameRules) -> String {
        "gameOptions." + rules.id
    }

    static func load(for rules: GameRules) -> GameOptions {
        guard let data = UserDefaults.standard.data(forKey: key(for: rules)),
              let options = try? JSONDecoder().decode(GameOptions.self, from: data)
        else {
            return GameOptions()
        }
        return options
    }

    func save(for rules: GameRules) {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: GameOptions.key(for: rules))
        }
    }
}
