//
//  ScoreCardView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 4/17/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct ScoreCardView: View {
    
    @EnvironmentObject var game : Game
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    // Bigger cards on iPad, same proportions : every size of the card follows this scale
    @Environment(\.cardScale) var scale
    @Environment(\.cardNames) var cardNames
    
    var playerScore : PlayerScore
    var scrollReaderProxy : ScrollViewProxy
    var noshadow = false
    
    @Binding var indexForEditView : Int
    @Binding var displayEditView : Bool
    
    @State private var pointsScored = CGFloat(0)
    @State private var sign = CGFloat(1)
    @State private var scoreEditing = false
    @State private var showKeyPad = false
    @State private var molkkyAlert : Game.MolkkyWarning?
    // Shanghai : singles, doubles and triples of the turn being entered
    @State private var shanghaiHits = [0, 0, 0]
    @State private var confirmDelete = false
    
    @State private var nameEditing = false
    @State private var username = ""
    
    var frameHeight: CGFloat { 135 * scale }
    @State private var showBottomBar = false
    @State private var slideOpen = false
    @State private var showingAlert = false
    @State private var isOverflowingScreen = false
    
    private enum Field:Int, Hashable {
        case  name
    }
    
    @FocusState private var focusedField: Field?
    
    // Released, the card springs back in place with a light bounce, as in iOS
    static let slideSpring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    @GestureState(resetTransaction: Transaction(animation: ScoreCardView.slideSpring)) private var dragOffset = CGSize.zero
//    @State private var dragOffset = CGSize(width: -180, height: 0)
    
