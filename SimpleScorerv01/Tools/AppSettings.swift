//
//  AppSettings.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/29/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Options of the whole app, under the gear of the setup screen : appearance and language
class AppSettings: ObservableObject {

    static let shared = AppSettings()

    // The names of iOS : Automatic follows the iPhone
    enum Appearance: String, CaseIterable {
        case automatic, light, dark

        var label: String {
            switch self {
            case .automatic: return L("Automatic")
            case .light: return L("Light")
            case .dark: return L("Dark")
            }
        }

        var interfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .automatic: return .unspecified
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    // Languages of the app, Automatic picks the one of the iPhone when the app has it, English otherwise
    enum Language: String, CaseIterable {
        case automatic, french = "fr", english = "en"

        // Each language in its own name, as in the settings of iOS
        var label: String {
            switch self {
            case .automatic: return L("Automatic")
            case .french: return "Français"
            case .english: return "English"
            }
        }

        // Code of the .lproj folder holding the texts
        var code: String {
            switch self {
            case .automatic:
                let available = Language.allCases.filter { $0 != .automatic }.map { $0.rawValue }
                return Bundle.preferredLocalizations(from: available).first ?? Language.english.rawValue
            default:
                return rawValue
            }
        }
    }

    static let appearanceKey = "appAppearance"
    static let languageKey = "appLanguage"

    @Published var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: AppSettings.appearanceKey)
        }
    }

    // The texts change at once in the settings, the screens behind them when the settings close
    @Published var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: AppSettings.languageKey)
            bundle = AppSettings.bundle(for: language)
            // From the next launch, the texts of iOS in the app (keyboard, share sheet) follow as well
            if language == .automatic {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
            }
        }
    }

    // Language of the screens behind the settings : changing it rebuilds them
    @Published private(set) var appliedLanguage: Language

    // Texts of the language chosen
    private(set) var bundle: Bundle

    var locale: Locale {
        Locale(identifier: language.code)
    }

    init() {
        let defaults = UserDefaults.standard
        let language = Language(rawValue: defaults.string(forKey: AppSettings.languageKey) ?? "") ?? .automatic
        self.appearance = Appearance(rawValue: defaults.string(forKey: AppSettings.appearanceKey) ?? "") ?? .automatic
        self.language = language
        self.appliedLanguage = language
        self.bundle = AppSettings.bundle(for: language)
    }

    func applyLanguage() {
        if appliedLanguage != language {
            appliedLanguage = language
        }
    }

    static func bundle(for language: Language) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }
}

// Text in the language of the app : the English text is the key of Localizable.strings
func L(_ key: String) -> String {
    AppSettings.shared.bundle.localizedString(forKey: key, value: key, table: nil)
}

// Same with values : %@ for a text, %ld for a number
func L(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: L(key), locale: AppSettings.shared.locale, arguments: arguments)
}
