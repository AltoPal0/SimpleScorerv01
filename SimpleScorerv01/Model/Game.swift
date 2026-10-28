//
//  Game.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 3/19/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import Foundation

struct SavedPlayer: Codable {
    var name: String
    var counter : Int
}


class Game : ObservableObject {
    
    @Published var playerScores = [PlayerScore] ()
    @Published var maxNbrOfRounds = 0

    // nil until the players chose which game they play
    @Published var rules : GameRules?
    @Published var options = GameOptions() {
        didSet {
            if let rules = rules {
                options.save(for: rules)
            }
        }
    }

    // History entry of the game being played, created with its first points
    private var recordID : UUID?
    private var recordDate = Date()

    // MARK: - Game choice
    func choose(rules : GameRules) {
        self.rules = rules
        self.options = GameOptions.load(for: rules)
        RecentGames.record(name: rules.name)
        self.saveSnapshot()
    }

    func needsGameChoice() -> Bool {
        return rules == nil && playerScores.count > 0 && nbrPlayersUnanmed() == 0
    }

    // Game specific entry only when the game is played with a supported number of players
    var activeKind : GameKind {
        guard let rules = rules, rules.supports(playerCount: playerScores.count) else { return .universal }
        return rules.kind
    }

    // A game of the library played with a number of players it doesn't allow
    var hasWrongPlayerCount : Bool {
        guard let rules = rules, rules.isInLibrary, !playerScores.isEmpty else { return false }
        return !rules.supports(playerCount: playerScores.count)
    }

    var entersRounds : Bool {
        return rules?.entersRounds == true && activeKind != .universal
    }

    // MARK: - Game rules
    func total(for playerScore : PlayerScore) -> Int {
        let points = playerScore.pointsList.map { $0.score }
        return rules?.total(of: points) ?? points.reduce(0, +)
    }

    var target : Int? {
        guard activeKind != .universal else { return nil }
        return options.target ?? rules?.target
    }

    var lowestScoreWins : Bool {
        return rules?.lowestScoreWins == true || (activeKind == .uno && options.unoLowestWins)
    }

    func isEliminated(_ playerScore : PlayerScore) -> Bool {
        return activeKind == .molkky && options.molkkyMissesOut
            && Molkky.consecutiveMisses(playerScore.pointsList.map { $0.score }) >= Molkky.missesToBeOut
    }

    // Mölkky : why entering a score for this player deserves a warning, nil when it doesn't
    enum MolkkyWarning {
        case eliminated, alreadyPlayed
    }

    func molkkyWarning(for playerScore : PlayerScore) -> MolkkyWarning? {
        if isEliminated(playerScore) {
            return .eliminated
        }
        return playersYetToPlay(before: playerScore).isEmpty ? nil : .alreadyPlayed
    }

    func molkkyWarningTitle(_ warning : MolkkyWarning, for playerScore : PlayerScore) -> String {
        warning == .eliminated
            ? "\(playerScore.player.name) is out after 3 misses"
            : "\(playerScore.player.name) already played this turn"
    }

    func molkkyWarningMessage(_ warning : MolkkyWarning, for playerScore : PlayerScore) -> String {
        if warning == .eliminated {
            return "Let \(playerScore.player.name) keep playing? Players won't be out after 3 misses anymore."
        }
        return "Still to play : \(playersYetToPlay(before: playerScore).map { $0.player.name }.joined(separator: ", "))."
    }

    // Players won't be out after 3 misses anymore
    func keepEliminatedPlaying() {
        options.molkkyMissesOut = false
    }

    // Mölkky : players still in the game who played fewer turns than this one
    func playersYetToPlay(before playerScore : PlayerScore) -> [PlayerScore] {
        guard activeKind == .molkky else { return [] }
        return playerScores.filter {
            $0.id != playerScore.id && !isEliminated($0) && $0.pointsList.count < playerScore.pointsList.count
        }
    }

    // Points still needed to reach the target, nil for games without target
    func remaining(for playerScore : PlayerScore) -> Int? {
        guard let target = target else { return nil }
        return max(0, target - total(for: playerScore))
    }

