//
//  GameHeaderView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Top of the scores screens : the game played and its options, discreet like the arrows at the bottom.
// Above the cards and scrolling with them : out of sight while playing, the cards pulled down show it
struct GameHeaderView: View {

    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
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

            // Order of the cards : table order, highest first, lowest first
            if displayInfo.screenDisplayed == .scoreCards {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        withAnimation {
                            displayInfo.cardOrder = displayInfo.cardOrder.next
                        }
                    }
            }

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
            return L("Exactly 50 to win. Going over 50 sends you back to 25.")
        case .coinche:
            let options = game.options
            var rules = options.coincheScoring == .announced
                ? L("A contract made scores the contract announced, × 2 when coinchée, × 4 when surcoinchée. A contract down gives 160 to the other team, 250 for a capot, × 2 or × 4 as well.")
                : L("A contract made scores the contract plus the card points rounded to the ten. Coinchée made : 160 + contract × 2 or × 4. A contract down gives 160 + contract to the other team.")
            rules += " " + (options.coincheDefenseScores ? L("The defense scores its card points.") : L("Only the taking team scores."))
            rules += " " + (options.coincheBelote ? L("Belote +20 to its holder.") : L("Belote is not counted."))
            return rules + " " + L("With 4 players, 1st & 2nd play against 3rd & 4th.")
        case .tarot:
            let petit = game.options.tarotPetitDefense ? L("Petit au bout ±10 × contract, for the attack or the defense") : L("Petit au bout +10 × contract, for the attack only")
            return L("French federation scoring : 25 + difference, times the contract (×1, ×2, ×4, ×6). %@. Poignée 20 / 30 / 40 to the winning side. Chelem not counted.", petit)
        case .scrabble:
            return L("Enter the points of each word. The +50 key adds the bonus for playing all 7 tiles.")
        case .uno:
            return game.options.unoLowestWins
                ? L("Each player scores the cards left in his hand. The game ends at the target, the lowest score wins.")
                : L("Official rules : the player out of cards scores the cards left in the other hands (numbers face value, action cards 20, wild cards 50).")
        case .petanque:
            return L("Each mène, the winning player or team scores 1 to 6 points.")
        case .gangOfFour:
            return L("The player out of cards ends the round. The others score the cards left : 1 point each up to 7 cards, × 2 from 8, × 3 from 11, × 4 from 14 (16 cards = 64). The game ends at 100, the lowest score wins. The direction of play changes every round.")
        case .cabo:
            return L("Each player scores the total of their hand. Calling Cabo scores 0 with the lowest hand, otherwise the hand + 10 (a tie is not enough). Kamikaze (%@) : 0, and 50 for everyone else. Exactly 100 brings a player back to 50, once. The game ends over 100, the lowest score wins.", game.options.caboKamikazeHand)
        case .darts:
            switch game.rules?.darts {
            case .x501?, .x301?:
                let finish = game.options.dartsDoubleOut
                    ? L("The last dart must be a double : 1 left is a bust as well.")
                    : L("Any dart can finish.")
                return L("Each turn, enter the points of the 3 darts (180 at most) : they are taken off %ld. Going under 0 is a bust, the turn counts nothing. %@ First to exactly 0 wins.", game.rules?.target ?? 501, finish)
            case .cricket?:
                return game.options.cricketCutThroat
                    ? L("Only 15 to 20 and the bull count. 3 marks close a number (double = 2, triple = 3). Once closed, each new hit gives its points to the opponents who haven't closed it. Tap the numbers hit on the board, the points are counted : close everything with the fewest points to win.")
                    : L("Only 15 to 20 and the bull count. 3 marks close a number (double = 2, triple = 3). Once closed, each new hit scores its points for you while an opponent hasn't closed it. Tap the numbers hit on the board, the points are counted : close everything with the most points to win.")
            case .aroundTheClock?:
                return L("Hit 1, then 2… up to 20, then the bull (21). Each turn, the arrows move the player to the number reached. First to the bull wins.")
            case .shanghai?:
                return L("7 rounds : round 1 on the 1, round 2 on the 2… Count the singles, doubles and triples of that number, the points are counted. Hitting all three in one turn is a Shanghai and wins at once. Otherwise the highest score after 7 rounds wins.")
            case nil:
                return ""
            }
        case .universal:
            if let rules = game.rules, rules.isInLibrary {
                return L("%@ needs %@ : scores are entered freely.", rules.displayName, rules.playerCountHint)
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
                            RoundSection(title: L("Game ends at")) {
                                ChoiceChips(items: GameOptions.targets(for: game.activeKind), selection: targetSelection) { "\($0)" }
                            }
                        }

                        if game.activeKind == .molkky {
                            RoundSection(title: L("3 misses in a row")) {
                                ChoiceChips(items: [true, false], selection: $game.options.molkkyMissesOut) { $0 ? L("Out") : L("Keep playing") }
                            }
                        }

                        if game.activeKind == .coinche {
                            RoundSection(title: L("Scoring")) {
                                ChoiceList(items: [CoincheDeal.Scoring.announced, .pointsMade], selection: $game.options.coincheScoring) {
                                    $0 == .announced ? L("Contract announced") : L("Contract + card points")
                                }
                            }
                            RoundSection(title: L("Defense card points")) {
                                ChoiceChips(items: [false, true], selection: $game.options.coincheDefenseScores, minimumWidth: 150) { $0 ? L("Counted") : L("Not counted") }
                            }
                            RoundSection(title: L("Belote · Rebelote +20")) {
                                ChoiceChips(items: [false, true], selection: $game.options.coincheBelote, minimumWidth: 150) { $0 ? L("Counted") : L("Not counted") }
                            }
                        }
                        
                        if game.activeKind == .tarot {
                            RoundSection(title: L("Petit au bout by the defense")) {
                                ChoiceChips(items: [false, true], selection: $game.options.tarotPetitDefense, minimumWidth: 150) { $0 ? L("Counted") : L("Not counted") }
                            }
                        }
                        
                        if game.activeKind == .cabo {
                            RoundSection(title: L("Kamikaze hand")) {
                                ChoiceList(items: [true, false], selection: $game.options.caboKamikazeFourKings) {
                                    $0 ? L("Four kings · 54 cards deck") : L("Two 12 and two 13 · Cabo deck")
                                }
                            }
                        }
                        
                        if game.countsDown {
                            RoundSection(title: L("Finish")) {
                                ChoiceList(items: [true, false], selection: $game.options.dartsDoubleOut) {
                                    $0 ? L("On a double · double out") : L("Any dart · straight out")
                                }
                            }
                        }
                        
                        if game.isCricket {
                            RoundSection(title: L("Points")) {
                                ChoiceList(items: [false, true], selection: $game.options.cricketCutThroat) {
                                    $0 ? L("Given to the opponents · cut-throat, lowest wins") : L("For the player · classic, highest wins")
                                }
                            }
                        }
                        
                        if game.activeKind == .uno {
                            RoundSection(title: L("Scoring")) {
                                ChoiceList(items: [false, true], selection: $game.options.unoLowestWins) {
                                    $0 ? L("Everyone scores his hand · lowest wins") : L("Winner scores the hands · official")
                                }
                            }
                        }

                        RoundSection(title: L("Rules")) {
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
        .environmentObject(GlobalDisplayInfo())
    }
}
