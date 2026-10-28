//
//  MolkkyPadView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/28/26.
//  Copyright © 2026 Stephane Giloppe. All rights reserved.
//

import SwiftUI

// Keypad of the 12 scores of a throw, one tap scores it
struct MolkkyPadView: View {

    var onPick : (Int) -> Void

    let rows = [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { points in
                        Button(action: { pick(points) }) {
                            Text("\(points)").foregroundColor(.purpleStart).fontWeight(.heavy)
                        }
                        .buttonStyle(SimpleRectButtonStyle())
                    }
                }
            }

            // A throw knocking no pin : 3 in a row and the player is out
            Button(action: { pick(0) }) {
                Text("✕  miss").foregroundColor(.offRed).fontWeight(.light)
            }
            .buttonStyle(SimpleRectButtonStyle())
        }
    }

    func pick(_ points: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        onPick(points)
    }
}

struct MolkkyPadView_Previews: PreviewProvider {
    static var previews: some View {
        MolkkyPadView { _ in }
            .frame(height: 180)
    }
}
