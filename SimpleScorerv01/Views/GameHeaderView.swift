//
//  GameHeaderView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Top of the scores screens : the game played and its options, discreet like the arrows at the bottom
struct GameHeaderView: View {

    @EnvironmentObject var game : Game
    @State private var showOptions = false

    static let height = CGFloat(56)

    var body: some View {
        HStack {
            Text(game.rules?.displayName ?? "")
                .font(Font.system(size: 30, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.gray)

            Spacer()

            if game.rules?.isInLibrary == true {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showOptions = true
                    }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: GameHeaderView.height)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
        }
        .sheet(isPresented: $showOptions) {
            GameOptionsView()
                .environmentObject(game)
        }
    }
}

struct GameOptionsView: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var game : Game

    var targetSelection : Binding<Int> {
        Binding(
            get: { game.target ?? 0 },
            set: { game.options.target = $0 })
    }

    // How the app counts, in one sentence, so the players know which variant is played
    var rulesSummary : String {
        switch game.activeKind {
        case .molkky:
            return "Exactly 50 to win. Going over 50 sends you back to 25."
        case .coinche:
            let options = game.options
            var rules = options.coincheScoring == .announced
                ? "A contract made scores the contract announced, × 2 when coinchée, × 4 when surcoinchée. A contract down gives 160 to the other team, 250 for a capot, × 2 or × 4 as well."
                : "A contract made scores the contract plus the card points rounded to the ten. Coinchée made : 160 + contract × 2 or × 4. A contract down gives 160 + contract to the other team."
            rules += options.coincheDefenseScores ? " The defense scores its card points." : " Only the taking team scores."
            rules += options.coincheBelote ? " Belote +20 to its holder." : " Belote is not counted."
            return rules + " With 4 players, 1st & 3rd play against 2nd & 4th."
        case .tarot:
            let petit = game.options.tarotPetitDefense ? "Petit au bout ±10 × contract, for the attack or the defense" : "Petit au bout +10 × contract, for the attack only"
            return "French federation scoring : 25 + difference, times the contract (×1, ×2, ×4, ×6). \(petit). Poignée 20 / 30 / 40 to the winning side. Chelem not counted."
        case .scrabble:
            return "Enter the points of each word. The +50 key adds the bonus for playing all 7 tiles."
        case .uno:
            return game.options.unoLowestWins
                ? "Each player scores the cards left in his hand. The game ends at the target, the lowest score wins."
                : "Official rules : the player out of cards scores the cards left in the other hands (numbers face value, action cards 20, wild cards 50)."
        case .petanque:
            return "Each mène, the winning player or team scores 1 to 6 points."
        case .universal:
            if let rules = game.rules, rules.isInLibrary {
                return "\(rules.name) needs \(rules.playerCountHint) : scores are entered freely."
            }
            return ""
        }
    }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.midnightBlue : Color.offWhite).edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HStack {
                    Text(game.rules?.displayName ?? "")
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

                        if !GameOptions.targets(for: game.activeKind).isEmpty {
                            RoundSection(title: "Game ends at") {
                                ChoiceChips(items: GameOptions.targets(for: game.activeKind), selection: targetSelection) { "\($0)" }
                            }
                        }

                        if game.activeKind == .molkky {
                            RoundSection(title: "3 misses in a row") {
                                ChoiceChips(items: [true, false], selection: $game.options.molkkyMissesOut) { $0 ? "Out" : "Keep playing" }
                            }
                        }

                        if game.activeKind == .coinche {
                            RoundSection(title: "Scoring") {
                                ChoiceList(items: [CoincheDeal.Scoring.announced, .pointsMade], selection: $game.options.coincheScoring) {
                                    $0 == .announced ? "Contract announced" : "Contract + card points"
                                }
                            }
                            RoundSection(title: "Defense card points") {
                                ChoiceChips(items: [false, true], selection: $game.options.coincheDefenseScores, minimumWidth: 150) { $0 ? "Counted" : "Not counted" }
                            }
                            RoundSection(title: "Belote · Rebelote +20") {
                                ChoiceChips(items: [false, true], selection: $game.options.coincheBelote, minimumWidth: 150) { $0 ? "Counted" : "Not counted" }
                            }
                        }
                        
                        if game.activeKind == .tarot {
                            RoundSection(title: "Petit au bout by the defense") {
                                ChoiceChips(items: [false, true], selection: $game.options.tarotPetitDefense, minimumWidth: 150) { $0 ? "Counted" : "Not counted" }
                            }
                        }
                        
                        if game.activeKind == .uno {
                            RoundSection(title: "Scoring") {
                                ChoiceList(items: [false, true], selection: $game.options.unoLowestWins) {
                                    $0 ? "Everyone scores his hand · lowest wins" : "Winner scores the hands · official"
                                }
                            }
                        }

                        RoundSection(title: "Rules") {
                            Text(rulesSummary)
                                .font(Font.system(size: 17, weight: .light, design: .rounded))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct GameHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let game = Game(withTestPlayers: ())
        game.rules = GameLibrary.rules(named: "Coinche")
        return VStack {
            GameHeaderView()
            Spacer()
        }
        .environmentObject(game)
    }
}
