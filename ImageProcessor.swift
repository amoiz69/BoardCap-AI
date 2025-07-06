//
//  ImageProcessor.swift
//  BoardCap AI
//
//  Created by Abdul Moiz on 25/6/25.
//

import UIKit
import CoreImage
import Vision
import CoreML

class ImageProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private let context = CIContext()
    
    // MARK: - Main Processing Pipeline
    func processBoardImage(_ image: UIImage, completion: @escaping (ProcessedImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.isProcessing = true
                self.processingProgress = 0.0
            }
            
            // Step 1: Detect board boundaries
            DispatchQueue.main.async {
                self.processingProgress = 0.2
            }
            let detectedImage = self.detectBoardBoundaries(image) ?? image
            
            // Step 2: Enhance image quality
            DispatchQueue.main.async {
                self.processingProgress = 0.4
            }
            let enhancedImage = self.enhanceImage(detectedImage) ?? detectedImage
            
            // Step 3: Apply perspective correction
            DispatchQueue.main.async {
                self.processingProgress = 0.6
            }
            let correctedImage = self.applyPerspectiveCorrection(enhancedImage) ?? enhancedImage
            
            // Step 4: Optimize for text recognition
            DispatchQueue.main.async {
                self.processingProgress = 0.8
            }
            let optimizedImage = self.optimizeForTextRecognition(correctedImage) ?? correctedImage
            
            DispatchQueue.main.async {
                self.processingProgress = 1.0
            }
            
            let processedImage = ProcessedImage(
                originalImage: image,
                processedImage: optimizedImage,
                timestamp: Date(),
                processingSteps: ["Board Detection", "Enhancement", "Perspective Correction", "Text Optimization"]
            )
            
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(processedImage)
            }
        }
    }
    
    // MARK: - Board Boundary Detection
    private func detectBoardBoundaries(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Use Vision framework to detect rectangles (potential board boundaries)
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 2.0
        request.minimumSize = 0.3
        request.maximumObservations = 1
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results as? [VNRectangleObservation],
               let firstRectangle = results.first {
                return cropToRectangle(image, rectangle: firstRectangle)
            }
        } catch {
            print("Rectangle detection failed: \(error)")
        }
        
        return image // Return original if no board detected
    }
    
    private func cropToRectangle(_ image: UIImage, rectangle: VNRectangleObservation) -> UIImage? {
        let imageSize = image.size
        
        let topLeft = CGPoint(
            x: rectangle.topLeft.x * imageSize.width,
            y: (1 - rectangle.topLeft.y) * imageSize.height
        )
        let topRight = CGPoint(
            x: rectangle.topRight.x * imageSize.width,
            y: (1 - rectangle.topRight.y) * imageSize.height
        )
        let bottomLeft = CGPoint(
            x: rectangle.bottomLeft.x * imageSize.width,
            y: (1 - rectangle.bottomLeft.y) * imageSize.height
        )
        let bottomRight = CGPoint(
            x: rectangle.bottomRight.x * imageSize.width,
            y: (1 - rectangle.bottomRight.y) * imageSize.height
        )
        
        // Create perspective transform
        let transform = CGAffineTransform.identity
        let rect = CGRect(
            x: min(topLeft.x, bottomLeft.x),
            y: min(topLeft.y, topRight.y),
            width: max(topRight.x, bottomRight.x) - min(topLeft.x, bottomLeft.x),
            height: max(bottomLeft.y, bottomRight.y) - min(topLeft.y, topRight.y)
        )
        
        guard let cgImage = image.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Image Enhancement
    private func enhanceImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Apply filters for enhancement
        var enhancedImage = ciImage
        
        // Auto-adjust filters
        if let autoAdjustmentFilter = CIFilter(name: "CIAutoAdjustmentFilter") {
            autoAdjustmentFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
            if let output = autoAdjustmentFilter.outputImage {
                enhancedImage = output
            }
        }
        
        // Enhance contrast
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(enhancedImage, forKey: kCIInputImageKey)
            colorControls.setValue(1.1, forKey: kCIInputContrastKey) // Increase contrast
            colorControls.setValue(0.0, forKey: kCIInputSaturationKey) // Remove color for better text recognition
            if let output = colorControls.outputImage {
                enhancedImage = output
            }
        }
        
        // Sharpen
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.5, forKey: "inputSharpness")
            if let output = sharpenFilter.outputImage {
                enhancedImage = output
            }
        }
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(enhancedImage, from: enhancedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Perspective Correction
    private func applyPerspectiveCorrection(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Apply perspective correction filter
        if let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection") {
            perspectiveCorrection.setValue(ciImage, forKey: kCIInputImageKey)
            
            // Set perspective correction points (you can adjust these based on detected board corners)
            let imageSize = ciImage.extent.size
            perspectiveCorrection.setValue(CIVector(x: 0, y: 0), forKey: "inputTopLeft")
            perspectiveCorrection.setValue(CIVector(x: imageSize.width, y: 0), forKey: "inputTopRight")
            perspectiveCorrection.setValue(CIVector(x: 0, y: imageSize.height), forKey: "inputBottomLeft")
            perspectiveCorrection.setValue(CIVector(x: imageSize.width, y: imageSize.height), forKey: "inputBottomRight")
            
            if let output = perspectiveCorrection.outputImage,
               let cgImage = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return image
    }
    
    // MARK: - Text Recognition Optimization
    private func optimizeForTextRecognition(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        var optimizedImage = ciImage
        
        // Convert to grayscale for better text recognition
        if let colorMatrix = CIFilter(name: "CIColorMatrix") {
            colorMatrix.setValue(optimizedImage, forKey: kCIInputImageKey)
            colorMatrix.setValue(CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0), forKey: "inputRVector")
            colorMatrix.setValue(CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0), forKey: "inputGVector")
            colorMatrix.setValue(CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0), forKey: "inputBVector")
            colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
            
            if let output = colorMatrix.outputImage {
                optimizedImage = output
            }
        }
        
        // Apply noise reduction
        if let noiseReduction = CIFilter(name: "CINoiseReduction") {
            noiseReduction.setValue(optimizedImage, forKey: kCIInputImageKey)
            noiseReduction.setValue(0.02, forKey: "inputNoiseLevel")
            noiseReduction.setValue(0.4, forKey: "inputSharpness")
            
            if let output = noiseReduction.outputImage {
                optimizedImage = output
            }
        }
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(optimizedImage, from: optimizedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Utility Methods
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
}

// MARK: - Processed Image Model
struct ProcessedImage {
    let originalImage: UIImage
    let processedImage: UIImage
    let timestamp: Date
    let processingSteps: [String]
    
    var id: String {
        return "\(timestamp.timeIntervalSince1970)"
    }
} 