    func winner() -> PlayerScore? {
        guard let target = target else { return nil }

        if activeKind == .molkky {
            return playerScores.first { total(for: $0) == target }
        }
        if lowestScoreWins {
            // The game ends when someone reaches the target, the lowest score wins
            guard playerScores.contains(where: { total(for: $0) >= target }) else { return nil }
            return playerScores.min { total(for: $0) < total(for: $1) }
        }
        return playerScores
            .filter { total(for: $0) >= target }
            .max { total(for: $0) < total(for: $1) }
    }

    // Coinche : 2 players are 2 teams, 4 players make 2 teams of partners
    func coincheTeam(of playerScore : PlayerScore) -> Int {
        return Coinche.team(ofPlayerAt: indexOf(player: playerScore.player) ?? 0, playerCount: playerScores.count)
    }

    // Coinche with 4 players : the two teams, as indices of their players. nil for any other game
    var coincheTeams : [[Int]]? {
        guard activeKind == .coinche && playerScores.count == 4 else { return nil }
        return [[0, 1], [2, 3]]
    }

    // The player and the partner sharing the score, or the player alone
    func teamIndices(of index : Int) -> [Int] {
        coincheTeams?.first { $0.contains(index) } ?? [index]
    }

    func coincheTeamName(_ team : Int) -> String {
        return playerScores
            .filter { coincheTeam(of: $0) == team }
            .map { $0.player.initials.isEmpty ? $0.player.name : $0.player.initials }
            .joined(separator: " & ")
    }

    // MARK: - History
    // MARK: - Interrupted game
    func saveSnapshot() {
        GameSnapshot(
            players: playerScores.map { playerScore in
                GameSnapshot.SavedPlayer(
                    id: playerScore.player.id,
                    name: playerScore.player.name,
                    initials: playerScore.player.initials,
                    gradientIndex: playerScore.player.gradientIndex,
                    points: playerScore.pointsList.map { $0.score })
            },
            gameName: rules?.name,
            recordID: recordID,
            recordDate: recordDate
        ).save()
    }

    // A game of the history played again : its scores go on in the same history entry
    func resume(players : [RecordedPlayer], gameID : String, gameName : String, recordID : UUID, date : Date) {
        playerScores = players.map { saved in
            var playerScore = PlayerScore(
                player: Player(name: saved.name, initials: saved.initials, gradientIndex: saved.gradientIndex),
                pointsList: [])
            for points in saved.points {
                playerScore.addPoints(scoreValue: points)
            }
            return playerScore
        }
        
        let rules = gameID == GameRules.universal.id
            ? GameRules.universal
            : GameLibrary.games.first { $0.id == gameID } ?? GameLibrary.rules(named: gameName)
        self.rules = rules
        self.options = GameOptions.load(for: rules)
        self.recordID = recordID
        self.recordDate = date
        self.maxNbrOfRounds = currentMaxNumberOfRounds()
        saveSnapshot()
    }

    // The game as it was when the app was left, empty the first time
    static func restored() -> Game {
        let game = Game()
        guard let snapshot = GameSnapshot.load() else { return game }

        for saved in snapshot.players {
            var playerScore = PlayerScore(
                player: Player(id: saved.id, name: saved.name, initials: saved.initials, gradientIndex: saved.gradientIndex),
                pointsList: [])
            for points in saved.points {
                playerScore.addPoints(scoreValue: points)
            }
            game.playerScores.append(playerScore)
        }
        if let gameName = snapshot.gameName {
            let rules = GameLibrary.rules(named: gameName)
            game.rules = rules
            game.options = GameOptions.load(for: rules)
        }
        game.recordID = snapshot.recordID
        game.recordDate = snapshot.recordDate
        game.maxNbrOfRounds = game.currentMaxNumberOfRounds()
        return game
    }

