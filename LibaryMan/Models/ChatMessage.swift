//
//  ChatMessage.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation

// MARK: - Роль в чате
enum ChatRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - Статус сообщения
enum MessageStatus: String, Codable {
    case sending = "sending"
    case sent = "sent"
    case error = "error"
}

// MARK: - Сообщение чата
struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var bookId: UUID?
    var sessionId: UUID?
    var role: ChatRole
    var content: String
    var status: MessageStatus
    var createdAt: Date
    var referencedNoteIds: [UUID]
    var isStreaming: Bool
    
    init(
        id: UUID = UUID(),
        bookId: UUID? = nil,
        sessionId: UUID? = nil,
        role: ChatRole,
        content: String,
        status: MessageStatus = .sent,
        createdAt: Date = Date(),
        referencedNoteIds: [UUID] = [],
        isStreaming: Bool = false
    ) {
        self.id = id
        self.bookId = bookId
        self.sessionId = sessionId
        self.role = role
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.referencedNoteIds = referencedNoteIds
        self.isStreaming = isStreaming
    }
    
    // Исключаем isStreaming из кодирования
    enum CodingKeys: String, CodingKey {
        case id, bookId, sessionId, role, content, status, createdAt, referencedNoteIds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        bookId = try container.decodeIfPresent(UUID.self, forKey: .bookId)
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId)
        role = try container.decode(ChatRole.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        status = try container.decode(MessageStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        referencedNoteIds = try container.decodeIfPresent([UUID].self, forKey: .referencedNoteIds) ?? []
        isStreaming = false
    }
}

// MARK: - История чата (сессия разговора)
struct ChatSession: Identifiable, Codable, Hashable {
    let id: UUID
    var bookId: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        bookId: UUID,
        title: String = "",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Автоматически генерирует заголовок из первого сообщения пользователя
    var displayTitle: String {
        if !title.isEmpty {
            return title
        }
        
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let preview = firstUserMessage.content.prefix(50)
            return preview.count < firstUserMessage.content.count ? "\(preview)..." : String(preview)
        }
        
        return "Новый разговор"
    }
    
    /// Количество сообщений
    var messageCount: Int {
        messages.filter { $0.role != .system }.count
    }
    
    /// Форматированная дата
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}

// MARK: - Примеры для превью
extension ChatMessage {
    static let samples: [ChatMessage] = [
        ChatMessage(
            bookId: Book.sample.id,
            role: .user,
            content: "Кто такой Фродо Бэггинс?"
        ),
        ChatMessage(
            bookId: Book.sample.id,
            role: .assistant,
            content: "Фродо Бэггинс — хоббит из Шира и главный герой «Властелина колец». Он племянник и приёмный наследник Бильбо Бэггинса, от которого унаследовал Кольцо Всевластия. Фродо отправляется в опасное путешествие, чтобы уничтожить Кольцо в огне Роковой горы."
        )
    ]
}

extension ChatSession {
    static let sample = ChatSession(
        bookId: Book.sample.id,
        title: "Кто такой Фродо Бэггинс?",
        messages: ChatMessage.samples,
        createdAt: Date(),
        updatedAt: Date()
    )
}

