//
//  OCRService.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import Vision
import UIKit
import Combine

// MARK: - Ошибки OCR
enum OCRError: LocalizedError {
    case imageProcessingFailed
    case noTextFound
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Не удалось обработать изображение."
        case .noTextFound:
            return "Текст на изображении не найден."
        case .recognitionFailed:
            return "Ошибка распознавания текста."
        }
    }
}

// MARK: - Сервис распознавания текста с изображений
@MainActor
class OCRService: ObservableObject {
    @Published var isProcessing = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    
    // MARK: - Распознавание текста
    
    func recognizeText(from image: UIImage) async throws -> String {
        isProcessing = true
        errorMessage = nil
        
        defer {
            isProcessing = false
        }
        
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                if recognizedStrings.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Настройки для русского языка
            request.recognitionLanguages = ["ru-RU", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed)
            }
        }
    }
    
    // MARK: - Распознавание с предобработкой
    
    func recognizeTextWithPreprocessing(from image: UIImage) async throws -> String {
        // Предобработка изображения для лучшего распознавания
        let processedImage = preprocessImage(image)
        return try await recognizeText(from: processedImage)
    }
    
    private func preprocessImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        
        // Увеличиваем контраст
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return image }
        contrastFilter.setValue(ciImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.1, forKey: kCIInputContrastKey)
        
        guard let contrastOutput = contrastFilter.outputImage else { return image }
        
        // Преобразуем в оттенки серого для лучшего распознавания
        guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else { return image }
        grayscaleFilter.setValue(contrastOutput, forKey: kCIInputImageKey)
        
        guard let grayscaleOutput = grayscaleFilter.outputImage,
              let cgImage = context.createCGImage(grayscaleOutput, from: grayscaleOutput.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Извлечение цитаты
    
    /// Пытается очистить распознанный текст и отформатировать как цитату
    func extractQuote(from text: String) -> String {
        var cleaned = text
        
        // Убираем лишние переносы строк
        cleaned = cleaned.replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
        
        // Убираем номера страниц (обычно числа в начале или конце строки)
        let lines = cleaned.components(separatedBy: "\n")
        let filteredLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Пропускаем строки, которые содержат только числа
            return !trimmed.isEmpty && Int(trimmed) == nil
        }
        
        cleaned = filteredLines.joined(separator: " ")
        
        // Убираем множественные пробелы
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Добавляем кавычки, если их нет
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        if !cleaned.hasPrefix("«") && !cleaned.hasPrefix("\"") {
            cleaned = "«\(cleaned)»"
        }
        
        return cleaned
    }
    
    // MARK: - Распознавание области
    
    func recognizeText(from image: UIImage, in region: CGRect) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }
        
        // Вырезаем область
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let cropRect = CGRect(
            x: region.origin.x * imageWidth,
            y: region.origin.y * imageHeight,
            width: region.width * imageWidth,
            height: region.height * imageHeight
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            throw OCRError.imageProcessingFailed
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage)
        return try await recognizeText(from: croppedImage)
    }
}

