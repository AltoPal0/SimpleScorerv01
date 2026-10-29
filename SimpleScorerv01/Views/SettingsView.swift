//
//  SettingsView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/29/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Under the gear of the setup screen : appearance and language of the app
struct SettingsView: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.midnightBlue : Color.offWhite).edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HStack {
                    Text(L("Settings"))
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.gray)
                        .padding()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismiss()
                        }
                }
                .padding([.horizontal, .top])

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        RoundSection(title: L("Appearance")) {
                            ChoiceChips(items: AppSettings.Appearance.allCases, selection: $settings.appearance, columns: 3) {
                                $0.label
                            }
                        }

                        RoundSection(title: L("Language")) {
                            ChoiceList(items: AppSettings.Language.allCases, selection: $settings.language) {
                                $0.label
                            }
                        }

                        Text(L("Automatic follows the settings of the iPhone."))
                            .font(Font.system(size: 15, weight: .light, design: .rounded))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)

                        // Required by the CC BY license of the icons used
                        RoundSection(title: L("Credits")) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("Dart icon : Lorc, game-icons.net"))
                                Link(L("License CC BY 3.0"), destination: URL(string: "https://creativecommons.org/licenses/by/3.0/")!)
                                Link("game-icons.net", destination: URL(string: "https://game-icons.net")!)
                            }
                            .font(Font.system(size: 15, weight: .light, design: .rounded))
                            .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
            }
        }
        // The settings speak the language chosen at once
        .environment(\.locale, settings.locale)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
