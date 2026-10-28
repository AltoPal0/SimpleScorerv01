//
//  TarotRoundView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct TarotRoundView: View {

    @EnvironmentObject var game : Game

    // nil until chosen when the round was opened by New round
    @State var takerID : UUID?
    var onConfirm : ([UUID : Int]) -> Void

    @State private var deal = TarotDeal()
    @State private var pointsEntered = false
    // 5 players : the partner is easily forgotten, the taker alone is confirmed first
    @State private var confirmsPlayingAlone = false
    // 5 players : the called king, the taker when playing alone
    @State private var partnerID : UUID?
    @State private var missesTaker = false
    // Petit au bout, poignée and misères, in a panel over the bottom of the screen
    @State private var showExtras = false
    @State private var misereIDs = Set<UUID>()

    init(takerID: UUID?, onConfirm: @escaping ([UUID : Int]) -> Void) {
        self._takerID = State(initialValue: takerID)
        self._partnerID = State(initialValue: takerID)
        self.onConfirm = onConfirm
    }

    // The avatars show no selection while nobody is chosen
    static let nobody = UUID()
    
    func choice(_ id: Binding<UUID?>) -> Binding<UUID> {
        Binding(get: { id.wrappedValue ?? TarotRoundView.nobody }, set: { id.wrappedValue = $0 })
    }
    
    var takerName : String {
        game.playerScores.first { $0.player.id == takerID }?.player.name ?? ""
    }

    var isFivePlayers : Bool {
        game.playerScores.count == 5
    }

    var points : [UUID : Int] {
        guard let takerID = takerID else { return [:] }
        var deal = deal
        deal.taker = game.indexOf(playerID: takerID) ?? 0
        deal.partner = isFivePlayers ? partnerID.flatMap { game.indexOf(playerID: $0) } : nil
        deal.miseres = misereIDs.compactMap { game.indexOf(playerID: $0) }

        let scores = deal.scores(playerCount: game.playerScores.count)
        var points = [UUID : Int]()
        for (index, playerScore) in game.playerScores.enumerated() {
            points[playerScore.player.id] = scores[index]
        }
        return points
    }

    var pointsCaption : String {
        let difference = deal.points - deal.required
        return "needs \(deal.required) · \(difference >= 0 ? "+" : "")\(difference)"
    }

    // What the extras hold, in a few words
    var extrasSummary : String {
        var extras = [String]()
        switch deal.petitAuBout {
        case .attack: extras.append("Petit au bout attack")
        case .defense: extras.append("Petit au bout defense")
        case .none: break
        }
        switch deal.poignee {
        case 20: extras.append("Simple poignée")
        case 30: extras.append("Double poignée")
        case 40: extras.append("Triple poignée")
        default: break
        }
        let miseres = game.playerScores.filter { misereIDs.contains($0.player.id) }.map { $0.player.name }
        if !miseres.isEmpty {
            extras.append("Misère " + miseres.joined(separator: ", "))
        }
        return extras.isEmpty ? "Petit au bout · Poignée · Misère" : extras.joined(separator: " · ")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundEntryLayout(title: "Tarot") {
                RoundSection(title: "Taker") {
                    PlayerPickRow(players: game.playerScores, selected: choice($takerID))
                }

                if isFivePlayers {
                    RoundSection(title: "Called king") {
                        PlayerPickRow(players: game.playerScores, selected: choice($partnerID))
                    }
                }

                RoundSection(title: "Contract") {
                    ChoiceChips(items: TarotDeal.Contract.allCases, selection: $deal.contract, columns: 4) { $0.shortName }
                }

                RoundSection(title: "Oudlers", inline: true) {
                    ChoiceChips(items: [0, 1, 2, 3], selection: $deal.bouts, columns: 4) { "\($0)" }
                }

                PointsKeypadEntry(text: pointsEntered ? "\(deal.points)" : "",
                                  caption: pointsEntered ? pointsCaption : "Attack needs \(deal.required)",
                                  maximum: 91) { points in
                    deal.points = points
                    pointsEntered = true
                }

                // Extras in one button : the screen stays short
                VStack(spacing: 6) {
                    ChoiceChip(label: "Extras", isSelected: false) {
                        withAnimation(KeypadPanel.spring) {
                            showExtras = true
                        }
                    }
                    Text(extrasSummary)
                        .font(Font.system(size: 13, weight: .light, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } preview: {
                RoundPreview(points: pointsEntered ? points : [:],
                             caption: pointsEntered && takerID != nil ? (deal.isMade ? "Contract made" : "Contract down") : nil)
            } confirm: {
                ConfirmBar(isEnabled: pointsEntered) {
                    if takerID == nil {
                        missesTaker = true
                    } else if isFivePlayers && partnerID == takerID {
                        confirmsPlayingAlone = true
                    } else {
                        onConfirm(points)
                    }
                }
            }

            if showExtras {
                BottomPanel(onDone: {
                    withAnimation(KeypadPanel.spring) {
                        showExtras = false
                    }
                }) {
                    extrasPanel
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .alert("Who took?", isPresented: $missesTaker) {
            Button("OK") {}
        } message: {
            Text("Choose the taker before saving the deal.")
        }
        .alert("\(takerName) plays alone?", isPresented: $confirmsPlayingAlone) {
            Button("Plays alone") {
                onConfirm(points)
            }
            Button("Choose partner", role: .cancel) {}
        } message: {
            Text("No partner was called : \(takerName) is both the taker and the called king.")
        }
        .onChange(of: takerID) {
            partnerID = takerID
        }
    }

    var extrasPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundSection(title: "Petit au bout") {
                ChoiceChips(items: game.options.tarotPetitDefense ? [TarotDeal.Side.none, .attack, .defense] : [TarotDeal.Side.none, .attack],
                            selection: $deal.petitAuBout, columns: game.options.tarotPetitDefense ? 3 : 2) {
                    switch $0 {
                    case .none: return "—"
                    case .attack: return "Attack"
                    case .defense: return "Defense"
                    }
                }
            }

            RoundSection(title: "Poignée") {
                ChoiceChips(items: TarotDeal.poignees, selection: $deal.poignee, columns: 4) {
                    switch $0 {
                    case 20: return "Simple"
                    case 30: return "Double"
                    case 40: return "Triple"
                    default: return "—"
                    }
                }
            }

            RoundSection(title: "Misère · 10 from each player") {
                PlayerMultiPickRow(players: game.playerScores, selected: $misereIDs)
            }
        }
        .padding([.horizontal, .bottom])
    }
}
