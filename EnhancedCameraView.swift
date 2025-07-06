//
//  EnhancedCameraView.swift
//  BoardCap AI
//
//  Created by Abdul Moiz on 25/6/25.
//

import SwiftUI
import AVFoundation

struct EnhancedCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var imageProcessor = ImageProcessor()
    @StateObject private var storageManager = StorageManager.shared
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showProcessingView = false
    @State private var showImagePreview = false
    @State private var capturedImage: UIImage?
    @State private var processedImage: ProcessedImage?
    @State private var showSettings = false
    @State private var flashMode: AVCaptureDevice.FlashMode = .auto
    @State private var showGuideOverlay = true
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.isCameraReady {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
                    .onAppear {
                        print("🎥 CameraPreviewView appeared")
                    }
            } else {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Setting up camera...")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.top, 20)
                }
            }
            
            // Guide overlay
            if showGuideOverlay && cameraManager.isCameraReady {
                CameraGuideOverlay()
            }
            
            // Top controls
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 30) {
                    // Flash control
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            toggleFlashMode()
                        }) {
                            Image(systemName: flashMode == .on ? "bolt.fill" : "bolt.slash")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Capture button
                    HStack(spacing: 60) {
                        // Gallery button
                        Button(action: {
                            // TODO: Implement gallery picker
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        // Main capture button
                        Button(action: {
                            capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                            }
                        }
                        .disabled(cameraManager.isCapturing)
                        
                        // Settings button
                        Button(action: {
                            showGuideOverlay.toggle()
                        }) {
                            Image(systemName: showGuideOverlay ? "eye.fill" : "eye.slash")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .sheet(isPresented: $showImagePreview) {
            if let processedImage = processedImage {
                ImagePreviewView(
                    processedImage: processedImage,
                    onSave: saveImage,
                    onRetake: retakePhoto,
                    onContinue: continueCapturing
                )
            }
        }
        .sheet(isPresented: $showProcessingView) {
            ProcessingView(progress: imageProcessor.processingProgress)
        }
        .alert("Camera Error", isPresented: $cameraManager.showError) {
            Button("OK") { }
        } message: {
            Text(cameraManager.errorMessage ?? "Unknown error occurred")
        }
        .onReceive(cameraManager.$capturedImage) { image in
            if let image = image {
                processCapturedImage(image)
            }
        }
    }
    
    private func setupCamera() {
        print("🔧 Setting up camera...")
        Task {
            let hasPermission = await cameraManager.requestCameraPermission()
            print("📱 Camera permission granted: \(hasPermission)")
            
            if hasPermission {
                await MainActor.run {
                    cameraManager.setupCamera()
                }
                
                // Give the camera a moment to setup
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                
                print("✅ Camera setup completed")
            } else {
                await MainActor.run {
                    self.cameraManager.errorMessage = "Camera permission denied. Please enable camera access in Settings."
                    self.cameraManager.showError = true
                }
                print("❌ Camera permission denied")
            }
        }
    }
    
    private func capturePhoto() {
        print("📸 Attempting to capture photo...")
        guard cameraManager.isCameraReady else {
            print("❌ Camera not ready")
            cameraManager.errorMessage = "Camera is not ready yet. Please wait."
            cameraManager.showError = true
            return
        }
        
        print("✅ Camera ready, capturing photo...")
        cameraManager.capturePhoto(flashMode: flashMode)
    }
    
    private func processCapturedImage(_ image: UIImage) {
        capturedImage = image
        showProcessingView = true
        
        imageProcessor.processBoardImage(image) { processedImage in
            DispatchQueue.main.async {
                showProcessingView = false
                if let processedImage = processedImage {
                    self.processedImage = processedImage
                    showImagePreview = true
                } else {
                    // Fallback: use original image if processing fails
                    let fallbackProcessedImage = ProcessedImage(
                        originalImage: image,
                        processedImage: image,
                        timestamp: Date(),
                        processingSteps: ["Original Image (Processing Failed)"]
                    )
                    self.processedImage = fallbackProcessedImage
                    showImagePreview = true
                }
            }
        }
    }
    
    private func saveImage() {
        guard let processedImage = processedImage else { return }
        
        let metadata = ImageMetadata(
            title: "Board Capture",
            description: "Captured and processed board image",
            tags: ["board", "capture"],
            processingSteps: processedImage.processingSteps,
            boardType: .unknown,
            confidence: 0.8,
            imageSize: processedImage.processedImage.size
        )
        
        Task {
            let success = await storageManager.saveImage(processedImage.processedImage, metadata: metadata)
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func retakePhoto() {
        capturedImage = nil
        processedImage = nil
        showImagePreview = false
    }
    
    private func continueCapturing() {
        capturedImage = nil
        processedImage = nil
        showImagePreview = false
    }
    
    private func toggleFlashMode() {
        switch flashMode {
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        @unknown default:
            flashMode = .auto
        }
    }
}

// MARK: - Camera Guide Overlay
struct CameraGuideOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Board detection frame
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(
                        width: geometry.size.width * 0.85,
                        height: geometry.size.height * 0.6
                    )
                
                // Corner indicators
                VStack {
                    HStack {
                        CornerIndicator()
                        Spacer()
                        CornerIndicator()
                    }
                    Spacer()
                    HStack {
                        CornerIndicator()
                        Spacer()
                        CornerIndicator()
                    }
                }
                .frame(
                    width: geometry.size.width * 0.85,
                    height: geometry.size.height * 0.6
                )
                
                // Instructions
                VStack {
                    Spacer()
                    
                    Text("Position the board within the frame")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                }
            }
        }
    }
}

struct CornerIndicator: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 16, height: 16)
        }
    }
}

// MARK: - Processing View
struct ProcessingView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing your board image...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Image Preview View
struct ImagePreviewView: View {
    let processedImage: ProcessedImage
    let onSave: () -> Void
    let onRetake: () -> Void
    let onContinue: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Image preview
                ScrollView {
                    VStack(spacing: 20) {
                        Image(uiImage: processedImage.processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Processing steps
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Processing Steps:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            ForEach(processedImage.processingSteps, id: \.self) { step in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 14))
                                    
                                    Text(step)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary action buttons
                    HStack(spacing: 16) {
                        Button(action: onRetake) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Retake")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: onSave) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Save Note")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Continue button
                    Button(action: onContinue) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Continue Capturing")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 