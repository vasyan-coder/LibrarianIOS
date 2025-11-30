//
//  ReadingSession.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation

// MARK: - Сессия чтения
struct ReadingSession: Identifiable, Codable, Hashable {
    let id: UUID
    var bookId: UUID
    var startTime: Date
    var endTime: Date?
    var startPage: Int
    var endPage: Int?
    var noteIds: [UUID]
    var keyInsight: String?
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        bookId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        startPage: Int = 0,
        endPage: Int? = nil,
        noteIds: [UUID] = [],
        keyInsight: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.bookId = bookId
        self.startTime = startTime
        self.endTime = endTime
        self.startPage = startPage
        self.endPage = endPage
        self.noteIds = noteIds
        self.keyInsight = keyInsight
        self.isActive = isActive
    }
    
    // MARK: - Вычисляемые свойства
    
    /// Длительность сессии
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    /// Форматированная длительность
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Количество прочитанных страниц
    var pagesRead: Int {
        guard let end = endPage else { return 0 }
        return max(0, end - startPage)
    }
    
    /// Количество заметок
    var notesCount: Int {
        noteIds.count
    }
    
    /// Краткое описание сессии
    var summary: String {
        var parts: [String] = []
        
        if pagesRead > 0 {
            parts.append("\(pagesRead) стр.")
        }
        
        if notesCount > 0 {
            let noteWord = pluralize(notesCount, one: "заметка", few: "заметки", many: "заметок")
            parts.append("\(notesCount) \(noteWord)")
        }
        
        return parts.isEmpty ? "Сессия чтения" : parts.joined(separator: " • ")
    }
    
    /// Склонение слов
    private func pluralize(_ count: Int, one: String, few: String, many: String) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        
        if mod100 >= 11 && mod100 <= 19 {
            return many
        }
        
        switch mod10 {
        case 1:
            return one
        case 2, 3, 4:
            return few
        default:
            return many
        }
    }
}

// MARK: - Примеры для превью
extension ReadingSession {
    static let sample = ReadingSession(
        bookId: Book.sample.id,
        startTime: Date().addingTimeInterval(-1800), // 30 минут назад
        endTime: nil,
        startPage: 100,
        endPage: 120,
        noteIds: Note.samples.map { $0.id },
        isActive: true
    )
    
    static let finishedSample = ReadingSession(
        bookId: Book.sample.id,
        startTime: Date().addingTimeInterval(-7200), // 2 часа назад
        endTime: Date().addingTimeInterval(-3600), // 1 час назад
        startPage: 50,
        endPage: 100,
        noteIds: [Note.samples[0].id, Note.samples[1].id],
        keyInsight: "Главная тема этой части — противостояние добра и зла, которое автор раскрывает через диалоги Воланда с москвичами.",
        isActive: false
    )
}

