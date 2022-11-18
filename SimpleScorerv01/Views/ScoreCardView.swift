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
    
    var playerScore : PlayerScore
    var scrollReaderProxy : ScrollViewProxy
    @Binding var orderByScores : Bool
    
    @State private var pointsScored = CGFloat(0)
    @State private var sign = CGFloat(1)
    @State private var scoreEditing = false
    @State private var showKeyPad = false
    
    @State private var nameEditing = false
    @State private var username = ""
    
    let frameHeight = CGFloat(135)
    @State private var maxWidth = CGSize.zero
    @State private var showBottomBar = false
    @State private var slideOpen = false
    @State private var showingAlert = false
    @State private var isOverflowingScreen = false
    
    private enum Field:Int, Hashable {
        case  name
    }
    
    @FocusState private var focusedField: Field?
    
    @GestureState private var dragOffset = CGSize.zero
//    @State private var dragOffset = CGSize(width: -180, height: 0)
    
//    var index : Int
    
    var body: some View {
        
            ZStack {

                // button delete / edit
                HStack {
                    Spacer()
                    
                    Button(action: {
                        self.displayInfo.gradients.append(self.playerScore.player.colorGradient)
                        withAnimation {
                            self.game.removePlayer(player: self.playerScore.player)
                            self.displayInfo.setSizeAndScroll(nbrPlayers: self.game.playerScores.count)
                        }
                    }) {
                        Image(systemName: "trash.circle")
                            .font(.system(size: 45, weight: .light, design: .default))
                            .foregroundColor(Color.offRed)
                            .contentShape(Rectangle()).frame(height: self.frameHeight*2/3)
                    }
                    
                    Button(action: {
                        self.focusedField = .name
                        self.nameEditing = true
                        self.slideOpen = false
                        self.displayInfo.setSizeAndScroll(nbrPlayers: self.game.playerScores.count)
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 45, weight: .light, design: .default))
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
                            
                            if self.playerScore.totalScore() < 1000000 {
                                playerNameView
                            }
                            
                            if !nameEditing {
                                ExpandableScoreSection
                            }

                        }
                        .frame(height: frameHeight*2/3)
                        
                        if self.showBottomBar || self.displayInfo.scoreCardSize == .normal {
                            if self.showKeyPad {
                                KeyPadView(valueDisplayed: $pointsScored, sign: $sign)
                                    .frame(height: frameHeight*4/3)
                                    .cornerRadius(14, corners: [.bottomLeft, .bottomRight])
                                    .padding([.horizontal,.bottom],3)
                                    .disabled(self.dragOffset.width != 0)
                            }
                            else {
                                ScoringBottomBarTools
                                    .frame(height: frameHeight/3)
                                    .disabled(self.dragOffset.width != 0)
                            }
                        }
                    }
                    .frame(maxWidth: maxWidth.width)
                }
                .background(GeometryReader { geo -> Color in
                    DispatchQueue.main.async {
                            maxWidth = geo.size
                            if geo.frame(in: .global).maxY > UIScreen.main.bounds.maxY {
                                self.isOverflowingScreen = true
                            } else {
                                self.isOverflowingScreen = false
                            }
                        }
                        return Color.clear
                    })
                .clipShape(Rectangle()).cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.offWhite, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
                .offset(slideOpen ? CGSize(width: -120, height: 0) : dragOffset)
            }
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .updating($dragOffset) { value, state, transaction in
                        state.width = value.translation.width
                    }
                    .onEnded({ (value) in
                            if value.translation.width < -100 && !self.scoreEditing && !slideOpen {
                                self.slideOpen = true
                            } else {
                                self.slideOpen = false
                            }
                    })
            ) //drag
            .onLongPressGesture {
                withAnimation {
                    orderByScores.toggle()
                }
            }
            .onTapGesture {
                
                if self.slideOpen {
                   
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.slideOpen = false
                    }
                }
                else {
                    self.scoreEditing = true
                    if self.displayInfo.scoreCardSize == .compact {
                            self.showKeyPad.toggle()
                    }
                    self.showBottomBar = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if self.isOverflowingScreen {
                            withAnimation {
                                self.scrollReaderProxy.scrollTo(self.playerScore.id)
                            }
                        }
                    }
                }
            } //tap
            
        
        
            
        
    }
    
    var playerNameView: some View {
        Group {
            if !scoreEditing {
                if !self.nameEditing && self.playerScore.player.name != Player.defaultName {
                    Text(self.playerScore.player.name)
                        .font(Font.system(size: 40, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                        .foregroundColor(Color .offWhite)
                } else {
                    HStack {
                        TextField("Name?", text: self.$username,onEditingChanged: {change in }, onCommit: {commitName()})
                        .focused($focusedField, equals: .name)
                        .font(.system(.largeTitle, design: .rounded))
                        .background(Color.offWhite.opacity(0.6))
                        .foregroundColor(Color.offWhite)
                        .foregroundColor(Color .offWhite)
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
                            .overlay(Image(systemName: "checkmark").foregroundColor(Color.white))
                            .frame(minWidth:70, maxWidth:70, maxHeight: .infinity)
                            .onTapGesture {commitName()}
                        
                    }
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("No name entered"), message: Text("Please enter a name"), dismissButton: .default(Text("OK")))
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
    
    var totalFrameHeight : CGFloat {
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
                            .padding()
                            .contentShape(Rectangle())
                        Spacer()
                    }
                    .frame(minWidth:20, maxWidth:20, maxHeight: .infinity)
                    .onTapGesture {
                        self.pointsScored = 0
                        self.sign = 1
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
                    
                    Text("\(self.playerScore.totalScore()) \(self.sign >= 0 ? "+" : "-") \( String(format: "%.0f",abs(self.pointsScored)))")
                        .font(Font.system(size: 25, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .foregroundColor(Color .offWhite)
                        .padding(10)
                        
                    Rectangle().fill(Color.offWhite.opacity(0.5))
                            .border(width: 1, edge: .leading, color: .offWhite)
                            .overlay(Image(systemName: "checkmark").foregroundColor(Color.white))
                            .frame(minWidth:70, maxWidth:70, maxHeight: .infinity)
                            .onTapGesture {
                                self.game.addPointsFor(player: self.playerScore.player, points: Int(String(format: "%.0f",abs(self.pointsScored) * sign))!)
                                self.pointsScored = 0
                                self.sign = 1
                                self.scoreEditing = false
                                self.showKeyPad = false
                                if self.displayInfo.scoreCardSize == .compact {
                                    self.showBottomBar = false
                                }
                        }
                } else {
                    Text("\(self.playerScore.totalScore())")
                        .font(Font.system(size: self.scoreEditing ? 25 : 50, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                        .foregroundColor(Color .offWhite)
                        .padding(.horizontal,self.scoreEditing ? 0 : 20)
                }
            }
            
            
            
        }
    }
    
    var ScoringBottomBarTools: some View {
        HStack (spacing: 0) {
            
            Button(action: {
                self.scoreEditing = true
                self.sign = self.pointsScored <= 0 ? -1 : 1
                self.pointsScored -= 1
            }) {
                Image(systemName: "minus.rectangle")
                    .foregroundColor(.purpleStart)
            }
            .buttonStyle(SimpleRectButtonStyle())
            
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
            
            Button(action: {
                self.scoreEditing = true
                self.sign = self.pointsScored >= 0 ? 1 : -1
                self.pointsScored += 1
            }) {
                Image(systemName: "plus.rectangle")
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
                ScoreCardView(playerScore: PlayerScore(player: Player(name: "Stephane", initials: "St", colorGradient: LinearGradient.gradDefault), pointsList: [Points(score: 1000, round: 0)]),scrollReaderProxy: proxy, orderByScores: .constant(false))
    //                    .previewLayout(.sizeThatFits)
                        .padding(.horizontal, 15)
                        .padding(.bottom,15)
            }
        }
        .environmentObject(Game())
        .environmentObject(GlobalDisplayInfo())
    }
}
