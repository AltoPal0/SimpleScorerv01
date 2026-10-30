//
//  LiveViewerView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/30/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// The device watching a game streamed nearby : the scores as on the iPhone keeping them,
// the columns of every round next to the cards when the screen is large enough (iPad)
struct LiveViewerView: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var live = LiveShare.shared
    @ObservedObject var game = LiveShare.shared.game
    @StateObject private var displayInfo = LiveViewerView.watchingDisplay()
    // Narrow screens : the cards or the columns
    @State private var showsColumns = false

    static func watchingDisplay() -> GlobalDisplayInfo {
        let displayInfo = GlobalDisplayInfo()
        displayInfo.watchesLive = true
        displayInfo.screenDisplayed = .scoreCards
        return displayInfo
    }

    var showsScores: Bool { live.isConnected && !game.playerScores.isEmpty }

    // Same width as the columns next to the cards on the scores screens
    func columnsWidth() -> CGFloat {
        CGFloat(game.playerScores.count) * 72 + 48
    }

    // A screen just for watching : the columns get their room sooner than on the scores screens
    func isDual(width: CGFloat) -> Bool {
        width >= 700 && columnsWidth() <= width * 0.5
    }

    var title: String {
        if showsScores, let name = game.rules?.displayName, !name.isEmpty {
            return name
        }
        return L("Live game")
    }

    var status: String {
        guard let followed = live.followed else { return L("Looking for games nearby…") }
        return live.isConnected ? L("Live from %@", followed.deviceName) : L("Joining %@…", followed.deviceName)
    }

    var body: some View {
        GeometryReader { geometry in
            let dual = isDual(width: geometry.size.width)
            ZStack {
                (colorScheme == .dark ? Color.midnightBlue : Color.offWhite).edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    header(dual: dual)

                    if showsScores {
                        if dual {
                            HStack(spacing: 0) {
                                AllScoresView_new()
                                    .frame(width: columnsWidth())
                                ScoreCardsGridView()
                            }
                        } else if showsColumns {
                            AllScoresView_new()
                        } else {
                            ScoreCardsGridView()
                        }
                    } else {
                        streamsList
                    }
                }
            }
            .onAppear { displayInfo.isDualLayout = dual }
            .onChange(of: dual) { displayInfo.isDualLayout = dual }
        }
        .environmentObject(game)
        .environmentObject(displayInfo)
        .onAppear { live.startWatching() }
        .onDisappear { live.stop() }
        // Size of the cards for the number of players
        .onChange(of: game.playerScores.count) { _, count in
            guard count > 0 else { return }
            displayInfo.setSizeAndScroll(nbrPlayers: count)
        }
    }

    func header(dual: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Label(status, systemImage: "dot.radiowaves.left.and.right")
                    .font(Font.system(size: 15, weight: .light, design: .rounded))
                    .foregroundColor(live.isConnected ? .green : .gray)
                    .lineLimit(1)
            }

            Spacer()

            if showsScores {
                // Order of the cards, as with the bar of the game
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

                if !dual {
                    Image(systemName: showsColumns ? "rectangle.grid.1x2" : "tablecells")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                showsColumns.toggle()
                            }
                        }
                }
            }

            // Another game streamed nearby
            if live.followed != nil {
                Image(systemName: "list.bullet")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        live.unfollow()
                    }
            }

            Image(systemName: "xmark")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.gray)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    var streamsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if live.followed != nil {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if live.streams.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                    Text(L("On the iPhone keeping the scores, tap the gear next to the name of the game, then the waves next to its name. Both devices need %@ open and Wi-Fi or Bluetooth on.", AppConfig.appName))
                        .font(Font.system(size: 17, weight: .light, design: .rounded))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    RoundSection(title: L("Games streamed nearby")) {
                        VStack(spacing: 8) {
                            ForEach(live.streams) { stream in
                                ChoiceChip(label: stream.label, isSelected: false, fullWidth: true) {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    live.follow(stream)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct LiveViewerView_Previews: PreviewProvider {
    static var previews: some View {
        LiveViewerView()
    }
}
