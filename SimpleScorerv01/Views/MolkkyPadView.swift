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
                Text("✕  " + L("miss")).foregroundColor(.offRed).fontWeight(.light)
            }
            .buttonStyle(SimpleRectButtonStyle())
        }
    }

    func pick(_ points: Int) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        onPick(points)
    }
}

// Shanghai : the singles, doubles and triples of the number of the round, 3 darts at most
struct ShanghaiPadView: View {

    var number : Int
    var onCommit : ([Int]) -> Void

    @State private var hits = [0, 0, 0]

    let labels = [L("Single"), L("Double"), L("Triple")]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(hits.indices, id: \.self) { index in
                    Button(action: { add(index) }) {
                        VStack(spacing: 2) {
                            Text(labels[index]).fontWeight(.light)
                            Text(hits[index] > 0 ? "× \(hits[index])" : "\(number * (index + 1))").fontWeight(.heavy)
                        }
                        .foregroundColor(.purpleStart)
                    }
                    .buttonStyle(SimpleRectButtonStyle())
                }
            }

            HStack(spacing: 0) {
                Button(action: { hits = [0, 0, 0] }) {
                    Text("↺").foregroundColor(.offRed).fontWeight(.light)
                }
                .buttonStyle(SimpleRectButtonStyle())

                // No hit is a turn as well : 0
                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    onCommit(hits)
                    hits = [0, 0, 0]
                }) {
                    Text(Darts.isShanghai(hits) ? "Shanghai !" : "✓  \(Darts.shanghaiPoints(number: number, hits: hits))")
                        .foregroundColor(.purpleStart).fontWeight(.heavy)
                }
                .buttonStyle(SimpleRectButtonStyle())
            }
        }
    }

    func add(_ index: Int) {
        guard hits.reduce(0, +) < 3 else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        hits[index] += 1
    }
}

struct MolkkyPadView_Previews: PreviewProvider {
    static var previews: some View {
        MolkkyPadView { _ in }
            .frame(height: 180)
    }
}
