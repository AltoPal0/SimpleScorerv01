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

// The names and the totals of all the cards share two font sizes, set by the longest name and the widest total.
// The total stays a bit bigger than the name. When the names no longer fit, the cards keep only the avatar
struct CardNames: Equatable {

    static let maximumSize = CGFloat(40)
    // Below this size the names are left out
    static let minimumSize = CGFloat(24)
    static let maximumScoreSize = CGFloat(50)
    // Total compared to the name : bigger, but close
    static let scoreRatio = CGFloat(1.25)
    // Between the name and the total
    static let gap = CGFloat(8)

    var fontSize = CardNames.maximumSize
    var scoreSize = CardNames.maximumScoreSize
    var showsNames = true

    static func font(size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let rounded = font.fontDescriptor.withDesign(.rounded) else { return font }
        return UIFont(descriptor: rounded, size: size)
    }

    static func width(of text: String, size: CGFloat, weight: UIFont.Weight = .semibold) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font(size: size, weight: weight)]).width)
    }

    // availableWidth : what the name and the total share, the avatar and the paddings already taken off
    static func compute(names: [String], totals: [String], availableWidth: CGFloat, scale: CGFloat) -> CardNames {
        let maximum = maximumSize * scale
        let minimum = minimumSize * scale
        let maximumScore = maximumScoreSize * scale
        guard availableWidth > 0 else { return CardNames(fontSize: maximum, scoreSize: maximumScore) }

        // Widths for a 1 pt font : the sizes are proportional
        let longest = names.map { width(of: $0, size: 100) / 100 }.max() ?? 0
        let widest = totals.map { width(of: $0, size: 100, weight: .bold) / 100 }.max() ?? 0
        let room = availableWidth - gap * scale

        // Name and total side by side, the total scoreRatio times bigger
        let size = min(maximum, maximumScore / scoreRatio, room / (longest + scoreRatio * widest))
        if longest == 0 || size >= minimum {
            return CardNames(fontSize: size, scoreSize: size * scoreRatio)
        }
        // Too long : only the avatar, the total takes the room of the name
        let scoreSize = widest > 0 ? min(maximumScore, availableWidth / widest) : maximumScore
        return CardNames(fontSize: minimum, scoreSize: scoreSize, showsNames: false)
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
