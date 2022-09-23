//
//  ImagePickerView.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 5/4/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI
import Combine

struct CircleImagePickerView: View {
    
    @Binding var isPresented : Bool
    @Binding var selectedImage: UIImage
    var source : UIImagePickerController.SourceType
    
    @State private var showPicker = true
    
    var body: some View {
        Group {
            if selectedImage == UIImage() && self.showPicker {
                ImagePickerView(isPresented: self.$showPicker, selectedImage: self.$selectedImage, source: self.source)
            } else {
                ZStack {
                    GeometryReader { geo in
                    ImageResizerView(isPresented:self.$isPresented, image: self.$selectedImage)
                    .overlay(
                        Rectangle()
                            .fill(Color.black)
                            .mask(self.HoleShapeMask(in: geo.frame(in: .local)).fill(style: FillStyle(eoFill: true)))
                            .opacity(0.5)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                        )
                    }
                }
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
            }
        }
        
        
    }
    
    func HoleShapeMask(in rect: CGRect) -> Path {
        var shape = Rectangle().path(in: rect)
        shape.addPath(Circle().path(in: rect))
        return shape
    }
    
}

struct ImageResizerView: View {
    
    @Binding var isPresented: Bool
    @Binding var image: UIImage
    
    let minScale: CGFloat = 1.0
    
    @State var lastValue: CGFloat = 1.0
    @State var scale: CGFloat = 1.0
    @State var draged: CGSize = .zero
    @State var prevDraged: CGSize = .zero
    @State var tapPoint: CGPoint = .zero
    @State var isTapped: Bool = false
    
    @State private var rectToCapture: CGRect = .zero
    
    let rect = CGRect(x: 0, y: 0, width: 300, height: 100)
    
    var body: some View {
        
        let maxScale = image.imageAsset != nil ? self.image.size.width / UIScreen.main.bounds.size.width : 1.0
            
            let magnify = MagnificationGesture(minimumScaleDelta: 0.2)
                .onChanged { value in
                    let resolvedDelta = value / self.lastValue
                    self.lastValue = value
                    let newScale = self.scale * resolvedDelta
                    self.scale = min(maxScale, max(self.minScale, newScale))
                    
                    print("delta=\(value) resolvedDelta=\(resolvedDelta)  newScale=\(newScale)")
            }
            
            let gestureDrag = DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { (value) in
                    self.tapPoint = value.startLocation
                    self.draged = CGSize(width: value.translation.width + self.prevDraged.width,
                                         height: value.translation.height + self.prevDraged.height)
            }
            
        return GeometryReader { geo in
            ZStack {
                Image(uiImage: self.image.fixedOrientation)
                    .resizable()
                    .scaledToFit()
//                    .animation(.default)
                    .offset(self.draged)
                    .scaleEffect(self.scale)
                    .gesture(
                        TapGesture(count: 2).onEnded({
                            self.isTapped.toggle()
                            if self.scale > 1 {
                                self.scale = 1
                            } else {
                                self.scale = maxScale
                            }
                            let parent = geo.frame(in: .local)
                            self.postArranging(translation: CGSize.zero, in: parent)
                        })
                            .simultaneously(with: gestureDrag.onEnded({ (value) in
                                let parent = geo.frame(in: .local)
                                self.postArranging(translation: value.translation, in: parent)
                            })
                    ))
                    .gesture(magnify.onEnded { value in
                        // without this the next gesture will be broken
                        self.lastValue = 1.0
                        let parent = geo.frame(in: .local)
                        self.postArranging(translation: CGSize.zero, in: parent)
                    })
//                    .animation(.spring())
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
//                            self.image = resizeImage(image: self.rectToCapture.uiImage!, targetSize: CGSize(width: 200, height: 200))
                            self.isPresented = false
                        }) {
                            Image(systemName: "checkmark")
                            .font(.system(size: 30, weight: .light, design: .default))
                            .foregroundColor(Color.white)
                            .padding()
                            .contentShape(Circle())
                            //                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                            .padding()
                        }
                    }.padding()
                    
                }
            }.getRect(self.$rectToCapture)
        }
        
        
        
    }
        
    private func postArranging(translation: CGSize, in parent: CGRect) {
        let scaled = self.scale
        let parentWidth = parent.maxX
        let parentHeight = parent.maxY
        let offset = CGSize(width: (parentWidth * scaled - parentWidth) / 2,
                            height: (parentHeight * scaled - parentHeight) / 2)
        var resolved = CGSize()
        let newDraged = CGSize(width: self.draged.width * scaled,
                               height: self.draged.height * scaled)
        if newDraged.width > offset.width {
            resolved.width = offset.width / scaled
        } else if newDraged.width < -offset.width {
            resolved.width = -offset.width / scaled
        } else {
            resolved.width = translation.width + self.prevDraged.width
        }
        if newDraged.height > offset.height {
            resolved.height = offset.height / scaled
        } else if newDraged.height < -offset.height {
            resolved.height = -offset.height / scaled
        } else {
            resolved.height = translation.height + self.prevDraged.height
        }
        self.draged = resolved
        self.prevDraged = resolved
    }
    
    
}

struct ImagePickerView: UIViewControllerRepresentable {
    
    @Binding var isPresented : Bool
    @Binding var selectedImage: UIImage
    var source : UIImagePickerController.SourceType
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIViewController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.allowsEditing = false
        controller.sourceType = self.source
        //        controller.cameraOverlayView = UIView(frame: (controller.cameraOverlayView?.frame)!)
        //        controller.cameraOverlayView!.backgroundColor = UIColor.red
        
        return controller
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        init(parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let selectedImageFromPicker = info[.originalImage] as? UIImage {
                self.parent.selectedImage = selectedImageFromPicker
            }
            self.parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            self.parent.isPresented = false
        }
        
        
    }
    
    
    func updateUIViewController(_ uiViewController: ImagePickerView.UIViewControllerType, context: UIViewControllerRepresentableContext<ImagePickerView>) {
    }
}


//extension UIImagePickerController {
//    override open var shouldAutorotate: Bool {
//        return false
//    }
//}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
//        BindingProvider(UIImage()) { binding in
//           CircleImagePickerView(isPresented: .constant(true), selectedImage: binding, source: .photoLibrary)
//        }
        
        
        CircleImagePickerView(isPresented: .constant(false), selectedImage: .constant(UIImage(named: "utah")!), source: .photoLibrary)
    }
}



