//
//  CircleImage.swift
//  SimpleScorerv01
//
//  Created by Stephane Giloppe on 3/16/20.
//  Copyright © 2020 Stephane Giloppe. All rights reserved.
//

import SwiftUI

struct AvatarView: View {
    
    @EnvironmentObject var game : Game
    
    var user : Player
    
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? 
//    @State private var pickedImage: UIImage?
    
    @ViewBuilder
    var body: some View {
        
        ZStack(alignment: .center) {
            if user.photoImage?.imageAsset != nil {
                Image(uiImage: resizeImage(image: user.photoImage!.fixedOrientation.squared()!, targetSize: CGSize(width: 200, height: 200)))
                .resizable()
                .scaledToFit()
            } else if user.name != Player.defaultName {
                Text(user.initials)
                    .fontWeight(.regular)
                    .font(.system(.largeTitle, design: .rounded))
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(10)
            } else {
                Image(systemName: "keyboard")
                    .font(.system(size: 30, weight: .light, design: .default))
                    .foregroundColor(Color.white)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Circle())
                    .opacity(0.5)
            }
        }
        .clipShape(Circle())
        .aspectRatio(1, contentMode: .fit)
        .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
//        .onTapGesture {
//                self.showingImagePicker = true
//        }.sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
//            ImagePicker(image: self.$inputImage)
//        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
//        self.user.photoImage = resizeImage(image: inputImage.fixedOrientation.squared()!, targetSize: CGSize(width: 200, height: 200))
        let index = self.game.indexOf(player: user)!
        self.game.playerScores[index].player.photoImage = inputImage
        self.inputImage = inputImage
    }
}



struct CircleImage_Previews: PreviewProvider {
    static var previews: some View {
        
        Group {
            AvatarView(user: Player(name: "Stephane", initials: "St", photoImage: UIImage(named: "vertical"), gradientIndex: 0))
                .background(Color.orangeEnd)
                .previewLayout(.fixed(width: 50, height: 50))
            
            AvatarView(user: Player(name: "Stephane", initials: "St", photoImage: UIImage(named: "steph-test"), gradientIndex: 0))
            .background(Color.orangeEnd)
            .previewLayout(.fixed(width: 200, height: 300))
            
            AvatarView(user: Player(name: "Karim", initials: "Wm", gradientIndex: 0))    
            .background(Color.orangeEnd)
            .previewLayout(.fixed(width: 40, height: 40))
            
            
            AvatarView(user: Player())
            .background(Color.orangeEnd)
            .previewLayout(.fixed(width: 200, height: 300))
        }
        
        
    }
}

// Temp while imagepicker is not great

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }
    
   func makeCoordinator() -> Coordinator {
          Coordinator(self)
      }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


