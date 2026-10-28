//
//  TeamCardView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Coinche with 4 players, once the first deal is in : partners share one card and one score
struct TeamCardView: View {

    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    @Environment(\.cardScale) var scale

    // The two partners, the first one holds the score of the team
    var team : [PlayerScore]

    static let baseHeight = CGFloat(120)

    var rowHeight: CGFloat { TeamCardView.baseHeight / 2 * scale }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(team.enumerated()), id: \.element.id) { index, playerScore in
                HStack(spacing: 10 * scale) {
                    AvatarView(user: playerScore.player)
                        .padding(6 * scale)
                        .frame(width: rowHeight, height: rowHeight)
                    Text(playerScore.player.name)
                        .font(Font.system(size: 26 * scale, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundColor(.offWhite)
                    Spacer()
                }
                .padding(.leading, 6 * scale)
                .frame(height: rowHeight)
                .background(playerScore.player.colorGradient)
                .overlay(alignment: .bottom) {
                    if index == 0 {
                        Rectangle().fill(Color.offWhite.opacity(0.6)).frame(height: 0.5)
                    }
                }
            }
        }
        // One score for the team, over both lines
        .overlay(alignment: .trailing) {
            if let first = team.first {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(verbatim: "\(game.total(for: first))")
                        .font(Font.system(size: 50 * scale, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                    if game.winner().map({ winner in team.contains(winner) }) == true {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15 * scale))
                    } else if let remaining = game.remaining(for: first) {
                        Text(verbatim: "\(remaining) to go")
                            .font(Font.system(size: 15 * scale, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundColor(.offWhite)
                .padding(.horizontal, 20 * scale)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.offWhite, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if let first = team.first {
                displayInfo.roundEntryPlayerID = first.player.id
            }
        }
    }
}