    func recordHistory() {
        self.saveSnapshot()

        let hasPoints = playerScores.contains { !$0.pointsList.isEmpty }

        MainActor.assumeIsolated {
            guard hasPoints else {
                // Every point was deleted : the game is no longer worth keeping
                if let recordID = recordID {
                    HistoryStore.shared.delete(id: recordID)
                    self.recordID = nil
                }
                return
            }

            if recordID == nil {
                recordID = UUID()
                recordDate = Date()
            }
            HistoryStore.shared.save(
                id: recordID!,
                gameName: rules?.displayName ?? GameRules.universal.displayName,
                gameID: rules?.id ?? GameRules.universal.id,
                date: recordDate,
                lowestScoreWins: lowestScoreWins,
                players: playerScores.map { playerScore in
                    RecordedPlayer(
                        name: playerScore.player.name,
                        initials: playerScore.player.initials,
                        gradientIndex: playerScore.player.gradientIndex,
                        points: playerScore.pointsList.map { $0.score },
                        total: total(for: playerScore))
                })
        }
    }

    // A whole round at once : every player gets his points, 0 when absent from the dictionary
    func addRound(points : [UUID : Int]) {
        let round = self.currentMaxNumberOfRounds()

        for index in self.playerScores.indices {
            while self.playerScores[index].pointsList.count < round {
                self.playerScores[index].addPoints(scoreValue: 0)
            }
            self.playerScores[index].addPoints(scoreValue: points[self.playerScores[index].player.id] ?? 0)
        }

        self.maxNbrOfRounds = self.currentMaxNumberOfRounds()
        self.recordHistory()
    }

    // MARK: - Player functins
    func addPlayer(player: Player) {
        playerScores.append(PlayerScore(player: player, pointsList: []))
    }
    
    func indexOf(player : Player) -> Int? {
        for index in self.playerScores.indices {
            if self.playerScores[index].player.id == player.id {
                return index
            }
        }
        return nil
    }
    
    func indexOf(playerID : UUID) -> Int? {
        for index in self.playerScores.indices {
            if self.playerScores[index].player.id == playerID {
                return index
            }
        }
        return nil
    }
    
    func addEmptyPlayer() {
        self.addPlayer(player: Player())
    }
    
    func addEmptyPlayer(withGradientIndex gradientIndex : Int) {
        var player = Player()
        player.gradientIndex = gradientIndex
        self.addPlayer(player: player)
    }
    
    func removeLastPlayer() {
        if playerScores.count > 0 {
            playerScores.removeLast()
        }
    }
    
    func removePlayer(player : Player) {
        self.playerScores.remove(at: self.indexOf(player: player)!)
    }
    
    func nbrPlayersUnanmed() -> Int {
        
        var nbrPlayers = 0
        
        for playerScore in self.playerScores {
            if playerScore.player.name == Player.defaultName {
                nbrPlayers += 1
            }
        }
        
        return nbrPlayers
    }
    
    func indexOfPlayerWithNoName (playerScore : PlayerScore) -> Int {
        
        var playersWithNoName : [PlayerScore] = []
        
        for playerScore in self.playerScores {
            if playerScore.player.name == Player.defaultName {
                playersWithNoName.append(playerScore)
            }
        }
        
        for (index, pScoreNoName) in playersWithNoName.enumerated() {
            if pScoreNoName.id == playerScore.id {
                return index
            }
        }
        
        return -1
    }
    
    func nbrOfPlayersNeedingNames () -> Int {
        var count = 0
        for playerScore in self.playerScores {
            if playerScore.player.name == Player.defaultName {
                count += 1
            }
        }
        return count
    }
    
    func listNames() -> [String] {
        var names = [String]()
        for playerScore in self.playerScores {
            if playerScore.player.name != Player.defaultName {
                names.append(playerScore.player.name)
            }
        }
        
        return names
    }
    
    func createPreviousPlayers() -> [SavedPlayer] {
        let defaultNames = ["P1","P2","P3","P4","P5","P6","P7","P8","P9","P10","P11","P12","P13","P14","P15","P16","P17","P18","P19","P20"]
        
        var names = [SavedPlayer]()
        for playerScore in self.playerScores {
            if playerScore.player.name != Player.defaultName && !defaultNames.contains(playerScore.player.name) {
                names.append(SavedPlayer(name: playerScore.player.name, counter: 1))
            }
        }
        
        return names
    }
    
    
    
