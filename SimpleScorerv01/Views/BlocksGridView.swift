import SwiftUI

struct BlocksGridView: View {
    
    private var gridItemLayout = [GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 20)]
    
    
    var body: some View {
        ZStack{
            ScrollView {
                ScrollViewReader { value in
                    LazyVGrid(columns: gridItemLayout, spacing: 20) {
                        ForEach((0..<20), id: \.self) {
                            BlockView(cardID: $0,scrollReader: value).id($0)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

struct BlockView : View {
    
    var cardID : Int
    var scrollReader : ScrollViewProxy
    
    @State private var isOverflowingScreen = false
    @State private var expand = false
    
    var body: some View {
        ZStack{
            Rectangle()
                .foregroundColor(isOverflowingScreen ? Color.blue : Color.green)
                .frame(height: expand ? 300 : 135)
                .clipShape(Rectangle()).cornerRadius(14)
                .overlay(Text(cardID.description).font(Font.system(size: 100, weight: .semibold, design: .rounded)).scaledToFit())
                .background(GeometryReader { geo -> Color in
                    DispatchQueue.main.async {
                        if geo.frame(in: .global).maxY > UIScreen.main.bounds.maxY {
                            isOverflowingScreen = true
                        } else {
                            isOverflowingScreen = false
                        }
                    }
                    return Color.clear
                })
                .onTapGesture {
                    expand.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // <-- Hack :(
                        if isOverflowingScreen {
                            withAnimation{
                                scrollReader.scrollTo(cardID)
                            }
                        }
                    }
                }
        }
    }
}


struct BlocksGridView_Previews: PreviewProvider {
    static var previews: some View {
        BlocksGridView()
    }
}

