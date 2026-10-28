//
//  CardLayout.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import UIKit

// How the score cards fill the screen : bigger cards on iPad, same proportions as on iPhone
struct CardLayout: Equatable {

    // Card of an iPhone : below this width the scale stays 1
    static let baseWidth = CGFloat(380)
    static let minimumWidth = CGFloat(300)
    static let maximumScale = CGFloat(2)
    static let spacing = CGFloat(20)

    var columns = 1
    var cardWidth = CGFloat(380)
    var scale = CGFloat(1)

    // Largest cards showing every player without scrolling. Too many players : iPhone size, and scrolling
    static func compute(width: CGFloat, height: CGFloat, players: Int, baseCardHeight: CGFloat) -> CardLayout {
        guard width > 0, height > 0, players > 0 else { return CardLayout() }
        
        var best : (layout: CardLayout, fittingScale: CGFloat)?
        for columns in 1...players {
            let available = (width - spacing * CGFloat(columns + 1)) / CGFloat(columns)
            if columns > 1 && available < minimumWidth { break }
            
            let rows = CGFloat((players + columns - 1) / columns)
            let widthScale = available / baseWidth
            let heightScale = ((height - spacing) / rows - spacing) / baseCardHeight
            let fittingScale = min(widthScale, heightScale, maximumScale)
            
            let scale = max(1, fittingScale)
            // Full column width unless the height or the maximum scale keeps the card smaller
            let cardWidth = scale >= widthScale ? available : baseWidth * scale
            
            if best == nil || fittingScale > best!.fittingScale {
                best = (CardLayout(columns: columns, cardWidth: max(0, cardWidth), scale: scale), fittingScale)
            }
        }
        return best?.layout ?? CardLayout()
    }
}

// The names of all the cards share one font size, set by the longest name
struct CardNames: Equatable {

    static let maximumSize = CGFloat(40)
    // Below this size the longest names are cut and end with a "."
    static let minimumSize = CGFloat(24)

    var fontSize = CardNames.maximumSize
    var names = [UUID : String]()

    static func font(size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let rounded = font.fontDescriptor.withDesign(.rounded) else { return font }
        return UIFont(descriptor: rounded, size: size)
    }

    static func width(of text: String, size: CGFloat, weight: UIFont.Weight = .semibold) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font(size: size, weight: weight)]).width)
    }

    static func compute(players: [Player], availableWidth: CGFloat, scale: CGFloat) -> CardNames {
        let maximum = maximumSize * scale
        let minimum = minimumSize * scale
        guard availableWidth > 0 else { return CardNames(fontSize: maximum) }

        // Width of the longest name for a 1 pt font : the size is proportional
        let longest = players.map { width(of: $0.name, size: 100) / 100 }.max() ?? 0
        let size = longest > 0 ? min(maximum, max(minimum, availableWidth / longest)) : maximum

        var names = [UUID : String]()
        for player in players {
            names[player.id] = shortened(player.name, size: size, width: availableWidth)
        }
        return CardNames(fontSize: size, names: names)
    }

    // The name as it fits, cut with a "." when it is too long
    static func shortened(_ name: String, size: CGFloat, width: CGFloat) -> String {
        guard self.width(of: name, size: size) > width else { return name }
        var length = name.count - 1
        while length > 1 && self.width(of: String(name.prefix(length)) + ".", size: size) > width {
            length -= 1
        }
        return String(name.prefix(length)) + "."
    }
}

private struct CardScaleKey: EnvironmentKey {
    static let defaultValue = CGFloat(1)
}

private struct CardNamesKey: EnvironmentKey {
    static let defaultValue = CardNames()
}

extension EnvironmentValues {
    var cardScale: CGFloat {
        get { self[CardScaleKey.self] }
        set { self[CardScaleKey.self] = newValue }
    }

    var cardNames: CardNames {
        get { self[CardNamesKey.self] }
        set { self[CardNamesKey.self] = newValue }
    }
}
