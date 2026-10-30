//
//  SettingsView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/29/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Under the gear of the setup screen : appearance and language of the app, and the games streamed nearby
struct SettingsView: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings = AppSettings.shared
    @State private var watchesLive = false

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

                        // An iPad next to the iPhone keeping the scores : the same game on a larger screen
                        RoundSection(title: L("Live game")) {
                            ChoiceChip(label: L("Watch a game nearby"), isSelected: false, fullWidth: true) {
                                watchesLive = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        // The settings speak the language chosen at once
        .environment(\.locale, settings.locale)
        .fullScreenCover(isPresented: $watchesLive) {
            LiveViewerView()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
