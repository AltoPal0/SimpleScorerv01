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
    @Binding var orderByScores : Bool
    
    @GestureState var dragUpdate = CGSize.zero
    
    var body: some View {
        GeometryReader { geo in
            
            let swipeAreaSides = geo.size.width * 0.05
            VStack (spacing: 0){
                Color.clear
                    .frame(height: swipeAreaSides)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(coordinateSpace: .local)
//                            .updating($dragUpdate) { value, state, transaction in
//                                state.height = value.translation.height
//                            }
                            .onEnded({ (value) in
                                if value.startLocation.y < (swipeAreaSides) && self.displayInfo.screenDisplayed == .scoreCards {
                                    withAnimation{
                                        self.orderByScores.toggle()
                                    }
                                } 
                            })
                    )
                HStack{
                    Color.clear
                        .frame(width: swipeAreaSides)
                        .contentShape(Rectangle())
                    Spacer()
                    if colorScheme == .dark {
                        Color.midnightBlue.opacity(0.025)
                            .frame(width: swipeAreaSides )
                            .contentShape(Rectangle())
                    } else {
                        Color.offWhite.opacity(0.025)
                            .frame(width: swipeAreaSides)
                            .contentShape(Rectangle())
                    }
                    
                }
                .gesture(
                    DragGesture(coordinateSpace: .local)
                        .updating($dragUpdate) { value, state, transaction in
                            state.width = value.translation.width
                        }
                        .onEnded({ (value) in
                            if value.startLocation.x > (geo.size.width - swipeAreaSides) && self.displayInfo.screenDisplayed != .gameSetup {
                                withAnimation{
                                    self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue + 1)!
                                }
                            } else if value.startLocation.x < swipeAreaSides && self.displayInfo.screenDisplayed != .allScores {
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
                            }
                        })
                )
            }
            .ignoresSafeArea()
            
            
        }
    }
}

struct TopSwiperView_Previews: PreviewProvider {
    static var previews: some View {
        TopSwiperView(dragOffset: .constant(CGSize.zero), showPlayerEntry: .constant(false), orderByScores: .constant(false))
    }
}
