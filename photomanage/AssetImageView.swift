import SwiftUI
import Photos

struct AssetImageView: View {
    let asset: PHAsset?
    let imageURL: URL?
    // Placeholder color
    let color: Color
    
    @State private var image: Image?
    @Environment(\.displayScale) private var displayScale
    
    var body: some View {
        GeometryReader { proxy in
            if let image = image {
                image
                     .resizable()
                     .aspectRatio(contentMode: .fill)
                     .frame(width: proxy.size.width, height: proxy.size.height)
                     .clipped()
            } else if let asset = asset {
                // Loading state or color
                ZStack {
                    color
                    ProgressView()
                }
                .task {
                    await loadImage(asset: asset, size: proxy.size, scale: displayScale)
                }
            } else if let url = imageURL {
// ...
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        color
                    }
                }
            } else {
                color
            }
        }
    }
    
    private func loadImage(asset: PHAsset, size: CGSize, scale: CGFloat) async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, info in
            if let result = result {
                self.image = Image(uiImage: result)
            }
        }
    }
}
