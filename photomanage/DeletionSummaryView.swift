import SwiftUI

struct DeletionSummaryView: View {
    @ObservedObject var manager: PhotoManager
    @Environment(\.presentationMode) var presentationMode
    
    // Grid Setup
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Pending Deletion")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Review before deleting \(manager.pendingDeletionPhotos.count) photos")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Photo Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(manager.pendingDeletionPhotos) { photo in
                            ZStack(alignment: .bottomTrailing) {
                                AssetImageView(asset: photo.asset, imageURL: photo.imageURL, color: .gray)
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(12)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Circle().fill(Color.white))
                                    .padding(8)
                            }
                            .onTapGesture {
                                withAnimation {
                                    manager.restoreFromDeletion(photo)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 20) {
                    // Cancel / Keep
                    Button(action: {
                        manager.cancelDeletions()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    
                    // Confirm Delete
                    Button(action: {
                        manager.confirmDeletions { success in
                            if success {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        Text("Confirm Delete")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                }
                .padding(24)
            }
        }
    }
}
