//
//  HistoryView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import SwiftData

// 4th screen, right of the game setup : the last games played
struct HistoryView: View {

    @Query(sort: \GameRecord.date, order: .reverse) var records: [GameRecord]

    var gridItemLayout = [GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 20)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HISTORY")
                .font(Font.system(size: 15, weight: .light, design: .rounded))
                .foregroundColor(.gray)
                .padding([.horizontal, .top], 20)

            if records.isEmpty {
                Spacer()
                Text("Your games will show up here")
                    .font(Font.system(size: 20, weight: .light, design: .rounded))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: gridItemLayout, spacing: 20) {
                        ForEach(records) { record in
                            GameRecordCard(record: record)
                        }
                    }
                    .padding(20)
                    // Room for the bottom arrows
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

struct GameRecordCard: View {

    @Environment(\.colorScheme) var colorScheme
    var record : GameRecord

    var body: some View {
        let ranking = record.ranking

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.gameName)
                    .font(Font.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(GameRecordCard.dateText(record.date))
                    .font(Font.system(size: 15, weight: .light, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            // Players ranked, the winner first with the crown
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(ranking.enumerated()), id: \.offset) { index, player in
                        VStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: 0xf5af19))
                                .opacity(index == 0 && ranking.count > 1 ? 1 : 0)
                            RecordAvatar(player: player)
                                .frame(width: 48, height: 48)
                            Text("\(player.total)")
                                .font(Font.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(minWidth: 48)
                    }
                }
            }
        }
        .padding(16)
        .background(
            // Shadow on the card only, not on its texts and avatars
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.offWhite, lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    HistoryStore.shared.delete(id: record.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    static func dateText(_ date: Date) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(date) {
            return "Today · \(time)"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday · \(time)"
        }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}

// Same look as the avatars of the players in the game
struct RecordAvatar: View {
    var player : RecordedPlayer

    var body: some View {
        Text(player.initials.isEmpty ? String(player.name.prefix(1)) : player.initials)
            .font(.system(.title2, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Player.gradient(at: player.gradientIndex))
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
    }
}
