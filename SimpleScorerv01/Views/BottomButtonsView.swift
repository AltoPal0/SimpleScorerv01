//
//  BottomButtonsView.swift
//  SimpleScorerv01
//
//  Created by Dev on 7/9/22.
//  Copyright © 2022 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct BottomButtonsView: View {
    
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    @EnvironmentObject var game : Game
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var movingEdge : Edge
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                if !(self.displayInfo.screenDisplayed == .allScores) && !game.needsNameEntry() && !(game.playerScores.count == 0)  {
                    Image(systemName: "arrow.left.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.gray : Color.gray)
                        .background(Circle().foregroundColor(Color .clear))
                        .onTapGesture {
                            withAnimation{
                                if self.displayInfo.screenDisplayed == .gameSetup {
                                    self.movingEdge = .leading
                                    self.displayInfo.screenDisplayed = .scoreCards
                                } else {
//                                    self.movingEdge = .trailing
                                    self.displayInfo.screenDisplayed = .allScores
                                }
                            }
                        }.padding()
                } else {
                    EmptyView()
                }
                Spacer()
                if !(self.displayInfo.screenDisplayed == .gameSetup) {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color.gray)
                        .contentShape(Circle())
                        .background(Circle().foregroundColor(Color .clear))
                        .onTapGesture {
                            withAnimation{
                                if self.displayInfo.screenDisplayed == .allScores {
                                    self.movingEdge = .trailing
                                    self.displayInfo.screenDisplayed = .scoreCards
                                } else {
//                                    self.movingEdge = .leading
                                    self.displayInfo.screenDisplayed = .gameSetup
                                }
                            }
                        }.padding()
                } else {
                    EmptyView()
                }
                
                //                if self.dismissHelpForever {
                //                    Image(systemName: "questionmark.circle")
                //                        .font(.system(.largeTitle, design: .rounded))
                //                        .foregroundColor(Color.gray)
                //                        .padding([.bottom])
                //                        .onTapGesture {
                //                            self.showHelp = true
                //                    }
                //                }
                
            }
        }
    }
}

struct BottomButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        BottomButtonsView(movingEdge: .constant(.trailing))
            .environmentObject(GlobalDisplayInfo())
            .environmentObject(Game())
    }
}
