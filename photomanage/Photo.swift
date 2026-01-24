import Foundation
import SwiftUI
import Photos

struct Photo: Identifiable, Equatable {
    let id = UUID()
    // We keep imageURL for fallback or mixed usage, but primarily we use asset now
    let imageURL: URL?
    let asset: PHAsset?
    let creationDate: Date
    var isFavorite: Bool = false
    let color: Color
    
    // Initializer for mock data
    init(imageURL: URL, color: Color) {
        self.imageURL = imageURL
        self.asset = nil
        self.creationDate = Date() // Mock: Just use now
        self.color = color
    }
    
    // Initializer for Real Photo Library data
    init(asset: PHAsset, color: Color = .gray) {
        self.imageURL = nil
        self.asset = asset
        self.creationDate = asset.creationDate ?? Date()
        self.color = color
    }
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }
}

struct PhotoGroup: Identifiable {
    let id = UUID()
    var title: String
    var photos: [Photo]
}
