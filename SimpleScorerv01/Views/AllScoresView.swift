//
//  AllScoresView.swift
//  SimpleScorerv01
//
//  Created by Dev on 6/19/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

//Section(header: Text("Sticky Header")) {
//    ForEach(0...3) { item in
//        Text(item)
//    }
//}
//}

import SwiftUI



struct AllScoresView: View {
    
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    @EnvironmentObject var game : Game
    
    @State private var cell  = (cellIndex: -1, playerScore: PlayerScore())
    @State private var showKeypad = false
    @State private var pointScored = CGFloat(0)
    @State private var sign = CGFloat(1)
    @State private var editMode = ScoreEditMode.modification
    
    @State private var showHelp = true
    @State private var dismissHelpForever = UserDefaults.standard.bool(forKey: UserDefaultsKeys.didShowHelpAllScores)
    
    
    let scoreColumnMaxWidth = CGFloat(80)
    let pointCellsHeight = CGFloat(40)
    let frameHeight = CGFloat(135)
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
//                Color.offWhite.edgesIgnoringSafeArea(.all)
                
                ScrollView(geometry.size.width/CGFloat(game.playerScores.count) < scoreColumnMaxWidth ? .horizontal : []) {
                    HStack {
                        Spacer()
                        
                        ForEach(self.game.playerScores, id: \.id) { playerScore in
                            
                            PlayerScoreColumn(
                                cell: $cell,
                                showKeypad: $showKeypad,
                                editMode: $editMode,
                                playerScore: playerScore,
                                game: game,
                                geometry: geometry,
                                scoreColumnMaxWidth: scoreColumnMaxWidth,
                                cellHeight: pointCellsHeight
                            )
                            .frame(maxWidth:scoreColumnMaxWidth)
                            .background(playerScore.player.colorGradient)
                            .clipShape(Rectangle()).cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                            
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                
//                Text(String(self.displayInfo.allScoreScrolling))
                
                if showKeypad {
                    VStack {
                        Spacer()
                        scoreCorrectionView.padding(.bottom,50)
                    }
                    
                }
            }
        }
    }
    
    var scoreCorrectionView: some View {
        
        var display : String {
            if editMode == ScoreEditMode.modification {
                return "\(String(cell.playerScore.pointsList[cell.0].score)) ⇢ \(self.sign >= 0 ? "" : "-") \( String(format: "%.0f",abs(pointScored)))"
            } else {
                return "\(cell.playerScore.totalScore()) \(self.sign >= 0 ? "+" : "-") \(String(format: "%.0f",abs(pointScored)))"
            }
        }
        
        return ZStack {
            
            cell.playerScore.player.colorGradient
            
            VStack {
                HStack {
                    Image(systemName: "xmark").foregroundColor(Color.white)
                        .contentShape(Rectangle()).frame(width: 50, height: 50)
                        .offset(x: -10, y: -10)
                        .onTapGesture(count: 1, perform: {
                            showKeypad = false
                            sign = 1
                            pointScored = 0
                        })
                    
                    Spacer()
                }
                Spacer()
            }

            
            VStack (spacing:0){
                
                HStack {
                    Spacer()
                    
                    Text(display)
                        .font(Font.system(
                                size: fontSize(nbrChar: display.count - 2, fontSize: 50),
                                weight: .bold,
                                design: .rounded))
                        .scaledToFill()
                        .minimumScaleFactor(0.9)
                        .lineLimit(1)
                        .foregroundColor(Color .offWhite)
                        .padding(.horizontal,20)
                    
                    Spacer()
                    
                    Rectangle().fill(Color.offWhite.opacity(0.5))
                            .border(width: 1, edge: .leading, color: .offWhite)
                            .overlay(Image(systemName: "checkmark").foregroundColor(Color.white))
                            .frame(minWidth:70, maxWidth:70, maxHeight: .infinity)
                            .onTapGesture {
                                if editMode == .modification {
                                    game.playerScores[game.indexOf(player: cell.playerScore.player)!].modifyScore(newScore: Int(pointScored * sign), forRound: cell.cellIndex)
                                    showKeypad = false
                                    sign = 1
                                    pointScored = 0
                                } else {
                                    game.addPointsFor(player: cell.playerScore.player, points: Int(pointScored * sign))
                                    showKeypad = false
                                    sign = 1
                                    pointScored = 0
                                }
                        }
                }
                .frame(height: frameHeight*2/3)
                
                KeyPadView(valueDisplayed: $pointScored, sign: $sign)
                    .frame(height: frameHeight*4/3)
                    
            }
            
        }
        .frame(width: 300, height: frameHeight*6/3)
        .clipShape(Rectangle()).cornerRadius(14)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
        
    }
}

