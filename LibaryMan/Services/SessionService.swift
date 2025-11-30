//
//  SessionService.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Сервис сессий чтения
class SessionService: ObservableObject {
    @Published var sessions: [ReadingSession] = []
    @Published var activeSession: ReadingSession?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "reading_sessions"
    
    init() {
        loadSessionsFromStorage()
    }
    
    // MARK: - Локальное хранилище
    
    private func loadSessionsFromStorage() {
        guard let data = userDefaults.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([ReadingSession].self, from: data) else {
            return
        }
        sessions = decoded
        activeSession = sessions.first(where: { $0.isActive })
    }
    
    private func saveSessionsToStorage() {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        userDefaults.set(encoded, forKey: sessionsKey)
    }
    
    // MARK: - Управление сессиями
    
    func startSession(for bookId: UUID, startPage: Int = 0) -> ReadingSession {
        // Завершаем предыдущую активную сессию, если есть
        if let active = activeSession {
            var finished = active
            finished.isActive = false
            finished.endTime = Date()
            updateSession(finished)
        }
        
        let session = ReadingSession(
            bookId: bookId,
            startPage: startPage,
            isActive: true
        )
        
        sessions.insert(session, at: 0)
        activeSession = session
        saveSessionsToStorage()
        
        return session
    }
    
    func endSession(_ session: ReadingSession, endPage: Int? = nil, keyInsight: String? = nil) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        
        var finished = session
        finished.isActive = false
        finished.endTime = Date()
        finished.endPage = endPage
        finished.keyInsight = keyInsight
        
        sessions[index] = finished
        
        if activeSession?.id == session.id {
            activeSession = nil
        }
        
        saveSessionsToStorage()
    }
    
    func updateSession(_ session: ReadingSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index] = session
        
        if session.isActive {
            activeSession = session
        }
        
        saveSessionsToStorage()
    }
    
    func addNoteToSession(_ noteId: UUID, sessionId: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        var session = sessions[index]
        if !session.noteIds.contains(noteId) {
            session.noteIds.append(noteId)
            sessions[index] = session
            
            if activeSession?.id == sessionId {
                activeSession = session
            }
            
            saveSessionsToStorage()
        }
    }
    
    func deleteSession(_ session: ReadingSession) {
        sessions.removeAll { $0.id == session.id }
        
        if activeSession?.id == session.id {
            activeSession = nil
        }
        
        saveSessionsToStorage()
    }
    
    // MARK: - Фильтрация
    
    func sessions(for bookId: UUID) -> [ReadingSession] {
        sessions.filter { $0.bookId == bookId }
    }
    
    func recentSessions(limit: Int = 10) -> [ReadingSession] {
        Array(sessions.prefix(limit))
    }
    
    func sessionsToday() -> [ReadingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sessions.filter {
            calendar.isDate($0.startTime, inSameDayAs: today)
        }
    }
    
    // MARK: - Статистика
    
    func totalReadingTime(for bookId: UUID? = nil) -> TimeInterval {
        var filtered = sessions
        
        if let bookId = bookId {
            filtered = filtered.filter { $0.bookId == bookId }
        }
        
        return filtered.reduce(0) { $0 + $1.duration }
    }
    
    func totalPagesRead(for bookId: UUID? = nil) -> Int {
        var filtered = sessions
        
        if let bookId = bookId {
            filtered = filtered.filter { $0.bookId == bookId }
        }
        
        return filtered.reduce(0) { $0 + $1.pagesRead }
    }
    
    func formattedTotalTime(for bookId: UUID? = nil) -> String {
        let total = totalReadingTime(for: bookId)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) ч \(minutes) мин"
        } else {
            return "\(minutes) мин"
        }
    }
    
    func averageSessionDuration(for bookId: UUID? = nil) -> TimeInterval {
        var filtered = sessions.filter { !$0.isActive }
        
        if let bookId = bookId {
            filtered = filtered.filter { $0.bookId == bookId }
        }
        
        guard !filtered.isEmpty else { return 0 }
        
        let total = filtered.reduce(0) { $0 + $1.duration }
        return total / Double(filtered.count)
    }
    
    func sessionsCount(for bookId: UUID? = nil) -> Int {
        if let bookId = bookId {
            return sessions.filter { $0.bookId == bookId }.count
        }
        return sessions.count
    }
}

