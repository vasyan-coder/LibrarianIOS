//
//  Note.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import SwiftUI

// MARK: - Тип заметки
enum NoteType: String, Codable, CaseIterable {
    case thought = "thought"
    case quote = "quote"
    case question = "question"
    
    var displayName: String {
        switch self {
        case .thought: return "Мысль"
        case .quote: return "Цитата"
        case .question: return "Вопрос"
        }
    }
    
    var icon: String {
        switch self {
        case .thought: return "lightbulb.fill"
        case .quote: return "quote.opening"
        case .question: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .thought: return .yellow
        case .quote: return .purple
        case .question: return .cyan
        }
    }
}

// MARK: - Источник заметки
enum NoteSource: String, Codable {
    case voice = "voice"
    case camera = "camera"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .voice: return "Голос"
        case .camera: return "Камера"
        case .manual: return "Вручную"
        }
    }
    
    var icon: String {
        switch self {
        case .voice: return "mic.fill"
        case .camera: return "camera.fill"
        case .manual: return "pencil"
        }
    }
}

// MARK: - Модель заметки
struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var bookId: UUID
    var sessionId: UUID?
    var content: String
    var type: NoteType
    var source: NoteSource
    var page: Int?
    var createdAt: Date
    var updatedAt: Date
    var aiResponse: String?
    var isExpanded: Bool = false
    
    init(
        id: UUID = UUID(),
        bookId: UUID,
        sessionId: UUID? = nil,
        content: String,
        type: NoteType = .thought,
        source: NoteSource = .manual,
        page: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        aiResponse: String? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.sessionId = sessionId
        self.content = content
        self.type = type
        self.source = source
        self.page = page
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.aiResponse = aiResponse
    }
    
    // Определяем CodingKeys для исключения isExpanded из кодирования
    enum CodingKeys: String, CodingKey {
        case id, bookId, sessionId, content, type, source, page, createdAt, updatedAt, aiResponse
    }
}

// MARK: - Классификация заметок по русскому тексту
extension Note {
    /// Определяет тип заметки на основе русского текста
    static func classifyFromRussianText(_ text: String) -> NoteType {
        let lowercased = text.lowercased()
        
        // Проверка на цитату
        let quoteIndicators = [
            "цитата", "запиши цитату", "запомни цитату",
            "как сказано", "автор пишет", "в книге написано"
        ]
        
        // Русские кавычки
        let hasRussianQuotes = text.contains("«") || text.contains("»") ||
                              text.contains("„") || text.contains("\u{201C}") ||
                              text.contains("\"")
        
        if quoteIndicators.contains(where: { lowercased.contains($0) }) || hasRussianQuotes {
            return .quote
        }
        
        // Проверка на вопрос
        let questionIndicators = [
            "почему", "зачем", "как", "что будет, если",
            "интересно", "вопрос", "не понимаю"
        ]
        
        let hasQuestionMark = text.contains("?")
        
        if questionIndicators.contains(where: { lowercased.contains($0) }) || hasQuestionMark {
            return .question
        }
        
        // По умолчанию — мысль
        return .thought
    }
    
    /// Очищает текст от триггерных слов
    static func cleanTriggerWords(from text: String) -> String {
        var cleaned = text
        let triggers = ["цитата:", "цитата", "мысль:", "мысль", "вопрос:", "вопрос"]
        
        for trigger in triggers {
            if cleaned.lowercased().hasPrefix(trigger) {
                cleaned = String(cleaned.dropFirst(trigger.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        return cleaned
    }
}

// MARK: - Примеры заметок для превью
extension Note {
    static let samples: [Note] = [
        Note(
            bookId: Book.sample.id,
            content: "Кто такой Фродо Бэггинс?",
            type: .question,
            source: .voice,
            page: 45,
            aiResponse: "Фродо Бэггинс — хоббит из Шира, главный герой «Властелина колец». Он племянник и приёмный наследник Бильбо Бэггинса, предыдущего владельца таинственного и могущественного Кольца."
        ),
        Note(
            bookId: Book.sample.id,
            content: "«Рукописи не горят» — одна из ключевых фраз романа, символизирующая бессмертие истинного искусства.",
            type: .quote,
            source: .camera,
            page: 287
        ),
        Note(
            bookId: Book.sample.id,
            content: "Интересная параллель между Воландом и Мефистофелем из «Фауста» Гёте.",
            type: .thought,
            source: .manual,
            page: 150
        )
    ]
}