struct PlayerScoreColumn: View {
    
    @Binding var cell : (cellIndex: Int, playerScore: PlayerScore)
    @Binding var showKeypad : Bool
    @Binding var editMode : ScoreEditMode
   
    
    var playerScore : PlayerScore
    var game : Game
    var geometry : GeometryProxy
    let scoreColumnMaxWidth : CGFloat
    let cellHeight :  CGFloat
    
    @State private var showingActionSheet = false

    
    var body: some View {
        ZStack{
            //
            VStack (spacing:0){
                
                let maxHeightForPoints = geometry.size.height - scoreColumnMaxWidth - 50
                
                AvatarView(user: playerScore.player)
                    .padding(5)
                    .frame(minWidth:scoreColumnMaxWidth, maxHeight:scoreColumnMaxWidth)
                
                ScrollView(maxHeightForPoints/CGFloat(game.maxNbrOfRounds+1) < cellHeight ? .vertical : []) {
                    VStack {
                        pointList
                        Spacer()
                    }
                }
                .border(width: 1, edge: .bottom, color: .offWhite)
                .border(width: 1, edge: .top, color: .offWhite)
                .frame(maxHeight:8 + max(cellHeight * CGFloat(game.maxNbrOfRounds), cellHeight))
                
                Rectangle().fill(Color.clear)
                    .overlay(
                        Text(String(playerScore.totalScore())))
                            .font(Font.system(size: fontSize(nbrChar: String(playerScore.totalScore()).count + 1, fontSize: 25)
                                              , weight: .bold
                                              , design: .rounded))
                    .foregroundColor(Color.offWhite)
                    .frame(height:50)
                    .onTapGesture(count: 1, perform: {
                        cell.playerScore = playerScore
                        cell.cellIndex = 0
                        editMode = ScoreEditMode.addition
                        showKeypad = true
                    })
                
            }.padding(0)
        }
        
    }
    
    var pointList: some View {

        ForEach(playerScore.pointsList, id: \.self) { points in
            
            Rectangle()
                .fill(points.round % 2 == 0 ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                .frame(height:cellHeight)
                .border(Color.white, width: (cell.0 == points.round && cell.playerScore.id == playerScore.id && showKeypad && editMode == .modification) ? 5 : 0)
                .overlay(Text( ("\(String(points.score))")).foregroundColor(Color .white))
                .padding(-3)
                .onTapGesture(count: 1, perform: {
                    if (cell.cellIndex == points.round && cell.playerScore.id == playerScore.id) {
                        cell.cellIndex = -1
                        cell.playerScore = PlayerScore()
                        showKeypad = false
                    } else {
                        cell.cellIndex = points.round
                        cell.playerScore = playerScore
                        editMode = ScoreEditMode.modification
                        showKeypad = true
                    }
                })
                .onLongPressGesture {
                    self.showingActionSheet = true
                    cell.cellIndex = points.round
                    cell.playerScore = playerScore
                }.actionSheet(isPresented: $showingActionSheet) {
                    ActionSheet(title: Text("Delete this entry ?").font(.system(.headline, design: .rounded)), buttons: [
                        .default(Text("OK")) {
                            game.deletePointsFor(player: playerScore.player, round: cell.cellIndex)
                        },
                        .cancel()
                    ])
                }
        }
    }
}


struct AllScoresView_Previews: PreviewProvider {
    static var previews: some View {
        AllScoresView()
            .environmentObject(GlobalDisplayInfo())
            .environmentObject(Game(withTestPlayers: ()))
//            .environmentObject(Game())
    }
}

