//
//  GameRequests.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import UIKit
import UserNotifications

// Games asked by the players to be added to the library, sent to the backend
// with the device token so that the player is notified once the game is in
struct GameRequest: Codable, Equatable {
    var game: String
    var locale: String
    var date: Date
}

enum GameRequests {

    static let pendingKey = "pendingGameRequests"
    static let requestedKey = "requestedGames"
    static let tokenKey = "pushDeviceToken"

    // MARK: - What was already asked

    static func wasRequested(_ game: String) -> Bool {
        let requested = UserDefaults.standard.stringArray(forKey: requestedKey) ?? []
        return requested.contains(GameRules.normalized(game))
    }

    // Only games typed by the players, never the library or an empty name
    static func shouldOffer(_ rules: GameRules) -> Bool {
        !rules.isInLibrary && !rules.name.isEmpty && !wasRequested(rules.name)
    }

    // MARK: - Asking for a game

    // Asked once per game, whatever the answer
    static func markOffered(_ game: String) {
        var requested = UserDefaults.standard.stringArray(forKey: requestedKey) ?? []
        requested.append(GameRules.normalized(game))
        UserDefaults.standard.set(requested, forKey: requestedKey)
    }
    
    // Asks for the notifications, then sends the request (kept for later when offline)
    @MainActor
    static func request(game: String) async {
        markOffered(game)

        var pending = loadPending()
        pending.append(GameRequest(game: game, locale: Locale.current.identifier, date: Date()))
        savePending(pending)

        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted {
            // The token comes back in the AppDelegate, which sends the pending requests
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            await sendPending()
        }
    }

    // MARK: - Device token

    static var deviceToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    static func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: tokenKey)
        Task {
            await sendPending()
        }
    }

    // MARK: - Backend

    static func loadPending() -> [GameRequest] {
        guard let data = UserDefaults.standard.data(forKey: pendingKey),
              let requests = try? JSONDecoder().decode([GameRequest].self, from: data)
        else {
            return []
        }
        return requests
    }

    static func savePending(_ requests: [GameRequest]) {
        if let data = try? JSONEncoder().encode(requests) {
            UserDefaults.standard.set(data, forKey: pendingKey)
        }
    }

    // Sends what is waiting, keeps what failed for the next launch
    static func sendPending() async {
        guard let backend = AppConfig.backendURL else { return }

        var failed = [GameRequest]()
        for request in loadPending() {
            var urlRequest = URLRequest(url: backend.appendingPathComponent("requests"))
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: [
                "game": request.game,
                "locale": request.locale,
                "deviceToken": deviceToken ?? "",
                "apnsEnvironment": AppConfig.apnsEnvironment,
                "bundleId": Bundle.main.bundleIdentifier ?? "",
            ])

            let response = try? await URLSession.shared.data(for: urlRequest)
            if (response?.1 as? HTTPURLResponse)?.statusCode != 200 {
                failed.append(request)
            }
        }
        savePending(failed)
    }
}
