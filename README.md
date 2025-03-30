# KlutchShots Challenge

A modern iOS application that showcases advanced video streaming and downloading capabilities, built with SwiftUI and following MVVM architecture.

## Architecture Overview

The application follows the MVVM (Model-View-ViewModel) architectural pattern using Combine for reactive programming:

- **Models**: Simple data structures like `Video` that represent the core entities.
- **Views**: SwiftUI views responsible for the UI presentation.
- **ViewModels**: Business logic components that connect models to views and handle state management.

### Dependency Injection

The app implements a clean dependency injection system using Swift's environment values:

```swift
protocol DependenciesProtocol {
    var downloadManager: DownloadManagerProtocol { get }
    var networkingService: NetworkingProtocol { get }
}
```

Dependencies are injected through SwiftUI's environment, making testing easier and improving modularity.

## Key Features

### Video Streaming and Download Management

#### Buffering and Streaming

- Real-time buffering status indication during video streaming
- Automatic detection of network conditions
- Seamless transition between streaming and local playback

#### Download Handling

- Complete video download management system
- Progress tracking during downloads
- Intelligent playback source selection:
  - Automatically plays from local storage when available
  - Falls back to streaming when needed
  - Switches from streaming to local file mid-playback when download completes
  - Switches from local file to streaming when a downloaded video is deleted

### Custom UI Features

#### Interactive Transitions

- Custom zoom animation when transitioning between the video list and detail view
- Gesture-based return to list view with interactive animation

#### Responsive Layout

- Automatic orientation handling:
  - Switches to fullscreen mode in landscape orientation
  - Returns to detailed view in portrait orientation
- Pull-to-refresh functionality in the video list

#### Download Management UI

- Visual indication of download status
- Download button with multiple states
- Alert confirmation for video deletion
- Clear indication of playback source (local vs streaming)

### Caching System

- **Video Thumbnails**: Efficient caching of thumbnails in the video list
- **Video Files**: Complete video file storage and management for offline viewing

## Technical Implementation

### Networking

The app implements a robust networking layer:

- Protocol-based architecture for testability
- Proper error handling and logging
- Clean separation between network requests and business logic

### Download Management

The download system provides:

- Background download support
- Progress tracking
- File management capabilities
- Interruption handling

### Reactive Programming

Combine is used throughout the app:

- Real-time UI updates based on download progress
- State management in ViewModels
- Event handling for orientation changes

## Testing

- Comprehensive unit tests for all business logic
- Network service tests with mocked responses
- Download manager tests with file system mocking
- ViewModel tests ensuring correct state transitions

## CI/CD Integration

The project includes a CI workflow using GitHub Actions:

- Automated build process on every push and pull request
- Unit test execution
- Artifact storage for builds

## Running the App

### Requirements

- iOS 18.2+
- Xcode 16.2+

### Installation

1. Clone the repository
2. Open `KlutchShotsChallenge.xcodeproj` in Xcode
3. Build and run the project on your device or simulator

## Project Structure

```
KlutchShotsChallenge/
├── App/                  # App entry point and configuration
├── Models/               # Data models
├── ViewModels/           # Business logic
├── Views/                # UI components
└── Utils/                # Utilities and helpers
    ├── Dependencies/     # Dependency injection and services
    └── MockData/         # Mock data for previews and testing
```
