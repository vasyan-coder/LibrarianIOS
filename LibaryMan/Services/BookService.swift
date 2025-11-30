//
//  BookService.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Протокол сервиса книг
protocol BookServiceProtocol {
    func fetchBooks() async throws -> [Book]
    func searchBooks(query: String) async throws -> [Book]
    func searchByISBN(_ isbn: String) async throws -> Book?
    func saveBook(_ book: Book) async throws
    func deleteBook(_ book: Book) async throws
    func updateBook(_ book: Book) async throws
}

// MARK: - Результат поиска Google Books
struct GoogleBooksResponse: Codable {
    let totalItems: Int?
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: GoogleVolumeInfo
}

struct GoogleVolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: GoogleImageLinks?
    let industryIdentifiers: [GoogleIndustryIdentifier]?
    let language: String?
}

struct GoogleImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
}

struct GoogleIndustryIdentifier: Codable {
    let type: String?
    let identifier: String?
}

// MARK: - Ошибки сервиса
enum BookServiceError: LocalizedError {
    case networkError
    case decodingError
    case notFound
    case saveFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету."
        case .decodingError:
            return "Не удалось обработать данные."
        case .notFound:
            return "Книга не найдена."
        case .saveFailed:
            return "Не удалось сохранить книгу."
        case .deleteFailed:
            return "Не удалось удалить книгу."
        }
    }
}

// MARK: - Реализация сервиса книг
class BookService: BookServiceProtocol, ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let booksKey = "saved_books"
    
    init() {
        loadBooksFromStorage()
    }
    
    // MARK: - Локальное хранилище
    
    private func loadBooksFromStorage() {
        guard let data = userDefaults.data(forKey: booksKey),
              let decoded = try? JSONDecoder().decode([Book].self, from: data) else {
            // Загружаем примеры для демонстрации
            books = Book.samples
            return
        }
        books = decoded
    }
    
    private func saveBooksToStorage() {
        guard let encoded = try? JSONEncoder().encode(books) else { return }
        userDefaults.set(encoded, forKey: booksKey)
    }
    
    // MARK: - CRUD операции
    
    func fetchBooks() async throws -> [Book] {
        return books
    }
    
    func saveBook(_ book: Book) async throws {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        } else {
            books.insert(book, at: 0)
        }
        saveBooksToStorage()
    }
    
    func deleteBook(_ book: Book) async throws {
        books.removeAll { $0.id == book.id }
        saveBooksToStorage()
    }
    
    func updateBook(_ book: Book) async throws {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else {
            throw BookServiceError.notFound
        }
        books[index] = book
        saveBooksToStorage()
    }
    
    // MARK: - Поиск книг через Google Books API
    
    func searchBooks(query: String) async throws -> [Book] {
        isLoading = true
        defer { isLoading = false }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(encodedQuery)&maxResults=20&langRestrict=ru"
        
        guard let url = URL(string: urlString) else {
            throw BookServiceError.networkError
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            
            guard let items = response.items else {
                return []
            }
            
            return items.compactMap { convertToBook($0) }
        } catch {
            throw BookServiceError.networkError
        }
    }
    
    func searchByISBN(_ isbn: String) async throws -> Book? {
        isLoading = true
        defer { isLoading = false }
        
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(cleanISBN)"
        
        guard let url = URL(string: urlString) else {
            throw BookServiceError.networkError
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            
            guard let item = response.items?.first else {
                throw BookServiceError.notFound
            }
            
            return convertToBook(item)
        } catch is DecodingError {
            throw BookServiceError.decodingError
        } catch {
            throw BookServiceError.networkError
        }
    }
    
    // MARK: - Конвертация из Google Books формата
    
    private func convertToBook(_ item: GoogleBookItem) -> Book? {
        let info = item.volumeInfo
        
        guard let title = info.title else { return nil }
        
        let author = info.authors?.joined(separator: ", ") ?? "Неизвестный автор"
        
        // Получаем ISBN
        let isbn = info.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
                ?? info.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
        
        // Получаем URL обложки (заменяем http на https)
        var coverURL = info.imageLinks?.thumbnail ?? info.imageLinks?.smallThumbnail
        coverURL = coverURL?.replacingOccurrences(of: "http://", with: "https://")
        
        // Парсим год публикации
        var publishedYear: Int?
        if let dateString = info.publishedDate {
            let yearString = String(dateString.prefix(4))
            publishedYear = Int(yearString)
        }
        
        return Book(
            title: title,
            author: author,
            isbn: isbn,
            coverURL: coverURL,
            summary: info.description,
            publisher: info.publisher,
            publishedYear: publishedYear,
            pageCount: info.pageCount,
            genres: info.categories ?? [],
            language: info.language ?? "ru"
        )
    }
    
    // MARK: - Импорт из CSV
    
    func importFromCSV(_ csvString: String) throws -> [Book] {
        var importedBooks: [Book] = []
        let lines = csvString.components(separatedBy: .newlines)
        
        // Пропускаем заголовок
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let columns = parseCSVLine(trimmed)
            guard columns.count >= 2 else { continue }
            
            let title = columns[0]
            let author = columns[1]
            let isbn = columns.count > 2 ? columns[2] : nil
            
            let book = Book(
                title: title,
                author: author,
                isbn: isbn?.isEmpty == true ? nil : isbn
            )
            importedBooks.append(book)
        }
        
        return importedBooks
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        
        return result
    }
    
    // MARK: - Фильтрация
    
    func booksByStatus(_ status: ReadingStatus) -> [Book] {
        books.filter { $0.status == status }
    }
    
    func searchLocalBooks(_ query: String) -> [Book] {
        guard !query.isEmpty else { return books }
        
        let lowercased = query.lowercased()
        return books.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.author.lowercased().contains(lowercased)
        }
    }
}

