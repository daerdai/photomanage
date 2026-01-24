import SwiftUI

struct CardView: View {
    let photo: Photo
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                // Image Layer
                AsyncImage(url: photo.imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        ZStack {
                            photo.color
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        }
                    } else {
                        ZStack {
                            photo.color
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                
                // Gradient Overlay for text visibility
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                // Favorite Indicator
                if photo.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 32))
                        .padding()
                        .shadow(radius: 4)
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 8, x: 0, y: 4)
        }
    }
}
