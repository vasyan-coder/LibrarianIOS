//
//  NoteService.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Сервис заметок
class NoteService: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let notesKey = "saved_notes"
    
    init() {
        loadNotesFromStorage()
    }
    
    // MARK: - Локальное хранилище
    
    private func loadNotesFromStorage() {
        guard let data = userDefaults.data(forKey: notesKey),
              let decoded = try? JSONDecoder().decode([Note].self, from: data) else {
            // Загружаем примеры для демонстрации
            notes = Note.samples
            return
        }
        notes = decoded
    }
    
    private func saveNotesToStorage() {
        guard let encoded = try? JSONEncoder().encode(notes) else { return }
        userDefaults.set(encoded, forKey: notesKey)
    }
    
    // MARK: - CRUD операции
    
    func addNote(_ note: Note) {
        notes.insert(note, at: 0)
        saveNotesToStorage()
    }
    
    func updateNote(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updatedNote = note
        updatedNote.updatedAt = Date()
        notes[index] = updatedNote
        saveNotesToStorage()
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotesToStorage()
    }
    
    func deleteNotes(for bookId: UUID) {
        notes.removeAll { $0.bookId == bookId }
        saveNotesToStorage()
    }
    
    // MARK: - Фильтрация
    
    func notesForBook(_ bookId: UUID) -> [Note] {
        notes.filter { $0.bookId == bookId }
    }
    
    func notesForSession(_ sessionId: UUID) -> [Note] {
        notes.filter { $0.sessionId == sessionId }
    }
    
    func notes(ofType type: NoteType) -> [Note] {
        notes.filter { $0.type == type }
    }
    
    func notesForBook(_ bookId: UUID, ofType type: NoteType) -> [Note] {
        notes.filter { $0.bookId == bookId && $0.type == type }
    }
    
    // MARK: - Статистика
    
    func notesCount(for bookId: UUID) -> Int {
        notesForBook(bookId).count
    }
    
    func quotesCount(for bookId: UUID) -> Int {
        notesForBook(bookId, ofType: .quote).count
    }
    
    func questionsCount(for bookId: UUID) -> Int {
        notesForBook(bookId, ofType: .question).count
    }
    
    func thoughtsCount(for bookId: UUID) -> Int {
        notesForBook(bookId, ofType: .thought).count
    }
    
    // MARK: - Поиск
    
    func searchNotes(_ query: String, in bookId: UUID? = nil) -> [Note] {
        let lowercased = query.lowercased()
        
        var filtered = notes
        
        if let bookId = bookId {
            filtered = filtered.filter { $0.bookId == bookId }
        }
        
        return filtered.filter {
            $0.content.lowercased().contains(lowercased)
        }
    }
    
    // MARK: - Создание заметки из голоса
    
    func createNoteFromVoice(
        text: String,
        bookId: UUID,
        sessionId: UUID? = nil,
        page: Int? = nil
    ) -> Note {
        let type = Note.classifyFromRussianText(text)
        let cleanContent = Note.cleanTriggerWords(from: text)
        
        let note = Note(
            bookId: bookId,
            sessionId: sessionId,
            content: cleanContent,
            type: type,
            source: .voice,
            page: page
        )
        
        addNote(note)
        return note
    }
    
    // MARK: - Создание заметки из OCR
    
    func createNoteFromOCR(
        text: String,
        bookId: UUID,
        sessionId: UUID? = nil,
        page: Int? = nil
    ) -> Note {
        // OCR обычно захватывает цитаты
        let note = Note(
            bookId: bookId,
            sessionId: sessionId,
            content: text,
            type: .quote,
            source: .camera,
            page: page
        )
        
        addNote(note)
        return note
    }
}

