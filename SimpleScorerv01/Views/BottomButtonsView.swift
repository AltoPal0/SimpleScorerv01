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
    
    @State private var showSettings = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                // Only when there is somewhere to go
                if self.displayInfo.screenOnLeft(game: game) != nil {
                    Image(systemName: "arrow.left.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color.gray)
                        .contentShape(Circle())
                        .onTapGesture {
                            self.displayInfo.moveLeft(game: game)
                        }.padding()
                }
                Spacer()
                if self.displayInfo.screenOnRight(game: game) != nil {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color.gray)
                        .contentShape(Circle())
                        .onTapGesture {
                            self.displayInfo.moveRight(game: game)
                        }.padding()
                }
            }
            // Settings of the app on the setup screen, between the arrows : appearance and language
            .overlay {
                if self.displayInfo.screenDisplayed == .gameSetup {
                    Image(systemName: "gearshape.circle")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundColor(Color.gray)
                        .contentShape(Circle())
                        .onTapGesture {
                            self.showSettings = true
                        }.padding()
                }
            }
        }
        // The screens behind take the new language once the settings are closed
        .sheet(isPresented: $showSettings, onDismiss: {
            AppSettings.shared.applyLanguage()
        }) {
            SettingsView()
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
        BottomButtonsView()
            .environmentObject(GlobalDisplayInfo())
            .environmentObject(Game(withTestEmptyNamePlayers:()))
    }
}
