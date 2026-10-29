//
//  Score.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 3/19/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import Foundation

struct PlayerScore: Identifiable, Equatable {
    
    var id = UUID()
    var player: Player
    var pointsList: [Points]

    func indexFor(round: Int) -> Int? {
        for index in self.pointsList.indices {
            if self.pointsList[index].round == round {
                return index
            }
        }
        return nil
    }
    
    func totalScore() -> Int {
        var total = 0
        for index in self.pointsList.indices {
            total += self.pointsList[index].score
        }
        return total
    }
    
    mutating func addPoints(scoreValue: Int, marks: [Int]? = nil) {
        pointsList.append(Points(score: scoreValue, round: pointsList.count, marks: marks))
    }
    
    mutating func modifyScore(newScore: Int, forRound: Int) {
        pointsList[indexFor(round: forRound)!].score = newScore
    }
    
    mutating func resetScore () {
        pointsList = []
    }
    
    static func ==(lhs: PlayerScore, rhs: PlayerScore) -> Bool {
        return lhs.id == rhs.id
    }
    
}

struct Points : Identifiable, Hashable {
    var id = UUID()
    var score : Int
    var round : Int
    // Darts : the hits behind the score, on the cricket numbers or single / double / triple at Shanghai
    var marks : [Int]? = nil
    
}

extension PlayerScore {
    // Darts : the hits of each turn as saved, nil when no turn has any
    var savedMarks : [[Int]]? {
        guard pointsList.contains(where: { $0.marks != nil }) else { return nil }
        return pointsList.map { $0.marks ?? [] }
    }

    // Saved points back in the list, with their hits when there are some
    mutating func addPoints(_ points: [Int], marks: [[Int]]?) {
        for (index, score) in points.enumerated() {
            let turnMarks = marks.flatMap { $0.indices.contains(index) && !$0[index].isEmpty ? $0[index] : nil }
            addPoints(scoreValue: score, marks: turnMarks)
        }
    }

    init() {
        self.id = UUID()
        self.player = Player()
        self.pointsList = []
        
    }
}
