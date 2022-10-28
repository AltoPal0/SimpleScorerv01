//
//  KeyPadView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 10/27/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct KeyPadButton: View {
    var key: String

    var body: some View {
        Button(action: { self.action(self.key) }) {
            if key == "＋∕−" || key == "⌫" {
                Text(key).foregroundColor(.purpleStart).fontWeight(.light)
            } else {
                Text(key).foregroundColor(.purpleStart).fontWeight(.heavy)
            }
        }.buttonStyle(SimpleRectButtonStyle())
    }

    enum ActionKey: EnvironmentKey {
        static var defaultValue: (String) -> Void { { _ in } }
    }

    @Environment(\.keyPadButtonAction) var action: (String) -> Void
}

extension EnvironmentValues {
    var keyPadButtonAction: (String) -> Void {
        get { self[KeyPadButton.ActionKey.self] }
        set { self[KeyPadButton.ActionKey.self] = newValue }
    }
}

struct KeyPadRow: View {
    var keys: [String]

    var body: some View {
        HStack (spacing:0)  {
            ForEach(keys, id: \.self) { key in
                KeyPadButton(key: key)
            }
        }
    }
}

struct KeyPadView: View {
    @Binding var valueDisplayed: CGFloat
    @Binding var sign : CGFloat
    

    var body: some View {
        VStack (spacing:0) {
            KeyPadRow(keys: ["1", "2", "3"])
            KeyPadRow(keys: ["4", "5", "6"])
            KeyPadRow(keys: ["7", "8", "9"])
            KeyPadRow(keys: ["＋∕−", "0", "⌫"])
        }.environment(\.keyPadButtonAction, self.keyWasPressed(_:))
    }

    private func keyWasPressed(_ key: String) {
        switch key {
            
        case "＋∕−" :
            sign = -sign
            
        case "⌫" :
            valueDisplayed = (valueDisplayed / 10).rounded(.towardZero)
            
        case "0" where valueDisplayed == 0 :
            break
            
        case "0" :
            valueDisplayed = valueDisplayed * 10 + 0
            
        case "1" :
            valueDisplayed = valueDisplayed * 10 + 1
        
        case "2" :
            valueDisplayed = valueDisplayed * 10 + 2
        
        case "3" :
            valueDisplayed = valueDisplayed * 10 + 3
        
        case "4" :
            valueDisplayed = valueDisplayed * 10 + 4
        
        case "5" :
            valueDisplayed = valueDisplayed * 10 + 5
        
        case "6" :
            valueDisplayed = valueDisplayed * 10 + 6
        
        case "7" :
            valueDisplayed = valueDisplayed * 10 + 7
        
        case "8" :
            valueDisplayed = valueDisplayed * 10 + 8
        
        case "9" :
            valueDisplayed = valueDisplayed * 10 + 9
        
        default : valueDisplayed = CGFloat(0)

        }
    }
    
    
}

struct ContentView_keypad : View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(String(format: "%.0f",value))
            }.padding([.leading, .trailing])
            Divider()
            KeyPadView(valueDisplayed: $value,sign: $sign)
        }
        .font(.largeTitle)
            .padding()
    }

    @State private var value = CGFloat(0)
    @State private var sign = CGFloat(1)

}



struct ContentView_keypad_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            ContentView_keypad().frame(width: 300, height: 200)
        }
    }
}



