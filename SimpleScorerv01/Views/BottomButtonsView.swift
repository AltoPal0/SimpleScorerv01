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
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                if !(self.displayInfo.screenDisplayed == .allScores) {
                Image(systemName: "arrow.left.circle")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(Color.gray)
                    .background(Color.clear.opacity(0))
                    .onTapGesture {
                        if self.displayInfo.screenDisplayed == .gameSetup {
                            self.displayInfo.screenDisplayed = .scoreCards
                        } else {
//                            self.displayInfo.screenDisplayed = ScreenType(rawValue: self.displayInfo.screenDisplayed.rawValue - 1)!
                            self.displayInfo.screenDisplayed = .allScores
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
                    .background(Color.clear.opacity(0))
                    .onTapGesture {
                        if self.displayInfo.screenDisplayed == .allScores {
                            self.displayInfo.screenDisplayed = .scoreCards
                        } else {
                            self.displayInfo.screenDisplayed = .gameSetup
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
        BottomButtonsView()
    }
}
