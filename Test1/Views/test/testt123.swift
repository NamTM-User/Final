import SwiftUI

struct testt123: View {
    @State private var renderedImage: UIImage? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .border(Color.gray)
            } else {
                Text("Chưa render ảnh")
                    .foregroundColor(.gray)
            }
            
            Button("Render Ảnh") {
                renderedImage = drawFiveImages()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    testt123()
}
