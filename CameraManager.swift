//
//  CameraManager.swift
//  BoardCap AI
//
//  Created by Abdul Moiz on 25/6/25.
//

import AVFoundation
import UIKit
import SwiftUI
import Combine
import CoreMedia
import CoreVideo

class CameraManager: NSObject, ObservableObject {
    @Published var isCameraReady = false
    @Published var isCapturing = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var captureSession: AVCaptureSession?
    private var photoOutput = AVCapturePhotoOutput()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    override init() {
        super.init()
    }
    
    func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    private func configureCaptureSession() {
        print("🔧 Configuring capture session...")
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        // Check camera availability
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Camera not available on this device")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Camera not available on this device"
                self?.showError = true
            }
            return
        }
        
        print("✅ Camera device found: \(videoDevice.localizedName)")
        
        do {
            // Add video input
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                print("✅ Video input added")
            } else {
                throw NSError(domain: "CameraError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])
            }
            
            // Add photo output first
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                print("✅ Photo output added")
            } else {
                throw NSError(domain: "CameraError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot add photo output"])
            }
            
            // Configure photo output after it's connected to the session
            photoOutput.isLivePhotoCaptureEnabled = false
            
            // Configure high resolution capture after session is set up
            if #available(iOS 16.0, *) {
                if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    let activeFormat = videoDevice.activeFormat
                    let maxDimensions = CMVideoFormatDescriptionGetDimensions(activeFormat.formatDescription)
                    photoOutput.maxPhotoDimensions = maxDimensions
                    print("✅ Photo output configured with max dimensions: \(maxDimensions.width)x\(maxDimensions.height)")
                } else {
                    print("⚠️ Could not get video device for photo configuration")
                    // Set a reasonable default
                    photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
                }
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
                print("✅ Photo output configured with high resolution (legacy)")
            }
            
            self.captureSession = session
            
            // Start the session immediately after setup
            session.startRunning()
            print("✅ Camera session started after setup")
            
            DispatchQueue.main.async { [weak self] in
                self?.isCameraReady = true
                print("✅ Camera is ready")
            }
            
        } catch {
            print("❌ Camera setup failed: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to setup camera: \(error.localizedDescription)"
                self?.showError = true
            }
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession else { 
                print("❌ Cannot start session: captureSession is nil")
                return 
            }
            
            if !session.isRunning {
                session.startRunning()
                print("✅ Camera session started")
            } else {
                print("ℹ️ Camera session already running")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let session = self?.captureSession else { return }
            
            if session.isRunning {
                session.stopRunning()
                print("✅ Camera session stopped")
            }
        }
    }
    
    func capturePhoto(flashMode: AVCaptureDevice.FlashMode = .auto) {
        guard isCameraReady && !isCapturing else { 
            print("Camera not ready or already capturing")
            return 
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isCapturing = true
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = flashMode
            
            // Enable high resolution capture if available
            if #available(iOS 16.0, *) {
                // maxPhotoDimensions is set on the photoOutput during setup
                // We can optionally override it here for specific shots if needed
            } else {
                settings.isHighResolutionPhotoEnabled = true
            }
            
            // Set the photo orientation to match the device orientation
            if let videoConnection = self.photoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if videoConnection.isVideoRotationAngleSupported(0) {
                        videoConnection.videoRotationAngle = 0
                    }
                } else {
                    if videoConnection.isVideoOrientationSupported {
                        videoConnection.videoOrientation = .portrait
                    }
                }
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func requestCameraPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func getCaptureSession() -> AVCaptureSession? {
        return captureSession
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📸 Photo capture completed")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                print("❌ Self is nil in photo capture delegate")
                return 
            }
            
            self.isCapturing = false
            
            if let error = error {
                print("❌ Photo capture failed: \(error.localizedDescription)")
                self.errorMessage = "Failed to capture photo: \(error.localizedDescription)"
                self.showError = true
                return
            }
            
            guard let imageData = photo.fileDataRepresentation() else {
                print("❌ Failed to get image data from photo")
                self.errorMessage = "Failed to get image data from photo"
                self.showError = true
                return
            }
            
            print("✅ Got image data, size: \(imageData.count) bytes")
            
            guard let image = UIImage(data: imageData) else {
                print("❌ Failed to create UIImage from data")
                self.errorMessage = "Failed to create image from data"
                self.showError = true
                return
            }
            
            print("✅ Photo captured successfully, size: \(image.size), orientation: \(image.imageOrientation.rawValue)")
            
            // Fix image orientation for back camera
            let fixedImage = self.fixImageOrientation(image)
            
            // Clear previous image first
            self.capturedImage = nil
            
            // Set new image
            self.capturedImage = fixedImage
        }
    }
    
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        // For back camera, we need to ensure the image is properly oriented
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        
        // Set up the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Store reference to preview layer
        context.coordinator.previewLayer = previewLayer
        context.coordinator.previewView = view
        
        // Set session immediately if available
        if let captureSession = cameraManager.getCaptureSession() {
            previewLayer.session = captureSession
            print("✅ Preview layer connected to session in makeUIView")
        } else {
            print("⚠️ No capture session available yet in makeUIView")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update preview layer frame
        if let previewLayer = context.coordinator.previewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = uiView.bounds
            CATransaction.commit()
        }
        
        // Set session when camera is ready and not already set
        if let captureSession = cameraManager.getCaptureSession(),
           let previewLayer = context.coordinator.previewLayer {
            if previewLayer.session !== captureSession {
                previewLayer.session = captureSession
                print("✅ Preview layer connected to session in updateUIView")
            } else {
                print("ℹ️ Preview layer already connected to session")
            }
        } else {
            print("⚠️ No capture session or preview layer available in updateUIView")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var previewView: CameraPreviewUIView?
    }
}

// MARK: - Custom UIView for Camera Preview
class CameraPreviewUIView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update preview layer frame when view layout changes
        if let previewLayer = layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = bounds
            CATransaction.commit()
        }
    }
} 
