//
//  NotesView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Экран заметок
struct NotesView: View {
    @EnvironmentObject var noteService: NoteService
    @EnvironmentObject var bookService: BookService
    
    @State private var searchText = ""
    @State private var selectedType: NoteType?
    @State private var selectedBookId: UUID?
    @State private var expandedNoteId: UUID?
    
    private var filteredNotes: [Note] {
        var notes = noteService.notes
        
        // Фильтр по типу
        if let type = selectedType {
            notes = notes.filter { $0.type == type }
        }
        
        // Фильтр по книге
        if let bookId = selectedBookId {
            notes = notes.filter { $0.bookId == bookId }
        }
        
        // Поиск
        if !searchText.isEmpty {
            notes = notes.filter {
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return notes
    }
    
    private var groupedNotes: [(book: Book?, notes: [Note])] {
        let grouped = Dictionary(grouping: filteredNotes) { $0.bookId }
        
        return grouped.map { bookId, notes in
            let book = bookService.books.first { $0.id == bookId }
            return (book: book, notes: notes.sorted { $0.createdAt > $1.createdAt })
        }
        .sorted { group1, group2 in
            guard let first = group1.notes.first?.createdAt,
                  let second = group2.notes.first?.createdAt else {
                return false
            }
            return first > second
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                if noteService.notes.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Фильтры
                            filterSection
                            
                            // Статистика
                            statsSection
                            
                            // Заметки по книгам
                            notesListSection
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Заметки")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Поиск в заметках..."
            )
        }
    }
    
    // MARK: - Фон
    private var backgroundView: some View {
        ZStack {
            AppGradients.background
            AppGradients.warmGlow
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Фильтры
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // Все типы
                FilterChip(
                    title: "Все",
                    count: noteService.notes.count,
                    isSelected: selectedType == nil
                ) {
                    withAnimation(AppAnimations.quick) {
                        selectedType = nil
                    }
                }
                
                // По типам
                ForEach(NoteType.allCases, id: \.self) { type in
                    let count = noteService.notes(ofType: type).count
                    if count > 0 {
                        NoteTypeIndicator(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            withAnimation(AppAnimations.quick) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }
    
    // MARK: - Статистика
    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            MiniStatCard(
                value: "\(noteService.notes(ofType: .quote).count)",
                label: "Цитат",
                color: AppColors.noteQuote
            )
            
            MiniStatCard(
                value: "\(noteService.notes(ofType: .thought).count)",
                label: "Мыслей",
                color: AppColors.noteThought
            )
            
            MiniStatCard(
                value: "\(noteService.notes(ofType: .question).count)",
                label: "Вопросов",
                color: AppColors.noteQuestion
            )
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }
    
    // MARK: - Список заметок
    private var notesListSection: some View {
        LazyVStack(spacing: AppSpacing.xl) {
            ForEach(groupedNotes, id: \.book?.id) { group in
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // Заголовок книги
                    if let book = group.book {
                        HStack(spacing: AppSpacing.md) {
                            BookCoverView(book: book, size: .small)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(AppTypography.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                    .lineLimit(1)
                                
                                Text(book.author)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("\(group.notes.count)")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    // Заметки
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(group.notes) { note in
                            NoteCard(
                                note: note,
                                isExpanded: expandedNoteId == note.id
                            ) {
                                withAnimation(AppAnimations.spring) {
                                    expandedNoteId = expandedNoteId == note.id ? nil : note.id
                                }
                            } onDelete: {
                                withAnimation {
                                    noteService.deleteNote(note)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                }
            }
        }
    }
    
    // MARK: - Пустое состояние
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textMuted)
            
            Text("Нет заметок")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Начните сессию чтения и добавляйте заметки голосом или камерой")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
    }
}

// MARK: - Мини-карточка статистики
struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.title2)
                .foregroundColor(color)
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    NotesView()
        .environmentObject(NoteService())
        .environmentObject(BookService())
}

