//
//  SceneDelegate.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 3/16/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import UIKit
import SwiftUI
import SwiftData
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    // Saved when the app leaves the screen : names and players change outside the scores
    var game: Game?
    // Appearance chosen in the settings, applied to the whole window (sheets and alerts included)
    var appearanceObserver: AnyCancellable?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let displayInfo = GlobalDisplayInfo()
//        let game = Game(withTestPlayers: ())
        // The interrupted game starts again where it was
        var game = Game.restored()
        if !game.playerScores.isEmpty {
            // Colors already taken leave the palette of the new players
            let taken = Set(game.playerScores.compactMap { $0.player.gradientIndex })
            displayInfo.gradientIndices.removeAll { taken.contains($0) }
            displayInfo.setSizeAndScroll(nbrPlayers: game.playerScores.count)
            displayInfo.screenDisplayed = game.rules == nil ? .gameSetup : .scoreCards
        }
        #if DEBUG
        // Launch with -demoPlayers to skip the setup and land on the scores with test players,
        // -demoCount <n> to keep n of them, -demoGame <name> to pick the game and -demoRound to open the round entry
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-demoPlayers") {
            game = Game(withTestPlayers: ())
            displayInfo.screenDisplayed = .scoreCards
        }
        if let index = arguments.firstIndex(of: "-demoCount"), arguments.indices.contains(index + 1),
           let count = Int(arguments[index + 1]) {
            game.playerScores = Array(game.playerScores.prefix(count))
        }
        if let index = arguments.firstIndex(of: "-demoGame"), arguments.indices.contains(index + 1) {
            let rules = GameLibrary.rules(named: arguments[index + 1])
            game.rules = rules
            game.options = GameOptions.load(for: rules)
            if arguments.contains("-demoRound") {
                displayInfo.roundEntryPlayerID = game.playerScores.first?.player.id
            }
        }
        // -demoShort keeps 3 rounds per player
        if arguments.contains("-demoShort") {
            for index in game.playerScores.indices {
                game.playerScores[index].pointsList = Array(game.playerScores[index].pointsList.prefix(3))
            }
            game.maxNbrOfRounds = game.currentMaxNumberOfRounds()
        }
        // -demoReset resets the scores 8 seconds after launch, as the Reset scores button
        if arguments.contains("-demoReset") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [game] in
                game.resetScores(keepingGame: true)
            }
        }
        // -demoResetAll resets everything 8 seconds after launch, as the Reset all button
        if arguments.contains("-demoResetAll") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [game, displayInfo] in
                game.resetAll()
                displayInfo.gradientIndices = Array(gradiants.indices).shuffled()
                displayInfo.setSizeAndScroll(nbrPlayers: 0)
            }
        }
        // -demoColumns opens the columns of scores
        if arguments.contains("-demoColumns") {
            displayInfo.screenDisplayed = .allScores
        }
        // -demoHistory adds sample games to the history and opens it
        if arguments.contains("-demoHistory") {
            let store = HistoryStore.shared
            store.save(id: UUID(), gameName: "Tarot", gameID: "tarot", date: Date().addingTimeInterval(-3600), lowestScoreWins: false, players: [
                RecordedPlayer(name: "Emma", initials: "Em", gradientIndex: 2, points: [], total: 312),
                RecordedPlayer(name: "Marc", initials: "M", gradientIndex: 9, points: [], total: -104),
                RecordedPlayer(name: "Mat", initials: "Mt", gradientIndex: 12, points: [], total: -58),
                RecordedPlayer(name: "Eva", initials: "Ev", gradientIndex: 17, points: [], total: -150)])
            store.save(id: UUID(), gameName: "Mölkky", gameID: "molkky", date: Date().addingTimeInterval(-86400 - 7200), lowestScoreWins: false, players: [
                RecordedPlayer(name: "Louis", initials: "Lo", gradientIndex: 4, points: [], total: 50),
                RecordedPlayer(name: "Zoe", initials: "Z", gradientIndex: 14, points: [], total: 37)])
            store.save(id: UUID(), gameName: "Skyjo", gameID: "custom.skyjo", date: Date().addingTimeInterval(-86400 * 9), lowestScoreWins: false, players: [
                RecordedPlayer(name: "Emma", initials: "Em", gradientIndex: 2, points: [], total: 41),
                RecordedPlayer(name: "Marc", initials: "M", gradientIndex: 9, points: [], total: 102),
                RecordedPlayer(name: "Eva", initials: "Ev", gradientIndex: 17, points: [], total: 77)])
            displayInfo.screenDisplayed = .history
            // -demoShareImage writes the shared image of the last game in the temporary folder
            if arguments.contains("-demoShareImage"),
               let record = try? store.container.mainContext.fetch(FetchDescriptor<GameRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])).first,
               let data = ShareCardView.image(for: record)?.pngData() {
                try? data.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("share.png"))
                print(ShareCardView.message(for: record))
            }
        }
        // -demoRecord scores a point through the real game, which saves it in the history
        if arguments.contains("-demoRecord"), let player = game.playerScores.first?.player {
            game.addPointsFor(player: player, points: 7)
            displayInfo.screenDisplayed = .history
        }
        #endif
        self.game = game
        let contentView = RootView()
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(
                rootView: contentView
                    .environmentObject(displayInfo)
                    .environmentObject(game)
                    .modelContainer(HistoryStore.shared.container))
            self.window = window
            appearanceObserver = AppSettings.shared.$appearance.sink { [weak window] appearance in
                window?.overrideUserInterfaceStyle = appearance.interfaceStyle
            }
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        game?.saveSnapshot()
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

// Rebuilt when the language changes : every text of the app follows
struct RootView: View {

    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        GameScoreView()
            .id(settings.appliedLanguage)
            .environment(\.locale, Locale(identifier: settings.appliedLanguage.code))
    }
}