    func updatePreviousPlayers() {

        let defaultNames = ["P1","P2","P3","P4","P5","P6","P7","P8","P9","P10","P11","P12","P13","P14","P15","P16","P17","P18","P19","P20"]
        
        guard let fetchedData = UserDefaults.standard.data(forKey: "previousPlayers")
        else {
            let savedPlayersData = try! JSONEncoder().encode(self.createPreviousPlayers())
            UserDefaults.standard.set(savedPlayersData, forKey: "previousPlayers")
            return
        }
        
        var savedPlayers = try! JSONDecoder().decode([SavedPlayer].self, from: fetchedData)
        
        print("before --- ",savedPlayers.description)

        for playerScore in self.playerScores {
            
            let name = playerScore.player.name
            
            if let idx = savedPlayers.firstIndex(where: { $0.name == name }) {
                savedPlayers[idx].counter += 1
            } else {
                // Verify it's not P1, P2 ...
                if !defaultNames.contains(name) && name != Player.defaultName {
//                    savedPlayers.append(SavedPlayer(name: name, counter: 1))
                    savedPlayers.insert(SavedPlayer(name: name, counter: 1), at: savedPlayers.lastIndex(where: { $0.counter > 1 }) ?? 0)
                }
            }
        }
        
        let savedPlayersData = try! JSONEncoder().encode(savedPlayers.sorted(by: {$0.counter > $1.counter}))
        UserDefaults.standard.set(savedPlayersData, forKey: "previousPlayers")
        
        
        print("after ---",savedPlayers.description)
        
    }
    
