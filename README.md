# BoardCap AI - Backend System

This document describes the backend system for BoardCap AI, a SwiftUI app that captures and processes whiteboard/blackboard images.

## Overview

The backend system consists of several key components that work together to provide a complete camera capture and image processing solution:

1. **CameraManager** - Handles camera setup, permissions, and photo capture
2. **ImageProcessor** - Processes captured images for better text recognition
3. **StorageManager** - Manages local storage of images and metadata
4. **TextRecognitionService** - Extracts text from processed images
5. **EnhancedCameraView** - Provides a full-featured camera interface

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CameraManager │───▶│  ImageProcessor │───▶│ StorageManager  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│EnhancedCameraView│    │TextRecognition  │    │   Local Storage │
│                 │    │   Service       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Key Components

### 1. CameraManager.swift
**Purpose**: Manages camera setup, permissions, and photo capture using AVFoundation.
**Key Features**:
- Camera permission handling
- Real-time camera preview
- Photo capture with configurable settings
- Error handling and status reporting

**Usage**:
```swift
@StateObject private var cameraManager = CameraManager()

// Check permissions
let hasPermission = await cameraManager.requestCameraPermission()

// Start camera session
cameraManager.startSession()

// Capture photo
cameraManager.capturePhoto()
```

### 2. ImageProcessor.swift
**Purpose**: Processes captured images to improve text recognition accuracy.

**Processing Pipeline**:
1. **Board Detection** - Uses Vision framework to detect board boundaries
2. **Image Enhancement** - Applies filters for better contrast and clarity
3. **Perspective Correction** - Corrects skewed board images
4. **Text Optimization** - Converts to grayscale and reduces noise

**Usage**:
```swift
@StateObject private var imageProcessor = ImageProcessor()

imageProcessor.processBoardImage(image) { processedImage in
    // Handle processed image
    if let processed = processedImage {
        // Use processed.processedImage for text recognition
    }
}
```

### 3. StorageManager.swift
**Purpose**: Manages local storage of images and metadata.

**Features**:
- Automatic file management with unique naming
- Metadata storage (title, description, tags, processing steps)
- Image compression and optimization
- Storage usage tracking

**Usage**:
```swift
let storageManager = StorageManager.shared

// Save image with metadata
let metadata = ImageMetadata(
    title: "Math Notes",
    description: "Calculus formulas",
    tags: ["math", "calculus"],
    boardType: .whiteboard
)

let success = await storageManager.saveImage(image, metadata: metadata)

// Load saved images
for savedImage in storageManager.savedImages {
    if let image = storageManager.loadImage(from: savedImage) {
        // Use image
    }
}
```

### 4. TextRecognitionService.swift
**Purpose**: Extracts text from processed images using Vision framework.

**Features**:
- High-accuracy text recognition
- Text block positioning and confidence scoring
- Automatic text organization (lines, paragraphs)
- Reading time estimation

**Usage**:
```swift
@StateObject private var textService = TextRecognitionService()

textService.recognizeText(from: image) { recognizedText in
    if let text = recognizedText {
        let processedText = textService.processRecognizedText(text)
        print("Extracted text: \(processedText.formattedText)")
        print("Word count: \(processedText.wordCount)")
    }
}
```

### 5. EnhancedCameraView.swift
**Purpose**: Provides a complete camera interface with advanced features.

**Features**:
- Real-time camera preview
- Board detection guide overlay
- Flash control
- Processing progress indicators
- Image preview and editing options

## Setup Instructions

### 1. Add Required Permissions
Add the following to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>BoardCap AI needs camera access to capture whiteboards and blackboards for text recognition and processing.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>BoardCap AI needs access to your photo library to import existing board images for processing.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>BoardCap AI needs permission to save processed board images to your photo library.</string>
```

### 2. Import Required Frameworks
Ensure these frameworks are imported in your project:
- AVFoundation
- Vision
- CoreImage
- SwiftUI

### 3. Initialize Services
In your main app file:

```swift
.onAppear {
    // Initialize backend services
    _ = StorageManager.shared
}
```

## Usage Example

Here's a complete example of capturing and processing a board image:

```swift
struct CaptureExample: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var imageProcessor = ImageProcessor()
    @StateObject private var textService = TextRecognitionService()
    @StateObject private var storageManager = StorageManager.shared
    
    @State private var showCamera = false
    @State private var processedImage: ProcessedImage?
    @State private var recognizedText: RecognizedText?
    
    var body: some View {
        VStack {
            Button("Capture Board") {
                showCamera = true
            }
            
            if let text = recognizedText {
                Text("Extracted Text:")
                Text(text.fullText)
                    .padding()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            EnhancedCameraView()
        }
    }
}
```

## Data Models

### ProcessedImage
```swift
struct ProcessedImage {
    let originalImage: UIImage
    let processedImage: UIImage
    let timestamp: Date
    let processingSteps: [String]
}
```

### SavedImage
```swift
struct SavedImage: Codable, Identifiable {
    let id: String
    let filename: String
    let filePath: String
    let metadata: ImageMetadata
    let createdAt: Date
}
```

### RecognizedText
```swift
struct RecognizedText {
    let fullText: String
    let textBlocks: [TextBlock]
    let confidence: Double
    let timestamp: Date
}
```

## Error Handling

The system includes comprehensive error handling:

- Camera permission errors
- Image processing failures
- Storage errors
- Text recognition errors

All errors are reported through the respective service's `@Published` properties and can be handled in the UI.

## Performance Considerations

- Image processing is performed on background queues
- Images are automatically compressed to save storage space
- Text recognition uses Vision framework for optimal performance
- Camera sessions are properly managed to conserve battery

## Future Enhancements

Potential improvements for the backend system:

1. **Cloud Storage Integration** - Sync images across devices
2. **Advanced AI Models** - Better board detection and text recognition
3. **Multi-language Support** - Support for non-English text
4. **Real-time Processing** - Process images as they're captured
5. **Collaborative Features** - Share and edit board captures

## Troubleshooting

### Common Issues

1. **Camera not working**: Check permissions in Settings
2. **Poor text recognition**: Ensure good lighting and clear board content
3. **Storage issues**: Check available device storage
4. **Processing errors**: Verify image format and size

### Debug Information

Enable debug logging by adding print statements in the respective services. The system provides detailed error messages and processing status updates.

## License

This backend system is part of the BoardCap AI project and follows the same licensing terms as the main application. 
