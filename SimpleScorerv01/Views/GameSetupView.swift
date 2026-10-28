//
//  GameSetupView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 5/7/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct GameSetupView: View {
    
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    @EnvironmentObject var game : Game
    @Binding var showPlayerEntry : Bool
    
    let dismissHelpForever = UserDefaults.standard.bool(forKey: UserDefaultsKeys.didShowHelpAllScores)
    @State private var showHelp = false
    
    @State private var showingActionSheet = false
    
    let maxHeight = CGFloat(100)
    let maxWidth = CGFloat(300)
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange, Color.purple]), startPoint: UnitPoint(x: 0.2, y: 0.2), endPoint: UnitPoint(x: 0.8, y: 0.8))
            
            VStack (spacing : 20) {
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.offWhite, lineWidth: 1)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .overlay(
                        Text("RESET SCORES")
                            .fontWeight(.semibold)
                            .font(.system(.largeTitle, design: .rounded))
                            .foregroundColor(Color .offWhite)
                    )
                    .onTapGesture {
                        self.showingActionSheet = true
                    }
                    .actionSheet(isPresented: $showingActionSheet) {
                        ActionSheet(title: Text("This will reset all scores to 0").font(.system(.headline, design: .rounded)), buttons: [
                            .default(Text("OK")) {
                                self.game.resetScores()
                                if game.playerScores.count > 0 {
                                    self.moveNextScreen()
                                }
                            },
                            .cancel()
                        ])
                    }
                
                
                
                HStack {
                    Rectangle().fill(Color.clear).border(width: 1, edge: .trailing, color: .offWhite)
                        .contentShape(Rectangle())
                        .overlay(
                            Text(" −")
                                .font(Font.system(size: 40, weight: .light, design: .rounded))
                                .foregroundColor(Color.offWhite)
                                .opacity(game.playerScores.count == 0 ? 0.5 : 1)
                        )
//                        .padding(.trailing)
                        .onTapGesture {
                            if self.game.playerScores.count > 0 {
                                self.displayInfo.gradients.append((self.game.playerScores.last?.player.colorGradient)!)
                                self.game.removeLastPlayer()
                                self.displayInfo.setSizeAndScroll(nbrPlayers: self.game.playerScores.count)
                            }
                        }
                        .frame(width: 100)
                    
                    
                    
                    VStack {
                        Text("\(self.game.playerScores.count)")
                            .font(Font.system(size: 30, weight: .regular, design: .rounded))
                            .foregroundColor(Color .offWhite)
                        
                        Text("PLAYER\(self.game.playerScores.count > 1 ? "S" : "")")
                            .font(Font.system(size: 15, weight: .light, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                            .foregroundColor(Color .offWhite)
                    }.frame(width: 100)
                    
                    
                    Rectangle().fill(Color.clear).border(width: 1, edge: .leading, color: .offWhite)
                        .contentShape(Rectangle())
                        .overlay(
                            Text("+ ")
                            .font(Font.system(size: 40, weight: .light, design: .rounded))
                            .foregroundColor(Color.offWhite)
                            .opacity(self.displayInfo.gradients.count > 0 ? 1 : 0.5)
                        )
                            
                        .onTapGesture {
                            
                            if self.displayInfo.gradients.count > 0 {
                                let grad = self.displayInfo.gradients.last!
                                self.displayInfo.gradients.removeLast()
                                self.game.addEmptyPlayer(with: grad)
                                self.displayInfo.setSizeAndScroll(nbrPlayers: self.game.playerScores.count)
                            }
                        }
                        .frame(width: 100)
                    
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14).stroke(Color.offWhite, lineWidth: 1)
                )
                .frame(maxWidth: maxWidth, maxHeight: maxHeight)

                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.offWhite, lineWidth: 1)
                    .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                    .contentShape(Rectangle())
                    .overlay(
                        VStack {
                            Text("PLAY")
                                .fontWeight(.semibold)
                                .font(.system(.largeTitle, design: .rounded))
                                .foregroundColor(Color .offWhite)
                            if let gameName = self.game.rules?.name, !gameName.isEmpty {
                                Text(gameName.uppercased())
                                    .font(Font.system(size: 15, weight: .light, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.1)
                                    .foregroundColor(Color .offWhite)
                            }
                        }
                    ).onTapGesture {
                        self.moveNextScreen()
                    }
            }
            .padding()
        }
        .mask(
            VStack (spacing : 20) {
                Rectangle().cornerRadius(14).frame(maxWidth: maxWidth, maxHeight: maxHeight)
                Rectangle().cornerRadius(14).frame(maxWidth: maxWidth, maxHeight: maxHeight)
                Rectangle().cornerRadius(14).frame(maxWidth: maxWidth, maxHeight: maxHeight)
            }
                .padding()
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
    }
    
    func moveNextScreen() {
//        game.updatePreviousPlayers()
        if self.game.nbrPlayersUnanmed() > 0 {
            self.showPlayerEntry = true
        }
        self.displayInfo.screenDisplayed = .scoreCards
    }
    
}



struct GameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        
        GameSetupView(showPlayerEntry: .constant(false))
            .environmentObject(Game())
            .environmentObject(GlobalDisplayInfo())
    }
}