    func allPreviousPlayersSelected() -> Bool {
        guard let fetchedData = UserDefaults.standard.data(forKey: "previousPlayers")
        else {
            return true
        }
        
        var savedPlayers = try! JSONDecoder().decode([SavedPlayer].self, from: fetchedData)
        
        for playerScore in self.playerScores {
            let name = playerScore.player.name
            if let idx = savedPlayers.firstIndex(where: { $0.name == name }) {
                savedPlayers.remove(at: idx)
            }
        }
        
        if savedPlayers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func checkIdenticalName(name : String) -> Bool {
        for playerScore in self.playerScores {
            if name.caseInsensitiveCompare(playerScore.player.name) == .orderedSame {
                return true
            }
        }
        
        return false
    }
    
    func avatarInitialsForPlayers() {
        
        var indexOfDifference = 0
        
        var maxDiffs: [Int] = [Int](repeating: 0, count: self.playerScores.count)
        
        for playerScore in self.playerScores.sorted(by: {$0.player.name.lowercased() < $1.player.name.lowercased()}) {
            
            
//                print(playerScore.player.name,"-",player.name)

            for (index, pScore) in self.playerScores.enumerated() {
                
                if playerScore.player.name != pScore.player.name
                    && playerScore.player.name.lowercased()[0] == pScore.player.name.lowercased()[0] {

//                    print(pScore.player.name, " vs.", playerScore.player.name)
                    
//                    print(playerScore.player.name.lowercased()[indexOfDifference],"=?",pScore.player.name.lowercased()[indexOfDifference])
                    
                    while playerScore.player.name.lowercased()[indexOfDifference] == pScore.player.name.lowercased()[indexOfDifference]
                            &&  pScore.player.name.length >= indexOfDifference
                            && playerScore.player.name.length >= indexOfDifference
                    {
                        indexOfDifference += 1
                        
                        if maxDiffs[index] < indexOfDifference {
                            maxDiffs[index] = indexOfDifference
                        }
                    }
                    
                    
                }
                indexOfDifference = 0
            }
            
        }
        
        for (i,maxDiff) in maxDiffs.enumerated() {
//            print("max ",maxDiff," for ",self.playerScores[i].player.name, " - ", self.playerScores[i].player.name)
            if maxDiff > 0 {
                self.playerScores[i].player.initials = self.playerScores[i].player.name[0] + self.playerScores[i].player.name[maxDiff]
            } else {
                self.playerScores[i].player.initials = self.playerScores[i].player.name[0]
            }
        }
    }
    
    // MARK: - Score functions
    
    func addPointsFor(player : Player, points : Int) {
        
        let nbrOfRounds = self.currentMaxNumberOfRounds()
        let pIndex = self.indexOf(player: player)!

        if self.rules?.roundsInSync == false {
            // Players score independently : no 0 to fill the rounds they did not play
            self.playerScores[pIndex].addPoints(scoreValue: points)
        } else if self.playerScores[pIndex].pointsList.count == nbrOfRounds {
            self.playerScores[pIndex].addPoints(scoreValue: points)
        } else if self.playerScores[pIndex].pointsList.count == (nbrOfRounds - 1) {
            self.playerScores[pIndex].addPoints(scoreValue: points)
        } else {
            self.playerScores[pIndex].addPoints(scoreValue: 0)
            self.addPointsFor(player: player, points: points)
        }
        
        self.maxNbrOfRounds = self.currentMaxNumberOfRounds()
        self.recordHistory()
    }
    
    func addPointsFor(player : Player, points : Int, round : Int) {
        
        let pIndex = self.indexOf(player: player)!
        
        if self.playerScores[pIndex].pointsList.count == round {
            self.playerScores[pIndex].addPoints(scoreValue: points)
        } else {
            self.playerScores[pIndex].addPoints(scoreValue: 0)
            self.addPointsFor(player: player, points: points, round: round)
        }
        self.recordHistory()
        
//        self.maxNbrOfRounds = self.currentMaxNumberOfRounds()
    }
    
    // Coinche : partners share their score, a correction goes to both
    func deletePointsFor(player : Player, round : Int) {
        for index in self.teamIndices(of: self.indexOf(player: player)!)
            where self.playerScores[index].pointsList.indices.contains(round) {
            
            self.playerScores[index].pointsList.remove(at: round)
            
            // Adjust roundNbr for all points
            // (Decrease round for those after)
            for point in self.playerScores[index].pointsList {
                if point.round > round {
                    let pointIndex = self.playerScores[index].indexFor(round: point.round)!
                    self.playerScores[index].pointsList[pointIndex].round -= 1
                }
            }
        }
        
        self.maxNbrOfRounds = self.currentMaxNumberOfRounds()
        self.recordHistory()
    }
    
    func modifyPointsFor(player : Player, round : Int, points : Int) {
        for index in self.teamIndices(of: self.indexOf(player: player)!)
            where self.playerScores[index].indexFor(round: round) != nil {
            self.playerScores[index].modifyScore(newScore: points, forRound: round)
        }
        self.recordHistory()
    }
    
    func findScore(playerScore: PlayerScore) -> PlayerScore {
        return playerScores[playerScores.firstIndex(where: {$0.id == playerScore.id})!]
    }
    
    // No players and no game, as when the app starts : the game played stays in the history
    func resetAll() {
        self.recordID = nil
        self.playerScores = []
        self.maxNbrOfRounds = 0
        self.rules = nil
        self.saveSnapshot()
    }

    // keepingGame : a new game of the same game, otherwise the players are asked which game they play
    func resetScores (keepingGame : Bool) {
        // The game ends : its history entry stays as it is
        self.recordID = nil

        for (index, _) in playerScores.enumerated() {
            playerScores[index].resetScore()
        }

        self.maxNbrOfRounds = 0
        if !keepingGame {
            self.rules = nil
        }
        
        self.saveSnapshot()
    }
    
    //    func maxScore() -> Int {
    //        var maxScore = Int (0)
    //        for score in self.playerScores {
    //            if maxScore < score.totalScore()  {
    //                maxScore = score.totalScore()
    //            }
    //        }
    //        return maxScore
    //    }
    
    func currentMaxNumberOfRounds() -> Int {
        var maxNbrRounds = 0
        for score in self.playerScores {
            if score.pointsList.count > maxNbrRounds  {
                maxNbrRounds = score.pointsList.count
            }
        }
        return maxNbrRounds
    }
    
    
    
    
    //    func ranking(for playerScore:PlayerScore) -> Int {
    //
    //        var ranking = 1
    //
    //        let playerScore = self.findScore(playerScore: playerScore).totalScore()
    //
    //        for score in self.playerScores {
    //            if score.totalScore() > playerScore {
    //                ranking += 1
    //            }
    //        }
    //        return ranking
    //    }
    
    func addTestPlayers (){
        
        //        self.addPlayer(player: Player(name: "Steph", photoImage: UIImage(named: "steph-test"), gradientIndex: 0))
        //        self.addPlayer(player: Player(name: "Sof", photoImage: UIImage(named: "vertical"), gradientIndex: 1))
        //        self.addPlayer(player: Player(name: "Chloé", photoImage: UIImage(named: "chloe"), gradientIndex: 3))
        //        self.addPlayer(player: Player(name: "Gaby", photoImage: UIImage(named: "gaby"), gradientIndex: 4))
        //
        self.addPlayer(player: Player(name: "Emma", initials: "Em",  gradientIndex: Int.random(in: 1 ..< 5)))
        self.addPlayer(player: Player(name: "Marc", initials: "M",  gradientIndex: Int.random(in: 5 ..< 10)))
        self.addPlayer(player: Player(name: "Mat", initials: "Mt",  gradientIndex: Int.random(in: 10 ..< 15)))
        self.addPlayer(player: Player(name: "Eva", initials: "Ev",  gradientIndex: Int.random(in: 15 ..< 20)))
        self.addPlayer(player: Player(name: "Louis", initials: "Lo",  gradientIndex: Int.random(in: 1 ..< 20)))
        self.addPlayer(player: Player(name: "Zoe", initials: "Z",  gradientIndex: Int.random(in: 1 ..< 20)))
//        self.addPlayer(player: Player(name: "Gabriel", initials: "G",  gradientIndex: Int.random(in: 1 ..< 20)))
//        self.addPlayer(player: Player(name: "Emily", initials: "El",  gradientIndex: Int.random(in: 1 ..< 20)))
//        self.addPlayer(player: Player(name: "Chris", initials: "C",  gradientIndex: Int.random(in: 1 ..< 20)))
//        self.addPlayer(player: Player(name: "Steve", initials: "S",  gradientIndex: Int.random(in: 1 ..< 20)))
        
        //        self.addEmptyPlayer(with: gradiants[Int.random(in: 0 ..< 5)])
        //        self.addEmptyPlayer(with: gradiants[Int.random(in: 5 ..< 10)])
        //        self.addEmptyPlayer(with: gradiants[Int.random(in: 10 ..< 15)])
        //        self.addEmptyPlayer(with: gradiants[Int.random(in: 15 ..< 20)])
        
        self.playerScores[0].addPoints(scoreValue: -1)
        self.playerScores[0].addPoints(scoreValue: -2)
        self.playerScores[0].addPoints(scoreValue: 5)
        self.playerScores[0].addPoints(scoreValue: 7)
        self.playerScores[0].addPoints(scoreValue: 10)
        self.playerScores[0].addPoints(scoreValue: -12)
        self.playerScores[0].addPoints(scoreValue: 8)
        self.playerScores[0].addPoints(scoreValue: 13)
        self.playerScores[0].addPoints(scoreValue: 20)
        self.playerScores[0].addPoints(scoreValue: 12)
        self.playerScores[0].addPoints(scoreValue: 9)
        self.playerScores[0].addPoints(scoreValue: 0)
        self.playerScores[0].addPoints(scoreValue: 3)
        self.playerScores[0].addPoints(scoreValue: -12)
        self.playerScores[0].addPoints(scoreValue: -1)
        self.playerScores[0].addPoints(scoreValue: 5)
//        self.playerScores[0].addPoints(scoreValue: 7)
//        self.playerScores[0].addPoints(scoreValue: 7)
//
//        self.playerScores[1].addPoints(scoreValue: 10)
        self.playerScores[1].addPoints(scoreValue: 11)
//        self.playerScores[1].addPoints(scoreValue: 1)
//        self.playerScores[1].addPoints(scoreValue: 13)
//        self.playerScores[1].addPoints(scoreValue: 0)
//        self.playerScores[1].addPoints(scoreValue: -1)
//        self.playerScores[1].addPoints(scoreValue: -2)
//        self.playerScores[1].addPoints(scoreValue: -5)
//        self.playerScores[1].addPoints(scoreValue: 8)
//        self.playerScores[1].addPoints(scoreValue: 10)
//        self.playerScores[1].addPoints(scoreValue: 10)
//        self.playerScores[1].addPoints(scoreValue: 10)
//        self.playerScores[1].addPoints(scoreValue: 6)
//        self.playerScores[1].addPoints(scoreValue: 7)
//        self.playerScores[1].addPoints(scoreValue: 3)
//        self.playerScores[1].addPoints(scoreValue: 7)
//        self.playerScores[1].addPoints(scoreValue: 7)
//        self.playerScores[1].addPoints(scoreValue: 7)
//
        self.playerScores[2].addPoints(scoreValue: 2)
        self.playerScores[2].addPoints(scoreValue: 20)
//        self.playerScores[2].addPoints(scoreValue: 22)
//        self.playerScores[2].addPoints(scoreValue: 2)
//        self.playerScores[2].addPoints(scoreValue: 2)
//        self.playerScores[2].addPoints(scoreValue: 2)
//        self.playerScores[2].addPoints(scoreValue: 24)
//        self.playerScores[2].addPoints(scoreValue: -2)
//        self.playerScores[2].addPoints(scoreValue: 6)
//        self.playerScores[2].addPoints(scoreValue: 4)
//        self.playerScores[2].addPoints(scoreValue: 4)
//        self.playerScores[2].addPoints(scoreValue: 4)
//        self.playerScores[2].addPoints(scoreValue: 2)
//        self.playerScores[2].addPoints(scoreValue: -1)
//        self.playerScores[2].addPoints(scoreValue: 12)
//        self.playerScores[2].addPoints(scoreValue: 22)
//        self.playerScores[2].addPoints(scoreValue: 32)
//        self.playerScores[2].addPoints(scoreValue: 2)
//
        self.playerScores[3].addPoints(scoreValue: 1)
        self.playerScores[3].addPoints(scoreValue: 2)
        self.playerScores[3].addPoints(scoreValue: 3)
//        self.playerScores[3].addPoints(scoreValue: 4)
//        self.playerScores[3].addPoints(scoreValue: -4)
//        self.playerScores[3].addPoints(scoreValue: 32)
//        self.playerScores[3].addPoints(scoreValue: 103)
//        self.playerScores[3].addPoints(scoreValue: 3)
//        self.playerScores[3].addPoints(scoreValue: 2)
//        self.playerScores[3].addPoints(scoreValue: -30)
//        self.playerScores[3].addPoints(scoreValue: 4)
//        self.playerScores[3].addPoints(scoreValue: 22)
//        self.playerScores[3].addPoints(scoreValue: 0)
//        self.playerScores[3].addPoints(scoreValue: 0)
//        self.playerScores[3].addPoints(scoreValue: 13)
//        self.playerScores[3].addPoints(scoreValue: 53)
//        self.playerScores[3].addPoints(scoreValue: -43)
//        self.playerScores[3].addPoints(scoreValue: 3)
        
        self.maxNbrOfRounds = self.currentMaxNumberOfRounds()

    }
    
}

extension Game {
    convenience init(withTestPlayers: Void) {
        self.init()
        self.addTestPlayers()
    }
    
    convenience init(withTestEmptyNamePlayers: Void) {
        self.init()
        self.addPlayer(player: Player(name: Player.defaultName, initials: "",  gradientIndex: 1))
        self.addPlayer(player: Player(name: Player.defaultName, initials: "",  gradientIndex: 2))
        self.addPlayer(player: Player(name: Player.defaultName, initials: "",  gradientIndex: 3))
        self.addPlayer(player: Player(name: Player.defaultName, initials: "",  gradientIndex: 4))
        self.addPlayer(player: Player(name: Player.defaultName, initials: "",  gradientIndex: 5))
        self.addPlayer(player: Player(name: Player.defaultName, initials: "",  gradientIndex: 6))
        self.addPlayer(player: Player(name: Player.defaultName, initials: "",  gradientIndex: 7))

    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}





