import SwiftUI

struct BrowsingView: View {
    @Binding var group: PhotoGroup
    @ObservedObject var manager: PhotoManager
    @Environment(\.presentationMode) var presentationMode
    
    // Track the offset of the top card
    @State private var offset = CGSize.zero
    
    // For gesture interaction indicators
    @State private var isDragging: Bool = false
    @State private var showDeletionSummary: Bool = false
    
    var body: some View {
        ZStack {
            // Background - Dark Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1c2538"), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Header Bar
                HStack {
                    Button(action: {
                        if !manager.pendingDeletionPhotos.isEmpty {
                            showDeletionSummary = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.8)) // Matching the screenshot blue circle
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Progress Indicator (Capsule)
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 4)
                        .overlay(
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 10)
                                .offset(x: -10) // Mock progress
                        )
                    
                    Spacer()
                    
                    Button(action: {
                        // Action for share/more
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Card Stack Area
                ZStack {
                    if group.photos.isEmpty {
                        EmptyStateView()
                    } else {
                        // Show top 3 cards
                        ForEach(Array(group.photos.prefix(3).reversed()), id: \.id) { photo in
                            let isTop = group.photos.first?.id == photo.id
                            BrowsingCardView(photo: photo)
                                .overlay(
                                    // Status Indicators Overlay on top of the card
                                    GestureOverlay(offset: offset, isTop: isTop)
                                )
                                .offset(isTop ? offset : .zero)
                                .scaleEffect(isTop ? 1.0 : 0.95)
                                .rotationEffect(isTop ? .degrees(Double(offset.width / 20)) : .zero)
                                .opacity(isTop ? 1.0 : 0.5) // Fade background cards
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: offset)
                                .gesture(
                                    isTop ? DragGesture()
                                        .onChanged { gesture in
                                            offset = gesture.translation
                                            isDragging = true
                                        }
                                        .onEnded { gesture in
                                            isDragging = false
                                            handleSwipe(translation: gesture.translation, photo: photo)
                                        } : nil
                                )
                                .allowsHitTesting(isTop)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.vertical, 20)
                
                Spacer()
                
                // Bottom Toolbar
                HStack(spacing: 20) {
                    // Like Button
                    Button(action: {
                         if let topPhoto = group.photos.first {
                             swipeAndFavorite(photo: topPhoto)
                         }
                    }) {
                        Image(systemName: "heart")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Info Pill
                    HStack {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                        
                        Spacer()
                        
                        if let topPhoto = group.photos.first {
                            Text(timeAgoDisplay(date: topPhoto.creationDate))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            Text("No Photos")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    
                    // Undo/Back Button
                    Button(action: {
                        withAnimation {
                            manager.rotatePhotoBackwards(in: group.id)
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.05)) // Slightly darker than active
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .fullScreenCover(isPresented: $showDeletionSummary, onDismiss: {
            // Check if we should dismiss the browsing view too?
            // If deletions were confirmed (pending is empty), we can dismiss BrowsingView?
            // Or just stay here.
            // Let's assume if user dealt with them, they might want to leave or continue.
            // But usually "Back" meant "Leave".
            if manager.pendingDeletionPhotos.isEmpty {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            DeletionSummaryView(manager: manager)
        }
    }
    
    // MARK: - Logic (Same as before)
    
    private func handleSwipe(translation: CGSize, photo: Photo) {
        let threshold: CGFloat = 100
        
        if translation.height < -threshold {
            // Up: Delete
            swipeAndDelete(photo: photo)
        } else if translation.height > threshold {
            // Down: Favorite
            swipeAndFavorite(photo: photo)
        } else if translation.width < -threshold {
            // Left: Next
            swipeAndNext(photo: photo)
        } else if translation.width > threshold {
            // Right: Previous
            swipeAndPrevious(photo: photo)
        } else {
            // Reset
            withAnimation(.spring()) {
                offset = .zero
            }
        }
    }
    
    private func swipeAndDelete(photo: Photo) {
        withAnimation {
            offset = CGSize(width: 0, height: -1000)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            manager.removePhoto(photoId: photo.id, from: group.id)
            offset = .zero
        }
    }
    
    private func swipeAndFavorite(photo: Photo) {
        withAnimation {
            offset = CGSize(width: 0, height: 1000)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            manager.moveToFavorites(photo: photo, from: group.id)
            offset = .zero
        }
    }
    
    private func swipeAndNext(photo: Photo) {
        withAnimation {
            offset = CGSize(width: -1000, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            manager.rotatePhoto(photoId: photo.id, in: group.id)
            offset = .zero
        }
    }
    
    private func swipeAndPrevious(photo: Photo) {
        withAnimation {
            manager.rotatePhotoBackwards(in: group.id)
            offset = .zero
        }
    }
}


// Updated Card View matching prototype
struct BrowsingCardView: View {
    let photo: Photo
    
    var body: some View {
        GeometryReader { geometry in
             AssetImageView(asset: photo.asset, imageURL: photo.imageURL, color: photo.color)
             .frame(width: geometry.size.width, height: geometry.size.height)
             .clipped()
             .cornerRadius(32)
             .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal, 20) // Give simple padding
    }
}

// Visual indicators for swipe actions
struct GestureOverlay: View {
    let offset: CGSize
    let isTop: Bool
    
    var body: some View {
        ZStack {
            if isTop {
                // Same logic for indicators, maybe cleaner icons
                 if offset.height < -50 {
                     // Delete Intent
                     Image(systemName: "trash.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .background(Circle().fill(.white))
                        .offset(y: 100) // Position appropriately
                 } 
                 // Other indicators...
                 // Keeping it simple to match "Clean" aesthetic of screenshot
                // Usually clean apps don't show giant icons unless triggering
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack {
             Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("All Caught Up!")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