//    var index : Int
    
    var body: some View {
        
            ZStack {

                // button delete / edit
                HStack {
                    Spacer()
                    
                    Button(action: {
                        self.confirmDelete = true
                    }) {
                        Image(systemName: "trash.circle")
                            .font(.system(size: 45 * scale, weight: .light, design: .default))
                            .foregroundColor(Color.offRed)
                            .contentShape(Rectangle()).frame(height: self.frameHeight*2/3)
                    }
                    // The player and all his scores go : asked before
                    .alert(L("Delete %@?", self.playerScore.player.name), isPresented: $confirmDelete) {
                        Button(L("Delete"), role: .destructive) {
                            self.deletePlayer()
                        }
                        Button(L("Cancel"), role: .cancel) {}
                    } message: {
                        Text(L("His scores are deleted as well."))
                    }
                    
                    Button(action: {
                        self.indexForEditView = game.indexOf(player: self.playerScore.player)!
                        withAnimation {
                            self.displayEditView = true
                        }
                        self.slideOpen = false
                        self.displayInfo.showBottomButtons = true
//                        self.displayInfo.setSizeAndScroll(nbrPlayers: self.game.playerScores.count)
                    }) {
                        Image(systemName: "square.and.pencil.circle")
                            .font(.system(size: 45 * scale, weight: .light, design: .default))
                            .foregroundColor(Color.gray)
                            .contentShape(Rectangle()).frame(height: self.frameHeight*2/3)
                    }
                }
                
                // Actual whole card
                ZStack {
  
                    self.playerScore.player.colorGradient.frame(height: totalFrameHeight)
                    
                    VStack (spacing: 0){
                        
                        HStack (alignment: .center, spacing: 0) {
                            AvatarView(user: playerScore.player)
                                .padding(10)
                                .frame(width: frameHeight*2/3)
                            
                            if self.game.total(for: self.playerScore) < 1000000 {
                                playerNameView
                            }
                            
                            if !nameEditing {
                                ExpandableScoreSection
                            }

                        }
                        .frame(height: frameHeight*2/3)
                        
                        if (self.showBottomBar || self.displayInfo.scoreCardSize == .normal) && !self.game.entersRounds {
                            if self.showKeyPad && self.game.activeKind == .molkky {
                                MolkkyPadView { pins in
                                    self.commitPoints(pins)
                                }
                                    .frame(height: frameHeight*4/3)
                                    .cornerRadius(14, corners: [.bottomLeft, .bottomRight])
                                    .padding([.horizontal,.bottom],3)
                                    .disabled(self.dragOffset.width != 0)
                                    .font(.system(size: 20 * scale, design: .rounded))
                            } else if self.showKeyPad {
                                KeyPadView(valueDisplayed: $pointsScored, sign: $sign,
                                           extraKey: self.game.activeKind == .scrabble ? "+50" : nil,
                                           onExtraKey: { self.pointsScored += 50 })
                                    .frame(height: frameHeight*4/3)
                                    .cornerRadius(14, corners: [.bottomLeft, .bottomRight])
                                    .padding([.horizontal,.bottom],3)
                                    .disabled(self.dragOffset.width != 0)
                                    .font(.system(size: 20 * scale, design: .rounded))
                            }
                            else {
                                ScoringBottomBarTools
                                    .frame(height: frameHeight/3)
                                    .font(.system(size: 20 * scale))
                                    .disabled(self.dragOffset.width != 0)
                            }
                        }
                    }
                }
                .background(GeometryReader { geo -> Color in
                    // Measured at every frame of a scroll : the state changes only when it has to
                    let overflowing = geo.frame(in: .global).maxY > UIScreen.main.bounds.maxY
                    if overflowing != self.isOverflowingScreen {
                        DispatchQueue.main.async {
                            self.isOverflowingScreen = overflowing
                        }
                    }
                    return Color.clear
                    })
                .clipShape(Rectangle()).cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.offWhite, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(noshadow ? 0.0 : 0.3), radius: 10, x: 0, y: 10)
                .offset(x: cardOffset)
            }
            // Simultaneous and horizontal only : the list keeps scrolling and pulling to change the order
            .simultaneousGesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .updating($dragOffset) { value, state, transaction in
                        if !self.scoreEditing && abs(value.translation.width) > abs(value.translation.height) {
                            state.width = value.translation.width
                        }
                    }
                    .onEnded({ (value) in
                        guard !self.scoreEditing, abs(value.translation.width) > abs(value.translation.height) else { return }
                        // Where the card would stop with its speed : a quick flick is enough
                        let end = (self.slideOpen ? self.openOffset : 0) + value.predictedEndTranslation.width
                        withAnimation(ScoreCardView.slideSpring) {
                            self.slideOpen = end < self.openOffset / 2
                        }
                        self.displayInfo.showBottomButtons = !self.slideOpen
                    })
            ) 
            .onTapGesture {
                
                if self.slideOpen {
                    withAnimation(ScoreCardView.slideSpring) {
                        self.slideOpen = false
                    }
                    displayInfo.showBottomButtons = true
                }
                else if self.game.entersRounds {
                    self.displayInfo.roundEntryPlayerID = self.playerScore.player.id
                }
                else if self.game.entersPosition {
                    if self.displayInfo.scoreCardSize == .compact {
                        withAnimation {
                            self.showBottomBar.toggle()
                        }
                    }
                }
                else if self.game.isShanghai && self.game.shanghaiNumber(for: self.playerScore) == nil {
                    return
                }
                else if self.game.isEliminated(self.playerScore) {
                    self.molkkyAlert = .eliminated
                }
                else if !self.scoreEditing, let warning = self.game.molkkyWarning(for: self.playerScore) {
                    // Mölkky : everyone plays the same number of turns
                    self.molkkyAlert = warning
                }
                else {
                    self.startScoreEntry()
                }
            } //tap
            .alert(self.molkkyAlert.map { self.game.molkkyWarningTitle($0, for: self.playerScore) } ?? "", isPresented: Binding(
                get: { self.molkkyAlert != nil },
                set: { if !$0 { self.molkkyAlert = nil } })) {
                    if self.molkkyAlert == .eliminated {
                        Button(L("Keep playing")) {
                            self.game.keepEliminatedPlaying()
                            self.startScoreEntry()
                        }
                        Button(L("Cancel"), role: .cancel) {}
                    } else {
                        Button(L("OK")) {
                            self.startScoreEntry()
                        }
                    }
                } message: {
                    Text(self.molkkyAlert.map { self.game.molkkyWarningMessage($0, for: self.playerScore) } ?? "")
                }
    }
    
    func startScoreEntry() {
        self.scoreEditing = true
        if self.game.activeKind == .molkky {
            self.showKeyPad = true
        } else if self.game.isShanghai {
            self.showKeyPad = false
        } else if self.displayInfo.scoreCardSize == .compact {
                self.showKeyPad.toggle()
        }
        self.showBottomBar = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.isOverflowingScreen {
                withAnimation {
                    self.scrollReaderProxy.scrollTo(self.playerScore.id)
                }
                if self.showKeyPad == true {
                    self.displayInfo.showBottomButtons = false
                } else {
                    self.displayInfo.showBottomButtons = true
                }
                
            }
        }
    }
    
    var playerNameView: some View {
        Group {
            if !scoreEditing {
                if !self.nameEditing && self.playerScore.player.name != Player.defaultName {
                    // Same size for every name. Too long next to the totals : the avatar alone
                    if self.cardNames.showsNames {
                        Text(self.playerScore.player.name)
                            .font(Font.system(size: self.cardNames.fontSize, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .foregroundColor(Color .offWhite)
                    }
                } else {
                    HStack {
                        TextField(L("Name?"), text: self.$username,onEditingChanged: {change in }, onCommit: {commitName()})
                        .focused($focusedField, equals: .name)
                        .font(.system(.largeTitle, design: .rounded))
                        .background(Color.offWhite.opacity(0.6))
                        .foregroundColor(Color.offWhite)
                        .onTapGesture {
                            if displayInfo.screenDisplayed == .scoreCards {
                                self.focusedField = .name
                            } else {
                                if game.nbrOfPlayersNeedingNames() - game.indexOfPlayerWithNoName(playerScore: self.playerScore) == 1 {
                                    self.focusedField = .name
                                }
                                
                            }
                        }
                        
                        Rectangle().fill(Color.offWhite.opacity(0.5))
                            .border(width: 1, edge: .leading, color: .offWhite)
                            .overlay(
                                Text("✓")
                                    .font(Font.system(size: 30, design: .rounded))
                                    .foregroundColor(Color.offWhite)
                            )
                            .frame(minWidth:70, maxWidth:70, maxHeight: .infinity)
                            .onTapGesture {commitName()}
                        
                    }
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(L("No name entered")), message: Text(L("Please enter a name")), dismissButton: .default(Text(L("OK"))))
        }
    }
    
    func commitName() -> Void {
        if self.username.count == 0 {
            self.showingAlert = true
        } else {
            
            self.nameEditing = false
            let index = self.game.playerScores.firstIndex(where: {$0.id == self.playerScore.id})!
            self.game.playerScores[index].player.name = self.username.capitalized.trimmingCharacters(in: .whitespacesAndNewlines)
            self.game.avatarInitialsForPlayers()
            
            self.username = ""
            self.displayInfo.indexOFTextfieldFocused += 1
        }
    }
    
    // Slid open, the card uncovers the delete and edit buttons
    var openOffset: CGFloat { -120 * scale }
    
    // Follows the finger, with resistance beyond the closed and open positions
    var cardOffset: CGFloat {
        let offset = (slideOpen ? openOffset : 0) + dragOffset.width
        if offset > 0 {
            return offset / 4
        }
        if offset < openOffset {
            return openOffset + (offset - openOffset) / 4
        }
        return offset
    }
    
    func deletePlayer() {
        if let index = self.playerScore.player.gradientIndex {
            self.displayInfo.gradientIndices.append(index)
        }
        withAnimation {
            self.game.removePlayer(player: self.playerScore.player)
            self.displayInfo.setSizeAndScroll(nbrPlayers: self.game.playerScores.count)
        }
        self.displayInfo.showBottomButtons = true
    }
    
    // Around the clock : a number reached is a +1, going back takes the last one off
    func moveOnClock(by step: Int) {
        let position = self.game.total(for: self.playerScore)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if step > 0 && position < Darts.clockTargets {
            self.game.addPointsFor(player: self.playerScore.player, points: 1)
        } else if step < 0, let last = self.playerScore.pointsList.last {
            self.game.deletePointsFor(player: self.playerScore.player, round: last.round)
        }
    }
    
    func commitPoints(_ points: Int, marks: [Int]? = nil) {
        self.displayInfo.showBottomButtons = true
        self.game.addPointsFor(player: self.playerScore.player, points: points, marks: marks)
        self.pointsScored = 0
        self.sign = 1
        self.shanghaiHits = [0, 0, 0]
        self.scoreEditing = false
        self.showKeyPad = false
        if self.displayInfo.scoreCardSize == .compact {
            self.showBottomBar = false
        }
    }
    
    // Under the total : winner, out, Mölkky misses or points still to score
    var gameCaption: Text? {
        if self.game.winner() == self.playerScore {
            return Text(Image(systemName: "crown.fill"))
        }
        if self.game.isEliminated(self.playerScore) {
            return nil
        }
        if self.game.activeKind == .molkky {
            let misses = Molkky.consecutiveMisses(self.playerScore.pointsList.map { $0.score })
            if misses > 0 {
                return Text(String(repeating: "✕", count: misses))
            }
        }
        // Darts 501 and 301 : what is left is already the big number
        if !self.game.countsDown, let remaining = self.game.remaining(for: self.playerScore) {
            return Text(L("%ld to go", remaining))
        }
        return nil
    }
    
    var totalFrameHeight : CGFloat {
        if self.game.entersRounds {return frameHeight*2/3}
        if self.showKeyPad {return frameHeight * 6/3}
        if self.showBottomBar || self.displayInfo.scoreCardSize == .normal {return frameHeight}
        return frameHeight*2/3
    }
    
    var ExpandableScoreSection: some View {
        Group {
            // X mark of score editing
            VStack {
                if scoreEditing {
                    
                    VStack {
                        Image(systemName: "xmark").foregroundColor(Color.white)
                            .font(.system(size: 17 * scale))
                            .padding()
                            .contentShape(Rectangle())
                        Spacer()
                    }
                    .frame(minWidth:20 * scale, maxWidth:20 * scale, maxHeight: .infinity)
                    .onTapGesture {
                        self.displayInfo.showBottomButtons = true
                        self.pointsScored = 0
                        self.sign = 1
                        self.shanghaiHits = [0, 0, 0]
                        self.scoreEditing = false
                        self.showKeyPad = false
                        if self.displayInfo.scoreCardSize == .compact {
                            self.showBottomBar = false
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                if scoreEditing {
                    
                    Text(verbatim: self.game.isShanghai
                         ? "\(self.game.total(for: self.playerScore)) + \(self.shanghaiPoints)"
                         : self.game.countsDown
                         ? "\(self.game.displayedTotal(for: self.playerScore)) - \(String(format: "%.0f",abs(self.pointsScored)))"
                         : "\(self.game.total(for: self.playerScore)) \(self.sign >= 0 ? "+" : "-") \( String(format: "%.0f",abs(self.pointsScored)))")
                        .font(Font.system(size: 25 * scale, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .foregroundColor(Color .offWhite)
                        .padding(10)
                        
                    Rectangle().fill(Color.offWhite.opacity(0.5))
                            .border(width: 1, edge: .leading, color: .offWhite)
                            .overlay(Image(systemName: "checkmark").foregroundColor(Color.white).font(.system(size: 17 * scale)))
                            .frame(minWidth:70 * scale, maxWidth:70 * scale, maxHeight: .infinity)
                            .onTapGesture {
                                if self.game.isShanghai {
                                    self.commitPoints(self.shanghaiPoints, marks: self.shanghaiHits)
                                } else {
                                    self.commitPoints(Int(String(format: "%.0f",abs(self.pointsScored) * sign))!)
                                }
                        }
                } else {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(self.game.isEliminated(self.playerScore) ? "✕" : "\(self.game.displayedTotal(for: self.playerScore))")
                            .font(Font.system(size: self.scoreEditing ? 25 * scale : self.cardNames.scoreSize, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.2)
                            .lineLimit(1)
                            .foregroundColor(Color .offWhite)
                        if let caption = self.gameCaption {
                            // Whole, under the name if needed : it takes no width from the name
                            caption
                                .font(Font.system(size: 15 * scale, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .fixedSize()
                                .frame(width: 0, alignment: .trailing)
                                .foregroundColor(Color .offWhite)
                        }
                    }
                    .padding(.horizontal,self.scoreEditing ? 0 : 20 * scale)
                }
            }
            
            
            
        }
    }
    
    var shanghaiPoints: Int {
        Darts.shanghaiPoints(number: self.game.shanghaiNumber(for: self.playerScore) ?? 0, hits: self.shanghaiHits)
    }
    
    // Shanghai : a tap per dart on the number of the round, 3 darts at most
    var ShanghaiBottomBar: some View {
        HStack (spacing: 0) {
            ForEach(Array([L("Single"), L("Double"), L("Triple")].enumerated()), id: \.offset) { index, label in
                Button(action: {
                    // 3 darts, and only during the 7 rounds
                    guard self.shanghaiHits.reduce(0, +) < 3, self.game.shanghaiNumber(for: self.playerScore) != nil else { return }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    self.scoreEditing = true
                    self.shanghaiHits[index] += 1
                }) {
                    Text(self.shanghaiHits[index] > 0 ? "\(label) ×\(self.shanghaiHits[index])" : label)
                        .foregroundColor(.purpleStart)
                        .fontWeight(self.shanghaiHits[index] > 0 ? .heavy : .regular)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .buttonStyle(SimpleRectButtonStyle())
            }
        }
    }
    
    @ViewBuilder var ScoringBottomBarTools: some View {
        if self.game.isShanghai {
            ShanghaiBottomBar
        } else {
            PointsBottomBar
        }
    }
    
    var PointsBottomBar: some View {
        HStack (spacing: 0) {
            
            Button(action: {
                // Around the clock : back to the previous number at once
                if self.game.entersPosition {
                    self.moveOnClock(by: -1)
                    return
                }
                self.scoreEditing = true
                self.sign = self.pointsScored <= 0 ? -1 : 1
                self.pointsScored -= 1
            }) {
                Image(systemName: self.game.entersPosition ? "arrow.left.square" : "minus.rectangle")
                    .foregroundColor(.purpleStart)
            }
            .buttonStyle(SimpleRectButtonStyle())
            
            // Around the clock : only the next number or the previous one, no points to type
            if !self.game.entersPosition {
                Button(action: {
                    self.scoreEditing = true
                    self.showKeyPad.toggle()
                }) {
                    if showKeyPad {
                        Image(systemName: "chevron.up.circle")
                            .foregroundColor(.purpleStart)
                    } else {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(.purpleStart)
                    }
                }
                .buttonStyle(SimpleRectButtonStyle())
            }
            
            Button(action: {
                // Around the clock : on to the next number at once
                if self.game.entersPosition {
                    self.moveOnClock(by: 1)
                    return
                }
                self.scoreEditing = true
                self.sign = self.pointsScored >= 0 ? 1 : -1
                self.pointsScored += 1
            }) {
                Image(systemName: self.game.entersPosition ? "arrow.right.square" : "plus.rectangle")
                    .foregroundColor(.purpleStart)
            }
            .buttonStyle(SimpleRectButtonStyle())
        }
    }
    
//    func fontSize(nbrChar :Int, fontSize :Int) -> CGFloat {
//
//        if nbrChar <= 5 { return CGFloat(fontSize)}
//
////        return self.scoreEditing ? CGFloat(fontSize - (nbrChar-2)*10 ) : CGFloat(fontSize - (nbrChar-3)*10)
//        return CGFloat(fontSize - (nbrChar-5)*5 )
//    }
}

struct ScoreCardView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            ScrollViewReader { proxy in
                ScoreCardView(playerScore: PlayerScore(player: Player(name: "Stephane", initials: "St", gradientIndex: nil), pointsList: [Points(score: 1000, round: 0)]),scrollReaderProxy: proxy, indexForEditView: .constant(0), displayEditView: .constant(false))
    //                    .previewLayout(.sizeThatFits)
                        .padding(.horizontal, 15)
                        .padding(.bottom,15)
            }
        }
        .environmentObject(Game())
        .environmentObject(GlobalDisplayInfo())
    }
}
