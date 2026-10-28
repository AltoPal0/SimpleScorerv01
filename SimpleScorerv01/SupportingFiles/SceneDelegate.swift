//
//  SceneDelegate.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 3/16/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let displayInfo = GlobalDisplayInfo()
//        let game = Game(withTestPlayers: ())
        var game = Game()
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
        #endif
        let contentView = GameScoreView()
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(
                rootView: contentView
                    .environmentObject(displayInfo)
                    .environmentObject(game))
            self.window = window
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
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

