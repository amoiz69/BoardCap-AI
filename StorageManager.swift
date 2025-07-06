//
//  StorageManager.swift
//  BoardCap AI
//
//  Created by Abdul Moiz on 25/6/25.
//

import Foundation
import UIKit
import SwiftData

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var savedImages: [SavedImage] = []
    @Published var isSaving = false
    
    private let fileManager = FileManager.default
    private let documentsPath: String
    
    private init() {
        documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        loadSavedImages()
    }
    
    // MARK: - Image Storage
    func saveImage(_ image: UIImage, metadata: ImageMetadata) async -> Bool {
        await MainActor.run {
            isSaving = true
        }
        
        do {
            // Create unique filename
            let timestamp = Date().timeIntervalSince1970
            let filename = "board_\(timestamp).jpg"
            let filePath = (documentsPath as NSString).appendingPathComponent(filename)
            
            // Compress and save image
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                await MainActor.run {
                    isSaving = false
                }
                return false
            }
            
            try imageData.write(to: URL(fileURLWithPath: filePath))
            
            // Save metadata
            let savedImage = SavedImage(
                id: UUID().uuidString,
                filename: filename,
                filePath: filePath,
                metadata: metadata,
                createdAt: Date()
            )
            
            await MainActor.run {
                savedImages.append(savedImage)
                saveImageList()
                isSaving = false
            }
            
            return true
            
        } catch {
            print("Failed to save image: \(error)")
            await MainActor.run {
                isSaving = false
            }
            return false
        }
    }
    
    func loadImage(from savedImage: SavedImage) -> UIImage? {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: savedImage.filePath)) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    func deleteImage(_ savedImage: SavedImage) -> Bool {
        do {
            // Remove file
            try fileManager.removeItem(atPath: savedImage.filePath)
            
            // Remove from list
            savedImages.removeAll { $0.id == savedImage.id }
            saveImageList()
            
            return true
        } catch {
            print("Failed to delete image: \(error)")
            return false
        }
    }
    
    // MARK: - Metadata Storage
    private func saveImageList() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(savedImages)
            let listPath = (documentsPath as NSString).appendingPathComponent("saved_images.json")
            try data.write(to: URL(fileURLWithPath: listPath))
        } catch {
            print("Failed to save image list: \(error)")
        }
    }
    
    private func loadSavedImages() {
        let listPath = (documentsPath as NSString).appendingPathComponent("saved_images.json")
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: listPath)) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            savedImages = try decoder.decode([SavedImage].self, from: data)
        } catch {
            print("Failed to load saved images: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    func getStorageUsage() -> (used: Int64, total: Int64) {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsPath)
            let totalSpace = attributes[.systemSize] as? Int64 ?? 0
            let freeSpace = attributes[.systemFreeSize] as? Int64 ?? 0
            let usedSpace = totalSpace - freeSpace
            
            return (used: usedSpace, total: totalSpace)
        } catch {
            return (used: 0, total: 0)
        }
    }
    
    func clearAllImages() {
        for savedImage in savedImages {
            _ = deleteImage(savedImage)
        }
        savedImages.removeAll()
        saveImageList()
    }
    
    func clearAllData() {
        clearAllImages()
    }
    
    func exportImage(_ savedImage: SavedImage) -> URL? {
        guard let image = loadImage(from: savedImage) else { return nil }
        
        let exportPath = (documentsPath as NSString).appendingPathComponent("export_\(savedImage.filename)")
        
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
        
        do {
            try imageData.write(to: URL(fileURLWithPath: exportPath))
            return URL(fileURLWithPath: exportPath)
        } catch {
            print("Failed to export image: \(error)")
            return nil
        }
    }
}

// MARK: - Data Models
struct SavedImage: Codable, Identifiable {
    let id: String
    let filename: String
    let filePath: String
    let metadata: ImageMetadata
    let createdAt: Date
    
    var displayName: String {
        return metadata.title.isEmpty ? "Board Capture" : metadata.title
    }
    
    var fileSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

struct ImageMetadata: Codable {
    var title: String
    var description: String
    var tags: [String]
    var processingSteps: [String]
    var boardType: BoardType
    var confidence: Double
    var imageSize: CGSize
    
    init(title: String = "", description: String = "", tags: [String] = [], processingSteps: [String] = [], boardType: BoardType = .unknown, confidence: Double = 0.0, imageSize: CGSize = CGSize(width: 0, height: 0)) {
        self.title = title
        self.description = description
        self.tags = tags
        self.processingSteps = processingSteps
        self.boardType = boardType
        self.confidence = confidence
        self.imageSize = imageSize
    }
}

enum BoardType: String, Codable, CaseIterable {
    case whiteboard = "whiteboard"
    case blackboard = "blackboard"
    case glass = "glass"
    case paper = "paper"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .whiteboard: return "Whiteboard"
        case .blackboard: return "Blackboard"
        case .glass: return "Glass Board"
        case .paper: return "Paper"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .whiteboard: return "rectangle.fill"
        case .blackboard: return "rectangle"
        case .glass: return "rectangle.dashed"
        case .paper: return "doc.text"
        case .unknown: return "questionmark"
        }
    }
} 