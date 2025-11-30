//
//  BookDetailView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Экран деталей книги
struct BookDetailView: View {
    let book: Book
    
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var noteService: NoteService
    @EnvironmentObject var sessionService: SessionService
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditBook = false
    @State private var showingReadingSession = false
    @State private var showingStatusPicker = false
    @State private var showingDeleteAlert = false
    @State private var showingFullSummary = false
    @State private var currentBook: Book
    
    init(book: Book) {
        self.book = book
        _currentBook = State(initialValue: book)
    }
    
    private var bookNotes: [Note] {
        noteService.notesForBook(currentBook.id)
    }
    
    private var bookSessions: [ReadingSession] {
        sessionService.sessions(for: currentBook.id)
    }
    
    var body: some View {
        ZStack {
            // Фон с градиентом от обложки
            backgroundView
            
            ScrollView {
                VStack(spacing: 0) {
                    // Хедер с обложкой
                    headerSection
                    
                    // Информация о книге
                    VStack(spacing: AppSpacing.lg) {
                        // Статус и прогресс
                        statusSection
                        
                        // Описание
                        if let summary = currentBook.summary {
                            summarySection(summary)
                        }
                        
                        // Статистика
                        statsSection
                        
                        // Заметки
                        notesSection
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GlassIconButton(icon: "chevron.left", size: 36, iconSize: 14) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditBook = true
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Удалить книгу", systemImage: "trash")
                    }
                } label: {
                    Text("Редактировать")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
        }
        .alert("Удалить книгу?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                deleteBook()
            }
        } message: {
            Text("Книга «\(currentBook.title)» и все связанные заметки будут удалены. Это действие нельзя отменить.")
        }
        .sheet(isPresented: $showingEditBook) {
            EditBookView(book: currentBook) { updatedBook in
                currentBook = updatedBook
                Task {
                    try? await bookService.updateBook(updatedBook)
                }
            }
        }
        .fullScreenCover(isPresented: $showingReadingSession, onDismiss: {
            // Обновляем книгу из сервиса после закрытия сессии
            if let updatedBook = bookService.books.first(where: { $0.id == book.id }) {
                currentBook = updatedBook
            }
        }) {
            ReadingSessionView(book: currentBook)
        }
        .confirmationDialog("Статус чтения", isPresented: $showingStatusPicker) {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    updateStatus(status)
                }
            }
            Button("Отмена", role: .cancel) {}
        }
    }
    
    // MARK: - Фон
    private var backgroundView: some View {
        ZStack {
            AppGradients.background
            
            // Свечение от обложки
            if let _ = currentBook.coverURL {
                RadialGradient(
                    colors: [
                        AppColors.accent.opacity(0.3),
                        AppColors.orange.opacity(0.1),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
            } else {
                AppGradients.warmGlow
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Хедер
    private var headerSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Обложка
            BookCoverView(book: currentBook, size: .large)
                .shadow(color: AppColors.accent.opacity(0.3), radius: 30, y: 10)
            
            // Название и автор
            VStack(spacing: AppSpacing.sm) {
                Text(currentBook.title)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("автор: \(currentBook.author)")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
            }
            
            // Кнопка статуса
            Button {
                showingStatusPicker = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Text(currentBook.status.displayName)
                        .font(AppTypography.subheadline)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule()
                        .strokeBorder(AppColors.accent, lineWidth: 1)
                )
            }
        }
        .padding(.top, AppSpacing.xl)
        .padding(.bottom, AppSpacing.xxl)
    }
    
    // MARK: - Секция статуса
    private var statusSection: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                // Прогресс
                if currentBook.status == .reading, let pageCount = currentBook.pageCount {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Прогресс чтения")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(currentBook.currentPage) из \(pageCount) стр.")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        GlassProgressBar(progress: currentBook.readingProgress)
                    }
                }
                
                // Кнопка начала сессии
                GlassButton(
                    currentBook.status == .reading ? "Продолжить чтение" : "Начать чтение",
                    icon: "book.fill"
                ) {
                    showingReadingSession = true
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Описание
    private func summarySection(_ summary: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "doc.text")
                        .foregroundColor(AppColors.accent)
                    
                    Text("Описание")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    if summary.count > 200 {
                        Button {
                            withAnimation(AppAnimations.spring) {
                                showingFullSummary.toggle()
                            }
                        } label: {
                            Image(systemName: showingFullSummary ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                }
                
                Text(summary)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(showingFullSummary ? nil : 5)
                
                if summary.count > 200 && !showingFullSummary {
                    Button("Читать полностью") {
                        withAnimation(AppAnimations.spring) {
                            showingFullSummary = true
                        }
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
    
    // MARK: - Статистика
    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            StatCard(
                title: "Время чтения",
                value: sessionService.formattedTotalTime(for: currentBook.id),
                icon: "clock"
            )
            
            StatCard(
                title: "Сессий",
                value: "\(bookSessions.count)",
                icon: "calendar"
            )
            
            StatCard(
                title: "Заметок",
                value: "\(bookNotes.count)",
                icon: "note.text"
            )
        }
    }
    
    // MARK: - Заметки
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Заметки")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if !bookNotes.isEmpty {
                    Button("Все") {
                        // Показать все заметки
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.accent)
                }
            }
            
            if bookNotes.isEmpty {
                GlassCard {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "note.text")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.textMuted)
                        
                        Text("Пока нет заметок")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Начните сессию чтения, чтобы добавить заметки голосом или камерой")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                }
            } else {
                ForEach(bookNotes.prefix(3)) { note in
                    NoteCard(note: note)
                }
            }
        }
    }
    
    // MARK: - Методы
    private func updateStatus(_ status: ReadingStatus) {
        var updated = currentBook
        updated.status = status
        
        if status == .reading && updated.dateStarted == nil {
            updated.dateStarted = Date()
        } else if status == .finished {
            updated.dateFinished = Date()
            if let pageCount = updated.pageCount {
                updated.currentPage = pageCount
            }
        }
        
        currentBook = updated
        
        Task {
            try? await bookService.updateBook(updated)
        }
    }
    
    private func deleteBook() {
        Task {
            // Удаляем связанные заметки
            noteService.deleteNotes(for: currentBook.id)
            // Удаляем книгу
            try? await bookService.deleteBook(currentBook)
            // Закрываем экран
            dismiss()
        }
    }
}

// MARK: - Карточка статистики
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        GlassCard(padding: AppSpacing.md) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                
                Text(value)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        BookDetailView(book: Book.sample)
            .environmentObject(BookService())
            .environmentObject(NoteService())
            .environmentObject(SessionService())
    }
}

