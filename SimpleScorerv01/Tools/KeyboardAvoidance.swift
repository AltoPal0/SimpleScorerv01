//
//  KeyboardAvoidance.swift
//  SimpleScorerv01
//
//  Created by Vadim Bulavin
//


// --------------------------------------------------
// From https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
// --------------------------------------------------

import Foundation
import SwiftUI
import Combine
import UIKit

//// Propagating Keyboard Height Changes
//extension Publishers {
//    static var keyboardSize: AnyPublisher<CGRect, Never> {
//        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
//            .map { $0.keyboardSize }
//        
//        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
//            .map { _ in CGRect() }
//        
//        let didHide = NotificationCenter.default.publisher(for: UIApplication.keyboardDidHideNotification)
//            .map { $0.keyboardSize }
//        
//        return MergeMany(willShow, willHide,didHide)
//            .eraseToAnyPublisher()
//    }
//}
//
//extension Notification {
//    var keyboardSize: CGRect {
//        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? CGRect()
//    }
//}
//
//
//// Extracting Keyboard Avoidance Behavior into SwiftUI ViewModifier
//struct KeyboardAdaptive: ViewModifier {
//    
//    @State private var offset: CGFloat = 0
//    
//    func body(content: Content) -> some View {
//
////        GeometryReader { geometry in
//            content
//                .offset(x: 0, y: -self.offset)
//                
//                .onReceive(Publishers.keyboardSize) { keyboardSize in
//                
//
////                    let keyboardTop = geometry.frame(in: .global).height - keyboardSize.height
////                    let keyboardBottom = UIScreen.main.bounds.height - keyboardSize.maxY
//                    
//                    var screenOrientation: UIInterfaceOrientation? {
//                        get {
//                            guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
//                                #if DEBUG
//                                fatalError("Could not obtain UIInterfaceOrientation from a valid windowScene")
//                                #else
//                                return nil
//                                #endif
//                            }
//                            return orientation
//                        }
//                    }
//                    
//                    let screenHeight = UIScreen.main.bounds.height
//                    
//                    let keyboardTop = screenHeight - keyboardSize.height - 20 // I prefer the textfield slightly above
//                    
//                    let focusedTextInputBottom = UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0
//                    
//                    // This is a tricky part. When focusing from one textfield to the other, the offset wont reset between focuses
//                    // This will create a lack of offset in the calculation
//                    // For exemple, if previous offset was 110, when looking at Global.frame.maxY it will find a value offset by 110
//                    // to avoid, we detect if there is a first responder after keybard resigned (added the notification)
//                    // If not, we set offset to 0
//                    
//                    // Ideally, who want to keep keyboard up between field focuses but I don't see how to do it ... yet
//                    if UIResponder.currentFirstResponder != nil {
//                        self.offset = max(0, focusedTextInputBottom - keyboardTop ) + self.offset
//                    } else {
//                        self.offset = 0
//                    }
//                    
//            }
//            .animation(.easeOut(duration: 0.16))
////        }
//    }
//}
//
//extension View {
//    func keyboardAdaptive() -> some View {
//        ModifiedContent(content: self, modifier: KeyboardAdaptive())
//    }
//}
//
//
//// Avoiding Over-scroll
//extension UIResponder {
//    static var currentFirstResponder: UIResponder? {
//        _currentFirstResponder = nil
//        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
//        return _currentFirstResponder
//    }
//
//    private static weak var _currentFirstResponder: UIResponder?
//
//    @objc private func findFirstResponder(_ sender: Any) {
//        UIResponder._currentFirstResponder = self
//    }
//    
//    var globalFrame: CGRect? {
//        guard let view = self as? UIView else { return nil }
//        return view.superview?.convert(view.frame, to: nil)
//    }
//}

//struct ContentView_AK: View {
//    @State private var text = ""
//    @State private var keyboardHeight: CGFloat = 0
//
//    var body: some View {
//        VStack {
//            Spacer()
//
//            TextField("Enter something", text: $text)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//        }.keyboardAdaptive()
////        .padding()
////        .padding(.bottom, keyboardHeight)
////        .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
//    }
//}
//
//struct ContentView_AK_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView_AK()
//    }
//}
