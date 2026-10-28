//
//  ShareCardView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// The image of a game shared on WhatsApp & co : the look of the app, signed Score 2000
struct ShareCardView: View {

    var record : GameRecord

    static let width = CGFloat(360)
    static let rowHeight = CGFloat(56)

    var body: some View {
        let ranking = record.ranking

        VStack(spacing: 0) {
            // Header like the game header of the app
            VStack(alignment: .leading, spacing: 2) {
                Text(record.gameName)
                    .font(Font.system(size: 34, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                // Full date : "today" means nothing to the friend opening the image tomorrow
                Text(record.date.formatted(.dateTime.day().month(.wide).year()))
                    .font(Font.system(size: 15, weight: .light, design: .rounded))
            }
            .foregroundColor(.offWhite)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(ShareCardView.appGradient)

            // A mini score card per player, best first
            VStack(spacing: 10) {
                ForEach(Array(ranking.enumerated()), id: \.offset) { index, player in
                    HStack(spacing: 12) {
                        RecordAvatar(player: player)
                            .frame(width: 40, height: 40)
                        Text(player.name)
                            .font(Font.system(size: 22, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        if index == 0 && ranking.count > 1 {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                        }
                        Spacer()
                        Text("\(player.total)")
                            .font(Font.system(size: 28, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .foregroundColor(.offWhite)
                    .padding(.horizontal, 10)
                    .frame(height: ShareCardView.rowHeight)
                    .background(Player.gradient(at: player.gradientIndex))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.offWhite, lineWidth: 1)
                    )
                }
            }
            .padding(20)

            // Signature : where the app comes from
            VStack(spacing: 2) {
                Text(AppConfig.appName)
                    .font(Font.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(ShareCardView.appGradient)
                Text("Free on the App Store")
                    .font(Font.system(size: 12, weight: .light, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
        }
        .frame(width: ShareCardView.width)
        .background(Color.offWhite)
        .environment(\.colorScheme, .light)
    }

    static let appGradient = LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange, Color.purple]), startPoint: UnitPoint(x: 0, y: 0.2), endPoint: UnitPoint(x: 1, y: 0.8))

    // The text going with the image, with the link to the app
    static func message(for record: GameRecord) -> String {
        var message = record.gameName
        if let winner = record.ranking.first, record.players.count > 1 {
            message += " · \(winner.name) wins with \(winner.total) points!"
        }
        return message + "\nScored with \(AppConfig.appName) \(AppConfig.appStoreURL.absoluteString)"
    }

    @MainActor
    static func image(for record: GameRecord) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(record: record))
        renderer.scale = 3
        return renderer.uiImage
    }
}

enum ShareSheet {

    // Share sheet of iOS over whatever is on screen
    @MainActor
    static func share(record: GameRecord) {
        guard let image = ShareCardView.image(for: record),
              let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              var top = scene.keyWindow?.rootViewController
        else { return }

        while let presented = top.presentedViewController {
            top = presented
        }

        let controller = UIActivityViewController(activityItems: [image, ShareCardView.message(for: record)], applicationActivities: nil)
        // iPad : a popover needs an anchor
        controller.popoverPresentationController?.sourceView = top.view
        controller.popoverPresentationController?.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
        controller.popoverPresentationController?.permittedArrowDirections = []
        top.present(controller, animated: true)
    }
}
