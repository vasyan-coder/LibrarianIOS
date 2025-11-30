//
//  Book.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import SwiftUI

// MARK: - Статус чтения
enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead = "want_to_read"
    case reading = "reading"
    case finished = "finished"
    case abandoned = "abandoned"
    
    var displayName: String {
        switch self {
        case .wantToRead: return "Хочу прочитать"
        case .reading: return "Читаю"
        case .finished: return "Прочитано"
        case .abandoned: return "Отложено"
        }
    }
    
    var icon: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .reading: return "book.fill"
        case .finished: return "checkmark.circle.fill"
        case .abandoned: return "pause.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .wantToRead: return .orange
        case .reading: return .blue
        case .finished: return .green
        case .abandoned: return .gray
        }
    }
}

// MARK: - Модель книги
struct Book: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var author: String
    var isbn: String?
    var coverURL: String?
    var localCoverData: Data?
    var summary: String?
    var publisher: String?
    var publishedYear: Int?
    var pageCount: Int?
    var currentPage: Int
    var status: ReadingStatus
    var dateAdded: Date
    var dateStarted: Date?
    var dateFinished: Date?
    var rating: Int? // 1-5
    var genres: [String]
    var language: String
    
    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        isbn: String? = nil,
        coverURL: String? = nil,
        localCoverData: Data? = nil,
        summary: String? = nil,
        publisher: String? = nil,
        publishedYear: Int? = nil,
        pageCount: Int? = nil,
        currentPage: Int = 0,
        status: ReadingStatus = .wantToRead,
        dateAdded: Date = Date(),
        dateStarted: Date? = nil,
        dateFinished: Date? = nil,
        rating: Int? = nil,
        genres: [String] = [],
        language: String = "ru"
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn = isbn
        self.coverURL = coverURL
        self.localCoverData = localCoverData
        self.summary = summary
        self.publisher = publisher
        self.publishedYear = publishedYear
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.status = status
        self.dateAdded = dateAdded
        self.dateStarted = dateStarted
        self.dateFinished = dateFinished
        self.rating = rating
        self.genres = genres
        self.language = language
    }
    
    // Прогресс чтения в процентах
    var readingProgress: Double {
        guard let total = pageCount, total > 0 else { return 0 }
        return Double(currentPage) / Double(total)
    }
    
    var progressText: String {
        if let total = pageCount {
            return "\(currentPage) из \(total) стр."
        }
        return "\(currentPage) стр."
    }
}

// MARK: - Примеры книг для превью
extension Book {
    static let samples: [Book] = [
        Book(
            title: "Мастер и Маргарита",
            author: "Михаил Булгаков",
            isbn: "978-5-17-090335-1",
            coverURL: nil,
            summary: "Роман о визите дьявола в атеистическую Москву 1930-х годов. Переплетение трёх сюжетных линий: история Мастера и его возлюбленной Маргариты, похождения Воланда и его свиты, и роман о Понтии Пилате.",
            publisher: "АСТ",
            publishedYear: 1967,
            pageCount: 480,
            currentPage: 120,
            status: .reading,
            genres: ["Фантастика", "Классика"],
            language: "ru"
        ),
        Book(
            title: "Пикник на обочине",
            author: "Аркадий и Борис Стругацкие",
            isbn: "978-5-17-080401-7",
            summary: "После посещения Земли пришельцами остались загадочные Зоны, полные смертельных ловушек и невероятных артефактов. Сталкеры рискуют жизнью, добывая эти предметы.",
            pageCount: 224,
            currentPage: 0,
            status: .wantToRead,
            genres: ["Научная фантастика"],
            language: "ru"
        ),
        Book(
            title: "Преступление и наказание",
            author: "Фёдор Достоевский",
            isbn: "978-5-389-06256-6",
            summary: "История бедного студента Родиона Раскольникова, решившегося на убийство ради проверки своей теории о «праве» сильной личности.",
            publisher: "Азбука",
            publishedYear: 1866,
            pageCount: 672,
            currentPage: 672,
            status: .finished,
            rating: 5,
            genres: ["Классика", "Психологический роман"],
            language: "ru"
        ),
        Book(
            title: "Властелин колец",
            author: "Дж. Р. Р. Толкин",
            isbn: "978-5-17-114033-7",
            summary: "Эпическая история о хоббите Фродо Бэггинсе, которому выпала судьба уничтожить Кольцо Всевластия в огне Роковой горы.",
            pageCount: 1200,
            currentPage: 450,
            status: .reading,
            genres: ["Фэнтези"],
            language: "ru"
        )
    ]
    
    static let sample = samples[0]
}

