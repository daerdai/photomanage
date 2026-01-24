import SwiftUI

struct HomeView: View {
    @StateObject private var manager = PhotoManager()
    @State private var selectedGroup: PhotoGroup?
    @State private var activeGroupID: UUID?
    
    var body: some View {
        ZStack {
            // Global Background
            Color.black.ignoresSafeArea()
            
            // Dynamic blurred background based on current group
            if !manager.groups.isEmpty {
                GeometryReader { proxy in
                    let currentGroup = manager.groups.first(where: { $0.id == activeGroupID }) ?? manager.groups.first
                    
                    if let group = currentGroup, let photo = group.photos.first {
                        AssetImageView(asset: photo.asset, imageURL: photo.imageURL, color: .black)
                            .blur(radius: 60)
                            .overlay(Color.black.opacity(0.4))
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: activeGroupID)
            }
            
            
            VStack {
                // Header (Pill)
                HStack {
                    let currentGroup = manager.groups.first(where: { $0.id == activeGroupID }) ?? manager.groups.first
                    
                    if let group = currentGroup {
                        Button(action: {
                            // Action for future menu
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                Text(group.title)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("\(group.photos.count)")
                                    .font(.system(size: 12, weight: .regular))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    Spacer()
                    
                    // Refresh Button
                    Button(action: {
                        withAnimation {
                            manager.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Main Carousel
                GeometryReader { geometry in
                    let cardWidth = geometry.size.width * 0.8
                    let spacing: CGFloat = 20
                    // Calculate side padding to ensure current item is perfectly centered
                    let sidePadding = (geometry.size.width - cardWidth) / 2
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(manager.groups) { group in
                                GroupCoverCard(group: group) {
                                    selectedGroup = group
                                }
                                .frame(width: cardWidth)
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.7)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                                        .rotation3DEffect(
                                            .degrees(phase.value * -5),
                                            axis: (x: 0, y: 1, z: 0)
                                        )
                                }
                                .id(group.id)
                                .zIndex(activeGroupID == group.id ? 100 : 0)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $activeGroupID)
                    .contentMargins(.horizontal, sidePadding, for: .scrollContent)
                }
                .frame(height: 500)
                
                Spacer()
                
                // Bottom area spacing placeholder (since dock is removed)
                Color.clear.frame(height: 50)
            }
        }
        .fullScreenCover(item: $selectedGroup) { group in
            if let index = manager.groups.firstIndex(where: { $0.id == group.id }) {
                BrowsingView(group: $manager.groups[index], manager: manager)
            }
        }
        .onAppear {
            // Set initial active group
            if activeGroupID == nil {
                activeGroupID = manager.groups.first?.id
            }
        }
    }
}

struct GroupCoverCard: View {
    let group: PhotoGroup
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if let firstPhoto = group.photos.first {
                    AssetImageView(asset: firstPhoto.asset, imageURL: firstPhoto.imageURL, color: .gray)
                        .frame(maxWidth: .infinity)
                } else {
                    Color.gray
                }
                
                // Gradient overlay for better text contrast if we added text, 
                // or just to make it look premium
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.2)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            // Ensure card has a consistent height filling the container frame provided layout
            .frame(height: 450)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
        }
    }
}
