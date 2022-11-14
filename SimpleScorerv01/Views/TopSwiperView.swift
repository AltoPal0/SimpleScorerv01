//
//  TopSwiperView.swift
//  SimpleScorerv01
//
//  Created by Dev on 14/11/22.
//  Copyright © 2022 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct TopSwiperView: View {

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var displayInfo : GlobalDisplayInfo
    @EnvironmentObject var game : Game
    
    @Binding var dragOffset : CGSize
    @Binding var showPlayerEntry : Bool
    
    @GestureState var dragUpdate = CGSize.zero
    
    var body: some View {
        GeometryReader { geo in
            HStack{
                Color.clear
                    .frame(width: 25)
                  .contentShape(Rectangle())
                Spacer()
                if colorScheme == .dark {
                    Color.midnightBlue.opacity(0.025)
                        .frame(width: 25)
                      .contentShape(Rectangle())
                } else {
                    Color.offWhite.opacity(0.025)
                        .frame(width: 25)
                      .contentShape(Rectangle())
                }
                
            }
            .ignoresSafeArea()
            
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .updating($dragUpdate) { value, state, transaction in
                        state.width = value.translation.width
                    }
                    .onEnded({ (value) in
                        if value.startLocation.x > (geo.size.width - 25) && self.displayInfo.screenDisplayed != .gameSetup {
                            withAnimation{
                                self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue + 1)!
                            }
                        } else if value.startLocation.x < 25 && self.displayInfo.screenDisplayed != .allScores {
                            if game.needsNameEntry() {
                                withAnimation{
                                    self.showPlayerEntry = true
                                }
                                self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue - 1)!
                            } else {
                                withAnimation{
                                    self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue - 1)!
                                }
                            }
                        } else {
                            
                        }
                    })
            )
        }
    }
}

struct TopSwiperView_Previews: PreviewProvider {
    static var previews: some View {
        TopSwiperView(dragOffset: .constant(CGSize.zero), showPlayerEntry: .constant(false))
    }
}
