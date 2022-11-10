//
//  Constants.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 4/27/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

enum CardSize {
    case
    tiny ,
    compact ,
    normal
}

enum ScreenType : Int, Comparable {
    case
    allScores = 0,
    scoreCards = 1,
    gameSetup = 2
    
    public static func < (a: ScreenType, b: ScreenType) -> Bool {
        return a.rawValue < b.rawValue
    }
    
    public static func > (a: ScreenType, b: ScreenType) -> Bool {
        return a.rawValue > b.rawValue
    }
    
    public static func - (a: ScreenType, b: ScreenType) -> Int {
        return a.rawValue - b.rawValue
    }
}



let gradiants =
    [LinearGradient(Color(hex: 0xf4c4f3),Color(hex: 0xfc67fa)),
    LinearGradient(Color(hex: 0x7f7fd5),Color(hex: 0x86a8e7),Color(hex: 0x91eae4)),
    LinearGradient(Color(hex: 0xa770ef),Color(hex: 0xcf8bf3),Color(hex: 0xfdb99b)),
    LinearGradient(Color(hex: 0x3a7bd5),Color(hex: 0x3a6073)),
    LinearGradient(Color(hex: 0x43cea2),Color(hex: 0x185a9d)),
    LinearGradient(Color(hex: 0x4568DC),Color(hex: 0xB06AB3)),
    LinearGradient(Color(hex: 0x2193b0),Color(hex: 0x6dd5ed)),
    LinearGradient(Color(hex: 0x00b09b),Color(hex: 0x96c93d)),
    LinearGradient(Color(hex: 0xfeac5e),Color(hex: 0xc779d0),Color(hex: 0x4bc0c8)),
    LinearGradient(Color(hex: 0xf09819),Color(hex: 0xedde5d)),
    LinearGradient(Color(hex: 0xf79d00),Color(hex: 0x64f38c)),
    LinearGradient(Color(hex: 0xef32d9),Color(hex: 0x89fffd)),
        
    LinearGradient(Color(hex: 0xf12711),Color(hex: 0xf5af19)),
    LinearGradient(Color(hex: 0xbc4e9c),Color(hex: 0xf80759)),
//    LinearGradient(Color(hex: 0x1E9600),Color(hex: 0xFFF200),Color(hex: 0xFF0000)),
    LinearGradient(Color(hex: 0xFDC830),Color(hex: 0xF37335)),
    LinearGradient(Color(hex: 0xf79d00),Color(hex: 0x64f38c)),
    LinearGradient(Color(hex: 0xEECDA3),Color(hex: 0xEF629F)),
    LinearGradient(Color(hex: 0xfe8c00),Color(hex: 0xf83600)),
    LinearGradient(Color(hex: 0xd53369),Color(hex: 0xcbad6d)),
    LinearGradient(Color(hex: 0x16A085),Color(hex: 0xF4D03F))]

func randomGrad() -> LinearGradient {
    
    let color1 = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    let color2 = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    let color3 = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    return  LinearGradient(gradient: Gradient(colors: [color1,color2,color3]), startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Color {
    
    static let purpleStart = Color(red: 84 / 255, green: 124 / 255, blue: 246 / 255)
    static let purpleEnd = Color(red: 125 / 255, green: 84 / 255, blue: 245 / 255)
        
    static let orangeStart = Color(red: 242 / 255, green: 169 / 255, blue: 100 / 255)
    static let orangeEnd = Color(red: 233 / 255, green: 107 / 255, blue: 157 / 255)
    
    static let blueStart = Color(red: 83 / 255, green: 181 / 255, blue: 242 / 255)
    static let blueEnd = Color(red: 85 / 255, green: 159 / 255, blue: 245 / 255)
    
    static let cyan1 = Color(red: 2 / 255, green: 170 / 255, blue: 176 / 255)
    static let cyan2 = Color(red: 0 / 255, green: 205 / 255, blue: 172 / 255)

    static let offWhite = Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255)
    static let midnightBlue = Color(red: 44 / 255, green: 62 / 255, blue: 80 / 255)
    
    static let offRed = Color(red: 235 / 255, green: 55 / 255, blue: 55 / 255)
    static let offGray = Color(red: 82 / 255, green: 82 / 255, blue: 82 / 255)
    
    static let neon = Color(red: 77 / 255, green: 238 / 255, blue: 234 / 255)

}

extension LinearGradient {
    
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static let gradDefault = LinearGradient(Color(hex: 0x283048),Color(hex: 0x859398))

}

extension Color {

    init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(UIColor(red: components.R, green: components.G, blue: components.B, alpha: 1))
    }

}





