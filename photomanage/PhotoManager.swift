import SwiftUI
import Combine
import Photos

@MainActor
class PhotoManager: ObservableObject {
    @Published var groups: [PhotoGroup] = []
    @Published var favoritePhotos: [Photo] = []
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    
    init() {
        // Check permission immediately
        checkPermission()
    }
    
    func checkPermission() {
        permissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if permissionStatus == .authorized || permissionStatus == .limited {
            fetchPhotosFromLibrary()
        } else if permissionStatus == .notDetermined {
            requestPermission()
        } else {
            // Fallback to mock if denied, or empty
            generateRandomGroups()
        }
    }
    
    func refresh() {
        if permissionStatus == .authorized || permissionStatus == .limited {
            fetchPhotosFromLibrary()
        } else {
            generateRandomGroups()
        }
    }
    
    func requestPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.permissionStatus = status
                if status == .authorized || status == .limited {
                    self.fetchPhotosFromLibrary()
                } else {
                    self.generateRandomGroups()
                }
            }
        }
    }
    
    func fetchPhotosFromLibrary() {
        let fetchOptions = PHFetchOptions()
        // No sort descriptors needed for random access, or keeping them doesn't strictly matter if we pick random indices.
        // But removing them might be slightly faster if the OS doesn't have to sort.
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        let assets = PHAsset.fetchAssets(with: fetchOptions)
        let totalCount = assets.count
        
        let targetTotal = 45 // 3 groups * 15 photos
        
        guard totalCount >= 5 else {
            generateRandomGroups()
            return
        }
        
        // Generate unique random indices
        var randomIndices = Set<Int>()
        let needed = min(totalCount, targetTotal)
        
        // If total count is small (e.g. < 45), just take all of them.
        if totalCount <= targetTotal {
            for i in 0..<totalCount {
                randomIndices.insert(i)
            }
        } else {
            // True random sampling from the entire library
            while randomIndices.count < needed {
                let random = Int.random(in: 0..<totalCount)
                randomIndices.insert(random)
            }
        }
        
        var pickedAssets: [PHAsset] = []
        for index in randomIndices {
            pickedAssets.append(assets.object(at: index))
        }
        
        // Shuffle again just to mix the order of acquisition (though indices were random, iteration order of Set is undefined but consistent-ish)
        let shuffledAssets = pickedAssets.shuffled()
        
        // Create groups
        var newGroups: [PhotoGroup] = []
        let groupCount = 3
        let photosPerGroup = 15
        
        var currentIndex = 0
        
        for i in 1...groupCount {
            var photos: [Photo] = []
            for _ in 0..<photosPerGroup {
                if currentIndex < shuffledAssets.count {
                    let asset = shuffledAssets[currentIndex]
                    photos.append(Photo(asset: asset, color: .gray))
                    currentIndex += 1
                } else {
                    break
                }
            }
            if !photos.isEmpty {
                newGroups.append(PhotoGroup(title: "Group \(i)", photos: photos))
            }
        }
        
        self.groups = newGroups
    }
    
    func generateRandomGroups() {
        print("Generating Mock Data...")
        var newGroups: [PhotoGroup] = []
        for i in 1...3 {
            var photos: [Photo] = []
            for _ in 0..<15 {
                let randomId = Int.random(in: 1...1000)
                let url = URL(string: "https://picsum.photos/id/\(randomId)/600/800")!
                let randomColor = Color(
                    red: .random(in: 0...1),
                    green: .random(in: 0...1),
                    blue: .random(in: 0...1)
                )
                photos.append(Photo(imageURL: url, color: randomColor))
            }
            newGroups.append(PhotoGroup(title: "Group \(i)", photos: photos))
        }
        self.groups = newGroups
    }
    
    // MARK: - Actions
    
    func moveToFavorites(photo: Photo, from groupId: UUID) {
        var favPhoto = photo
        favPhoto.isFavorite = true
        favoritePhotos.append(favPhoto)
        
        // Remove from UI only, DO NOT add to pending deletion
        removePhotoFromGroupOnly(photoId: photo.id, from: groupId)
        
        // Real Photo Library Logic
        if let asset = photo.asset {
             toggleSystemFavorite(asset: asset, isFavorite: true)
        }
    }
    
    // Helper to just remove from UI stack without deletion intent
    private func removePhotoFromGroupOnly(photoId: UUID, from groupId: UUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[groupIndex].photos.removeAll(where: { $0.id == photoId })
    }
    
    func rotatePhoto(photoId: UUID, in groupId: UUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else { return }
        guard let photoIndex = groups[groupIndex].photos.firstIndex(where: { $0.id == photoId }) else { return }
        
        if groups[groupIndex].photos.indices.contains(photoIndex) {
            let photo = groups[groupIndex].photos.remove(at: photoIndex)
            groups[groupIndex].photos.append(photo)
        }
    }
    
    func rotatePhotoBackwards(in groupId: UUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else { return }
        var photos = groups[groupIndex].photos
        guard !photos.isEmpty else { return }
        
        let last = photos.removeLast()
        photos.insert(last, at: 0)
        groups[groupIndex].photos = photos
    }
    
    @Published var pendingDeletionPhotos: [Photo] = []
    
    // Restore a photo from the pending deletion list (cancel its deletion)
    func restoreFromDeletion(_ photo: Photo) {
        pendingDeletionPhotos.removeAll(where: { $0.id == photo.id })
    }
    
    func removePhoto(photoId: UUID, from groupId: UUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else { return }
        
        // Find photo
        if let photo = groups[groupIndex].photos.first(where: { $0.id == photoId }) {
            // Remove from UI
            groups[groupIndex].photos.removeAll(where: { $0.id == photoId })
            
            // Add to pending deletion queue
            pendingDeletionPhotos.append(photo)
        }
    }
    
    // Execute the final system delete for all pending photos
    func confirmDeletions(completion: @escaping (Bool) -> Void) {
        guard !pendingDeletionPhotos.isEmpty else {
            completion(true)
            return
        }
        
        let assetsToDelete = pendingDeletionPhotos.compactMap { $0.asset }
        
        PHPhotoLibrary.shared().performChanges {
             PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    self.pendingDeletionPhotos.removeAll()
                }
                completion(success)
            }
        }
    }
    
    func cancelDeletions() {
        // Just clear the pending list. 
        // Note: The photos are already gone from the group UI. To truly "cancel", we'd need to restore them to the group.
        // But typically "Cancel" here means "Don't delete from System".
        // If we want to restore them to the UI, we would need to track where they came from.
        // For simpler logic: We just clear the 'pending' list, so they won't be deleted from iCloud.
        // They are already gone from the 'To Sort' stack, which is also fine (User 'skipped' them essentially).
        pendingDeletionPhotos.removeAll()
    }
    
    // MARK: - System Operations
    
    private func toggleSystemFavorite(asset: PHAsset, isFavorite: Bool) {
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = isFavorite
        }
    }
    
    private func deleteSystemPhoto(asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }
    }
}
