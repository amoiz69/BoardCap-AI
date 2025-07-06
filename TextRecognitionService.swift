//
//  TextRecognitionService.swift
//  BoardCap AI
//
//  Created by Abdul Moiz on 25/6/25.
//

import Vision
import UIKit
import Foundation

class TextRecognitionService: ObservableObject {
    @Published var isProcessing = false
    @Published var recognitionProgress: Double = 0.0
    
    private let textRecognitionQueue = DispatchQueue(label: "text.recognition.queue", qos: .userInitiated)
    
    // MARK: - Main Text Recognition
    func recognizeText(from image: UIImage, completion: @escaping (RecognizedText?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.isProcessing = true
                self.recognitionProgress = 0.0
            }
            
            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(nil)
                }
                return
            }
            
            // Create text recognition request
            let request = VNRecognizeTextRequest { [weak self] request, error in
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    
                    if let error = error {
                        print("Text recognition error: \(error)")
                        completion(nil)
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        completion(nil)
                        return
                    }
                    
                    let recognizedText = self?.processTextObservations(observations, from: image)
                    completion(recognizedText)
                }
            }
            
            // Configure request for better accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"] // Add more languages as needed
            request.minimumTextHeight = 0.01 // Minimum text height relative to image height
            
            // Create handler and perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    print("Failed to perform text recognition: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Process Text Observations
    private func processTextObservations(_ observations: [VNRecognizedTextObservation], from image: UIImage) -> RecognizedText {
        var textBlocks: [TextBlock] = []
        var fullText = ""
        
        let imageSize = image.size
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let confidence = topCandidate.confidence
            let text = topCandidate.string
            
            // Get bounding box
            let boundingBox = observation.boundingBox
            let rect = CGRect(
                x: boundingBox.origin.x * imageSize.width,
                y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )
            
            let textBlock = TextBlock(
                text: text,
                confidence: Double(confidence),
                boundingBox: rect,
                fontSize: estimateFontSize(from: boundingBox, imageSize: imageSize)
            )
            
            textBlocks.append(textBlock)
            fullText += text + " "
        }
        
        // Sort text blocks by position (top to bottom, left to right)
        textBlocks.sort { block1, block2 in
            if abs(block1.boundingBox.minY - block2.boundingBox.minY) < 20 {
                // Same line, sort by x position
                return block1.boundingBox.minX < block2.boundingBox.minX
            } else {
                // Different lines, sort by y position
                return block1.boundingBox.minY < block2.boundingBox.minY
            }
        }
        
        return RecognizedText(
            fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            textBlocks: textBlocks,
            confidence: calculateOverallConfidence(textBlocks),
            timestamp: Date()
        )
    }
    
    // MARK: - Utility Methods
    private func estimateFontSize(from boundingBox: CGRect, imageSize: CGSize) -> CGFloat {
        let height = boundingBox.height * imageSize.height
        return height * 0.8 // Rough estimation
    }
    
    private func calculateOverallConfidence(_ textBlocks: [TextBlock]) -> Double {
        guard !textBlocks.isEmpty else { return 0.0 }
        
        let totalConfidence = textBlocks.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(textBlocks.count)
    }
    
    // MARK: - Advanced Text Processing
    func processRecognizedText(_ recognizedText: RecognizedText) -> ProcessedText {
        let lines = groupTextIntoLines(recognizedText.textBlocks)
        let paragraphs = groupLinesIntoParagraphs(lines)
        
        return ProcessedText(
            originalText: recognizedText,
            lines: lines,
            paragraphs: paragraphs,
            wordCount: countWords(recognizedText.fullText),
            estimatedReadingTime: estimateReadingTime(recognizedText.fullText)
        )
    }
    
    private func groupTextIntoLines(_ textBlocks: [TextBlock]) -> [TextLine] {
        var lines: [TextLine] = []
        var currentLine: [TextBlock] = []
        
        for block in textBlocks {
            if currentLine.isEmpty {
                currentLine.append(block)
            } else {
                let lastBlock = currentLine.last!
                let verticalDistance = abs(block.boundingBox.minY - lastBlock.boundingBox.minY)
                
                if verticalDistance < 20 { // Same line threshold
                    currentLine.append(block)
                } else {
                    // New line
                    if !currentLine.isEmpty {
                        lines.append(TextLine(blocks: currentLine))
                        currentLine = [block]
                    }
                }
            }
        }
        
        // Add the last line
        if !currentLine.isEmpty {
            lines.append(TextLine(blocks: currentLine))
        }
        
        return lines
    }
    
    private func groupLinesIntoParagraphs(_ lines: [TextLine]) -> [TextParagraph] {
        var paragraphs: [TextParagraph] = []
        var currentParagraph: [TextLine] = []
        
        for line in lines {
            if currentParagraph.isEmpty {
                currentParagraph.append(line)
            } else {
                let lastLine = currentParagraph.last!
                let verticalDistance = abs(line.blocks.first?.boundingBox.minY ?? 0 - (lastLine.blocks.first?.boundingBox.minY ?? 0))
                
                if verticalDistance < 50 { // Paragraph threshold
                    currentParagraph.append(line)
                } else {
                    // New paragraph
                    if !currentParagraph.isEmpty {
                        paragraphs.append(TextParagraph(lines: currentParagraph))
                        currentParagraph = [line]
                    }
                }
            }
        }
        
        // Add the last paragraph
        if !currentParagraph.isEmpty {
            paragraphs.append(TextParagraph(lines: currentParagraph))
        }
        
        return paragraphs
    }
    
    private func countWords(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private func estimateReadingTime(_ text: String) -> TimeInterval {
        let wordsPerMinute: Double = 200 // Average reading speed
        let wordCount = Double(countWords(text))
        return (wordCount / wordsPerMinute) * 60 // Convert to seconds
    }
}

// MARK: - Data Models
struct RecognizedText {
    let fullText: String
    let textBlocks: [TextBlock]
    let confidence: Double
    let timestamp: Date
    
    var id: String {
        return "\(timestamp.timeIntervalSince1970)"
    }
}

struct TextBlock {
    let text: String
    let confidence: Double
    let boundingBox: CGRect
    let fontSize: CGFloat
}

struct TextLine {
    let blocks: [TextBlock]
    
    var text: String {
        return blocks.map { $0.text }.joined(separator: " ")
    }
    
    var confidence: Double {
        guard !blocks.isEmpty else { return 0.0 }
        return blocks.reduce(0.0) { $0 + $1.confidence } / Double(blocks.count)
    }
}

struct TextParagraph {
    let lines: [TextLine]
    
    var text: String {
        return lines.map { $0.text }.joined(separator: "\n")
    }
    
    var confidence: Double {
        guard !lines.isEmpty else { return 0.0 }
        return lines.reduce(0.0) { $0 + $1.confidence } / Double(lines.count)
    }
}

struct ProcessedText {
    let originalText: RecognizedText
    let lines: [TextLine]
    let paragraphs: [TextParagraph]
    let wordCount: Int
    let estimatedReadingTime: TimeInterval
    
    var formattedText: String {
        return paragraphs.map { $0.text }.joined(separator: "\n\n")
    }
} 
