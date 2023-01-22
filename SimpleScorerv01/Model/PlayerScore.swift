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
    
    mutating func addPoints(scoreValue: Int) {
        pointsList.append(Points(score: scoreValue, round: pointsList.count))
    }
    
    mutating func modifyScore(newScore: Int, forRound: Int) {
        pointsList[indexFor(round: forRound)!] = Points(score: newScore, round: forRound)
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
    
}

extension PlayerScore {
    init() {
        self.id = UUID()
        self.player = Player()
        self.pointsList = []
        
    }
}
