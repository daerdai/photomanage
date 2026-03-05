# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS photo management app that provides a Tinder-like card interface for organizing photos from the device's photo library. Users can swipe photos to delete, favorite, or skip them.

## Build Commands

### Building and Running
```bash
# Build the project
xcodebuild -project photomanage.xcodeproj -scheme photomanage -configuration Debug build

# Build for specific destination (iOS Simulator)
xcodebuild -project photomanage.xcodeproj -scheme photomanage -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project photomanage.xcodeproj -scheme photomanage clean
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project photomanage.xcodeproj -scheme photomanage -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test file (when tests are added)
xcodebuild test -project photomanage.xcodeproj -scheme photomanage -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:photomanageTests/SpecificTestClass
```

### Opening in Xcode
```bash
open photomanage.xcodeproj
```

## Architecture

### MVVM Pattern
The app follows the MVVM (Model-View-ViewModel) architectural pattern:

- **Model Layer**: `Photo.swift` defines the core data structures (`Photo`, `PhotoGroup`)
- **ViewModel**: `PhotoManager.swift` acts as the @MainActor observable business logic layer, managing state and photo operations
- **Views**: SwiftUI views (`HomeView`, `BrowsingView`, `DeletionSummaryView`, etc.) observe the manager

### State Management
- `PhotoManager` is a `@MainActor` class with `@Published` properties for reactive state updates
- Views use `@StateObject` for creating manager instances and `@ObservedObject` for passed references
- All state mutations happen on the main thread via `@MainActor` annotation

### Photos Framework Integration
- The app uses Apple's Photos Framework (`PHAsset`, `PHPhotoLibrary`, `PHImageManager`)
- Permission handling: The app checks `PHPhotoLibrary.authorizationStatus` and requests `.readWrite` permission
- All photo mutations (delete, favorite) go through `PHAssetChangeRequest` to modify the system photo library
- Mock data fallback: When permission is denied or for testing, the app generates mock photos using `https://picsum.photos`

### Image Loading Strategy
`AssetImageView.swift` handles two types of image sources:
1. **Local Photos**: Uses `PHImageManager` with async loading, respects display scale for retina displays
2. **Remote URLs**: Falls back to `AsyncImage` for mock data from picsum.photos

### Navigation Structure
```
ContentView (Root)
└── HomeView (Main carousel)
    ├── GroupCoverCard (Clickable group previews)
    └── BrowsingView (Full-screen card stack)
        └── DeletionSummaryView (Modal for deletion confirmation)
```

### Gesture-Driven UI
`BrowsingView.swift` implements the core swipe mechanics:
- **Up swipe**: Delete (animates card upward, adds to pending deletion queue)
- **Down swipe**: Favorite (animates downward, marks as favorite in system library)
- **Left swipe**: Next/rotate (moves top card to bottom of stack)
- **Right swipe**: Previous/undo (moves bottom card to top of stack)

All gestures use `DragGesture` with real-time offset tracking and threshold-based action triggering.

### Deletion Workflow
Photos follow a two-phase deletion pattern:
1. **Pending State**: Swiped-up photos are added to `PhotoManager.pendingDeletionPhotos` and removed from UI
2. **Confirmation**: User reviews pending photos in `DeletionSummaryView`, then confirms or cancels
3. **System Deletion**: On confirmation, `PHPhotoLibrary.performChanges` deletes assets from iCloud/Photo Library

### Mock Data Generation
When photo library access is unavailable, `PhotoManager.generateRandomGroups()` creates 3 groups of 15 photos each using random picsum.photos URLs with random colors.

## Key Technical Details

### SwiftUI Features Used
- `scrollTransition`: Creates 3D rotation and scale effects on carousel cards
- `scrollTargetBehavior(.viewAligned)`: Enables paging behavior in horizontal scroll
- `scrollPosition`: Tracks active group ID in carousel
- `.task`: Used for async image loading that cancels when view disappears

### Performance Considerations
- The app loads a maximum of 45 photos (3 groups × 15) from the library using random sampling
- `AssetImageView` uses `.highQualityFormat` but loads at optimal size based on view dimensions and display scale
- Only top 3 cards are rendered in the stack (via `prefix(3)`) to minimize rendering overhead

### Color Extensions
The app includes a hex color initializer extension (`Color.init(hex:)`) for parsing hex color strings, used for custom background gradients.

## Development Notes

### Photo Permissions
The app requires `NSPhotoLibraryUsageDescription` in Info.plist. When adding new photo operations, ensure they handle all permission states: `.notDetermined`, `.restricted`, `.denied`, `.authorized`, `.limited`.

### Testing with Real Photos
When testing features that modify the photo library, consider adding a test mode flag to prevent accidental deletion during development.

### Animation Consistency
All swipe animations use `.spring(response: 0.4, dampingFraction: 0.6)` for consistent feel across the app.

### Date Formatting
`DateUtils.swift` provides `timeAgoDisplay(date:)` for human-readable relative timestamps (e.g., "2 days ago", "Last week"). This is used in the BrowsingView bottom toolbar.
