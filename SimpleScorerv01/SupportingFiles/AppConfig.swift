//
//  AppConfig.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import Foundation

// Links and services of the app, in one place
enum AppConfig {

    static let appName = "Score 2000"

    // Added to every shared score : this is how the app spreads
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id1668978877")!

    // Web service receiving the game requests and sending the notifications (Cloud Run on SG2, see backend/).
    // When it can't be reached, the requests wait on the device and leave on the next launch
    static let backendURL: URL? = URL(string: "https://score2000-417137053734.europe-west9.run.app")

    // Debug builds receive their notifications from the APNs sandbox
    #if DEBUG
    static let apnsEnvironment = "sandbox"
    #else
    static let apnsEnvironment = "production"
    #endif
}
