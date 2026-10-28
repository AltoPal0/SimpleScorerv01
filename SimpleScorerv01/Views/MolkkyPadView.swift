//
//  MolkkyPadView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// The 12 pins laid out as on the field : one tap scores the throw
struct MolkkyPadView: View {

    var onPick : (Int) -> Void

    let rows = [
        [7, 9, 8],
        [5, 11, 12, 6],
        [3, 10, 4],
        [1, 2],
    ]

    var body: some View {
        GeometryReader { geo in
            let pinSize = max(0, min((geo.size.height - 3 * 6) / 4, 48))

            ZStack(alignment: .bottomTrailing) {
                Color.white

                VStack(spacing: 6) {
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(row, id: \.self) { pin in
                                PinButton(label: "\(pin)", size: pinSize) {
                                    onPick(pin)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // A throw knocking no pin : 3 in a row and the player is out
                PinButton(label: "✕", size: pinSize, isMiss: true) {
                    onPick(0)
                }
                .padding(10)
            }
        }
    }
}

struct PinButton: View {
    var label : String
    var size : CGFloat
    var isMiss = false
    var action : () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        }) {
            Text(label)
                .font(Font.system(size: size * 0.45, weight: isMiss ? .light : .heavy, design: .rounded))
                .foregroundColor(isMiss ? .offRed : .purpleStart)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.offWhite))
                .overlay(Circle().stroke(isMiss ? Color.offRed : Color.purpleStart, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct MolkkyPadView_Previews: PreviewProvider {
    static var previews: some View {
        MolkkyPadView { _ in }
            .frame(height: 180)
    }
}
