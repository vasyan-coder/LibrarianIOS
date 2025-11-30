//
//  ChatService.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Ошибки AI сервиса
enum AIServiceError: LocalizedError {
    case networkError
    case invalidResponse
    case rateLimited
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету."
        case .invalidResponse:
            return "Не удалось обработать ответ."
        case .rateLimited:
            return "Слишком много запросов. Подождите немного."
        case .serverError:
            return "Ошибка сервера. Попробуйте позже."
        }
    }
}

// MARK: - Сервис чата с AI
class ChatService: ObservableObject {
    @Published var chatSessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    @Published var isLoading = false
    @Published var streamingText = ""
    
    private let userDefaults = UserDefaults.standard
    private let chatSessionsKey = "chat_sessions"
    
    // API ключ (в реальном приложении хранить в Keychain)
    private var apiKey: String?
    
    init() {
        loadSessionsFromStorage()
    }
    
    // MARK: - Локальное хранилище
    
    private func loadSessionsFromStorage() {
        guard let data = userDefaults.data(forKey: chatSessionsKey),
              let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            return
        }
        chatSessions = decoded
    }
    
    private func saveSessionsToStorage() {
        guard let encoded = try? JSONEncoder().encode(chatSessions) else { return }
        userDefaults.set(encoded, forKey: chatSessionsKey)
    }
    
    // MARK: - Управление сессиями
    
    func createSession(for bookId: UUID) -> ChatSession {
        let session = ChatSession(bookId: bookId)
        chatSessions.insert(session, at: 0)
        currentSession = session
        saveSessionsToStorage()
        return session
    }
    
    func selectSession(_ session: ChatSession) {
        currentSession = session
    }
    
    func deleteSession(_ session: ChatSession) {
        chatSessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = nil
        }
        saveSessionsToStorage()
    }
    
    func sessions(for bookId: UUID) -> [ChatSession] {
        chatSessions.filter { $0.bookId == bookId }
    }
    
    // MARK: - Отправка сообщения
    
    func sendMessage(
        _ content: String,
        book: Book,
        notes: [Note] = [],
        sessionId: UUID? = nil
    ) async throws {
        // Получаем или создаём сессию
        var session: ChatSession
        if let sessionId = sessionId,
           let existing = chatSessions.first(where: { $0.id == sessionId }) {
            session = existing
        } else if let existingForBook = chatSessions.first(where: { $0.bookId == book.id }) {
            // Используем существующую сессию для этой книги
            session = existingForBook
        } else {
            // Создаём новую сессию
            session = createSession(for: book.id)
        }
        
        // Создаём сообщение пользователя
        let userMessage = ChatMessage(
            bookId: book.id,
            sessionId: session.id,
            role: .user,
            content: content,
            status: .sent
        )
        
        session.messages.append(userMessage)
        updateSession(session)
        
        // Показываем индикатор загрузки
        isLoading = true
        streamingText = ""
        
        defer {
            isLoading = false
        }
        
        // Генерируем ответ (заглушка - в реальном приложении вызов API)
        let response = try await generateResponse(
            question: content,
            book: book,
            notes: notes,
            history: session.messages
        )
        
        // Создаём сообщение ассистента
        let assistantMessage = ChatMessage(
            bookId: book.id,
            sessionId: session.id,
            role: .assistant,
            content: response,
            status: .sent
        )
        
        session.messages.append(assistantMessage)
        
        // Обновляем заголовок сессии, если это первое сообщение
        if session.title.isEmpty {
            session.title = String(content.prefix(50))
        }
        
        session.updatedAt = Date()
        updateSession(session)
    }
    
    private func updateSession(_ session: ChatSession) {
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[index] = session
        }
        currentSession = session
        saveSessionsToStorage()
    }
    
    // MARK: - Генерация ответа (заглушка)
    
    private func generateResponse(
        question: String,
        book: Book,
        notes: [Note],
        history: [ChatMessage]
    ) async throws -> String {
        // Имитируем задержку сети
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // В реальном приложении здесь будет вызов OpenAI/Anthropic API
        // с системным промптом на русском языке
        
        // systemPrompt для будущей интеграции с AI API:
        // """
        // Ты — умный помощник для чтения книг. Отвечай на русском языке.
        // Книга: "\(book.title)" автора \(book.author).
        // \(book.summary.map { "Описание: \($0)" } ?? "")
        // Отвечай кратко, но информативно.
        // """
        _ = question // Используется в реальном API
        _ = history  // Используется в реальном API
        
        // Примеры ответов для демонстрации
        let responses = [
            "Это интересный вопрос о книге «\(book.title)»! \(book.author) создал уникальное произведение, которое затрагивает глубокие философские темы.",
            "В контексте «\(book.title)» этот вопрос особенно важен. Автор \(book.author) мастерски раскрывает эту тему через своих персонажей.",
            "Отличный вопрос! В книге «\(book.title)» \(book.author) исследует эту тему с разных сторон, показывая её многогранность.",
        ]
        
        return responses.randomElement() ?? responses[0]
    }
    
    // MARK: - Ответ на вопрос из заметки
    
    func answerNoteQuestion(
        note: Note,
        book: Book
    ) async throws -> String {
        guard note.type == .question else {
            return "Это не вопрос."
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let response = try await generateResponse(
            question: note.content,
            book: book,
            notes: [],
            history: []
        )
        
        return response
    }
    
    // MARK: - Генерация инсайта сессии
    
    func generateSessionInsight(
        session: ReadingSession,
        book: Book,
        notes: [Note]
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        // Имитируем задержку
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Для будущей интеграции с AI API
        _ = session
        _ = book
        _ = notes.map { "- \($0.type.displayName): \($0.content)" }.joined(separator: "\n")
        
        // В реальном приложении — вызов API
        let insights = [
            "Главная тема этой сессии — исследование внутреннего мира персонажей. Ваши заметки показывают глубокое понимание авторского замысла.",
            "Вы прочитали важный фрагмент книги, где раскрываются ключевые сюжетные линии. Обратите внимание на символизм в описаниях.",
            "Эта часть книги богата философскими размышлениями. Ваши вопросы затрагивают центральные темы произведения.",
        ]
        
        return insights.randomElement() ?? insights[0]
    }
}

