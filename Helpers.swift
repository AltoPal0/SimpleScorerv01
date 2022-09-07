//
//  Helpers.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 5/1/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct BindingProvider<StateT, Content: View>: View {

    @State private var state: StateT
    private var content: (_ binding: Binding<StateT>) -> Content

    init(_ initialState: StateT, @ViewBuilder content: @escaping (_ binding: Binding<StateT>) -> Content) {
        self.content = content
        self._state = State(initialValue: initialState)
    }

    var body: some View {
        self.content($state)
    }
}

func fontSize(nbrChar :Int, fontSize :Int) -> CGFloat {
    
    if nbrChar <= 5 { return CGFloat(fontSize)}
    
    return CGFloat(fontSize - (nbrChar-5)*7 )
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

// MARK: - TextField



// TextField responder

//struct TextFieldTyped: UIViewRepresentable {
//    let keyboardType: UIKeyboardType
//    let returnVal: UIReturnKeyType
//    let tag: Int
//    @Binding var text: String
//    @Binding var isfocusAble: [Bool]
//
//    func makeUIView(context: Context) -> UITextField {
//        let textField = UITextField(frame: .zero)
//        textField.keyboardType = self.keyboardType
//        textField.returnKeyType = self.returnVal
//        textField.tag = self.tag
//        textField.delegate = context.coordinator
//        textField.autocorrectionType = .no
//
//        return textField
//    }
//
//    func updateUIView(_ uiView: UITextField, context: Context) {
//        if isfocusAble[tag] {
//            uiView.becomeFirstResponder()
//        } else {
//            uiView.resignFirstResponder()
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, UITextFieldDelegate {
//        var parent: TextFieldTyped
//
//        init(_ textField: TextFieldTyped) {
//            self.parent = textField
//        }
//
//        func updatefocus(textfield: UITextField) {
//            textfield.becomeFirstResponder()
//        }
//
//func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//
//            if parent.tag == 0 {
//                parent.isfocusAble = [false, true]
//                parent.text = textField.text ?? ""
//            } else if parent.tag == 1 {
//                parent.isfocusAble = [false, false]
//                parent.text = textField.text ?? ""
//         }
//        return true
//        }
//
//    }
//}

// MARK: - Keyb slide

// Keyboard slide
// Courtesy of https://stackoverflow.com/questions/56491881/move-textfield-up-when-thekeyboard-has-appeared-by-using-swiftui-ios
//struct GeometryGetter: View {
//    @Binding var rect: CGRect
//
//    var body: some View {
//        GeometryReader { geometry in
//            Group { () -> AnyView in
//                // void the possibility of modifying the state of the view while it is being rendered
//                DispatchQueue.main.async {
//                    self.rect = geometry.frame(in: .global)
//                }
//
//                return AnyView(Color.clear)
//            }
//        }
//    }
//}

// MARK: - Views / Images

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension CGRect {
    var uiImage: UIImage? {
        UIApplication.shared.windows
            .filter{ $0.isKeyWindow }
            .first?.rootViewController?.view
            .asImage(rect: self)
    }
}

extension View {
    func getRect(_ rect: Binding<CGRect>) -> some View {
        self.modifier(GetRect(rect: rect))
    }
}

struct GetRect: ViewModifier {

    @Binding var rect: CGRect

    var measureRect: some View {
        GeometryReader { proxy in
            Rectangle().fill(Color.clear)
                .preference(key: RectPreferenceKey.self, value:  proxy.frame(in: .global))
        }
    }

    func body(content: Content) -> some View {
        content
            .background(measureRect)
            .onPreferenceChange(RectPreferenceKey.self) { (rect) in
                if let rect = rect {
                    self.rect = rect
                }
            }
    }
}


extension GetRect {
    struct RectPreferenceKey: PreferenceKey {
        static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
            value = nextValue()
        }

        typealias Value = CGRect?

        static var defaultValue: CGRect? = nil
    }
}

extension UIImage {
    var isPortrait:  Bool    { size.height > size.width }
    var isLandscape: Bool    { size.width > size.height }
    var breadth:     CGFloat { min(size.width, size.height) }
    var breadthSize: CGSize  { .init(width: breadth, height: breadth) }
    
    func squared(isOpaque: Bool = false) -> UIImage? {

        guard let cgImage = cgImage?

            .cropping(to: CGRect(x: isLandscape ? -((size.height-size.width)/2).rounded(.down) : 0,
                                 y: isPortrait ? -((size.width-size.height)/2).rounded(.down): 0,
                                 width: breadthSize.width,
                                 height: breadthSize.height)) else {return nil}
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: breadthSize, format: format).image { _ in
            UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation)
            .draw(in: .init(origin: .zero, size: breadthSize))
        }
    }
}

extension UIView {
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension UIImage {
    var fixedOrientation: UIImage {
        guard imageOrientation != .up else { return self }

        var transform: CGAffineTransform = .identity
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform
                .translatedBy(x: size.width, y: size.height).rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform
                .translatedBy(x: size.width, y: 0).rotated(by: .pi)
        case .right, .rightMirrored:
            transform = transform
                .translatedBy(x: 0, y: size.height).rotated(by: -.pi/2)
        case .upMirrored:
            transform = transform
                .translatedBy(x: size.width, y: 0).scaledBy(x: -1, y: 1)
        default:
            break
        }

        guard
            let cgImage = cgImage,
            let colorSpace = cgImage.colorSpace,
            let context = CGContext(
                data: nil, width: Int(size.width), height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
                space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue
            )
        else { return self }
        context.concatenate(transform)

        var rect: CGRect
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            rect = CGRect(x: 0, y: 0, width: size.height, height: size.width)
        default:
            rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }

        context.draw(cgImage, in: rect)
        return context.makeImage().map { UIImage(cgImage: $0) } ?? self
    }
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size

    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }

    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!
}

// MARK: - shapes

struct EdgeBorder: Shape {
    
    var width: CGFloat
    var edge: Edge
    
    func path(in rect: CGRect) -> Path {
        var x: CGFloat {
            switch edge {
            case .top, .bottom, .leading: return rect.minX
            case .trailing: return rect.maxX - width
            }
        }
        
        var y: CGFloat {
            switch edge {
            case .top, .leading, .trailing: return rect.minY
            case .bottom: return rect.maxY - width
            }
        }
        
        var w: CGFloat {
            switch edge {
            case .top, .bottom: return rect.width
            case .leading, .trailing: return self.width
            }
        }
        
        var h: CGFloat {
            switch edge {
            case .top, .bottom: return self.width
            case .leading, .trailing: return rect.height
            }
        }
        
        return Path( CGRect(x: x, y: y, width: w, height: h) )
    }
}

extension View {
    func border(width: CGFloat, edge: Edge, color: Color) -> some View {
        ZStack {
            self
            EdgeBorder(width: width, edge: edge).foregroundColor(color)
        }
    }
}

struct SimpleRectButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth:.infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .border(Color.offWhite, width: 1)
            .background(
                Group {
                    if configuration.isPressed {
                        Rectangle()
                            .fill(Color.gray)
                    } else {
                        Rectangle()
                            .fill(Color.white)
                    }
                }
        )
    }
}
