//
//  Player.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 3/16/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import Combine

struct Player: Identifiable {
    
    var id = UUID()
    var name : String
    var initials : String
//    var photoURL: String?
    var photoImage: UIImage?
    // Index in the gradiants palette : unlike the gradient itself, it can be saved in the history
    var gradientIndex: Int?
    
    var colorGradient: LinearGradient {
        Player.gradient(at: gradientIndex)
    }
    
    static func gradient(at index: Int?) -> LinearGradient {
        guard let index = index, gradiants.indices.contains(index) else { return LinearGradient.gradDefault }
        return gradiants[index]
    }
}

extension Player {
    
    static let defaultName = "New Player"
    
    init() {
        self.name = Player.defaultName
        self.initials = ""
    }
    
    
}
