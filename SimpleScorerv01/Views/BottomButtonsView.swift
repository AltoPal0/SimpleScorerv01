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
    
    @Binding var showPlayerEntry : Bool
    
    @State var swipeDirection = "none"
    @GestureState var dragOffset = CGSize.zero
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                if !(self.displayInfo.screenDisplayed == .allScores)  && !(game.playerScores.count == 0)  {
                    Image(systemName: "arrow.left.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.gray : Color.gray)
                        .background(Circle().foregroundColor(Color .clear))
                        .onTapGesture {
                            withAnimation{
                                if game.nbrPlayersUnanmed() > 0 {
                                    showPlayerEntry = true
                                } else {
                                    showPlayerEntry = false
                                }
                                if self.displayInfo.screenDisplayed == .gameSetup {
                                    self.displayInfo.screenDisplayed = .scoreCards
                                } else {
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
                                    self.displayInfo.screenDisplayed = .scoreCards
                                } else {
                                    self.displayInfo.screenDisplayed = .gameSetup
                                }
                            }
                        }.padding()
                } else {
                    EmptyView()
                }
            }
        }
//        .contentShape(Rectangle())
//        .gesture(
//            DragGesture(coordinateSpace: .local)
//                .updating($dragOffset) { value, state, transaction in
//                    state.width = value.translation.width
//                    swipeDirection = value.translation.width.description
//                }
//                .onEnded({ (value) in
//                    if value.translation.width < 0 {
//                        swipeDirection = "left"
//                    } else {
//                        swipeDirection = "right"
//                    }
//                })
//        )
//        .gesture(
//            DragGesture()
//                .onEnded({ (value) in
//                    if value.translation.width < 0 && self.displayInfo.screenDisplayed != .gameSetup {
//                        swipeDirection = value.translation.width.description
//                        withAnimation{
//                            self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue + 1)!
//                        }
//                    } else if value.translation.width > 0 && self.displayInfo.screenDisplayed != .allScores {
//                        swipeDirection = value.translation.width.description
//                        if game.needsNameEntry() {
//                            withAnimation{
//                                self.showPlayerEntry = true
//                            }
//                            self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue - 1)!
//                        } else {
//                            withAnimation{
//                                self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue - 1)!
//                            }
//                        }
//                    }
//                })
//        )
    }
}

struct BottomButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        BottomButtonsView(showPlayerEntry: .constant(false))
            .environmentObject(GlobalDisplayInfo())
            .environmentObject(Game(withTestEmptyNamePlayers:()))
    }
}
