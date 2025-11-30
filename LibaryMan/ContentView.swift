//
//  ContentView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Главный экран приложения
struct ContentView: View {
    @StateObject private var bookService = BookService()
    @StateObject private var noteService = NoteService()
    @StateObject private var sessionService = SessionService()
    @StateObject private var chatService = ChatService()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var selectedTab: AppTab = .library
    @State private var showingAddBook = false
    @State private var showingQuickRecord = false
    @State private var showingSettings = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainContent
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Контент вкладок
            Group {
                switch selectedTab {
                case .library:
                    LibraryView(showingSettings: $showingSettings)
                case .notes:
                    NotesView()
                case .chat:
                    ChatView()
                }
            }
            .environmentObject(bookService)
            .environmentObject(noteService)
            .environmentObject(sessionService)
            .environmentObject(chatService)
            
            // Кастомный TabBar
            CustomTabBar(
                selectedTab: $selectedTab,
                onAddTap: {
                    showingAddBook = true
                },
                onRecordTap: {
                    showingQuickRecord = true
                }
            )
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView()
                .environmentObject(bookService)
        }
        .sheet(isPresented: $showingQuickRecord) {
            QuickRecordView()
                .environmentObject(bookService)
                .environmentObject(noteService)
                .environmentObject(sessionService)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Быстрая запись заметки
struct QuickRecordView: View {
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var noteService: NoteService
    @EnvironmentObject var sessionService: SessionService
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = SpeechService()
    
    @State private var selectedBook: Book?
    @State private var isRecording = false
    @State private var showBookPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                ZStack {
                    AppGradients.background
                    
                    RadialGradient(
                        colors: [
                            AppColors.orange.opacity(0.3),
                            AppColors.accent.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                }
                .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.xl) {
                    Spacer()
                    
                    // Выбор книги
                    if let book = selectedBook {
                        Button {
                            showBookPicker = true
                        } label: {
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
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .fill(AppColors.cardBackground)
                            )
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                    } else {
                        GlassButton("Выберите книгу", icon: "book", style: .secondary) {
                            showBookPicker = true
                        }
                    }
                    
                    // Распознанный текст
                    if isRecording || !speechService.recognizedText.isEmpty {
                        GlassCard {
                            Text(speechService.recognizedText.isEmpty ? "Говорите..." : speechService.recognizedText)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 100)
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    
                    Spacer()
                    
                    // Кнопка записи
                    FloatingActionButton(
                        icon: "mic.fill",
                        size: 80,
                        isRecording: isRecording
                    ) {
                        toggleRecording()
                    }
                    .disabled(selectedBook == nil)
                    .opacity(selectedBook == nil ? 0.5 : 1)
                    
                    Text(isRecording ? "Нажмите, чтобы остановить" : "Нажмите, чтобы начать запись")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                    
                    Spacer()
                }
            }
            .navigationTitle("Быстрая заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GlassIconButton(icon: "xmark", size: 36, iconSize: 14) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBookPicker) {
                BookPickerView(selectedBook: $selectedBook)
                    .environmentObject(bookService)
            }
            .onAppear {
                // Автоматически выбираем книгу, которую сейчас читаем
                selectedBook = bookService.books.first { $0.status == .reading }
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            speechService.stopRecording()
            isRecording = false
            
            // Сохраняем заметку
            if let book = selectedBook, !speechService.recognizedText.isEmpty {
                let _ = noteService.createNoteFromVoice(
                    text: speechService.recognizedText,
                    bookId: book.id,
                    sessionId: sessionService.activeSession?.id,
                    page: book.currentPage > 0 ? book.currentPage : nil
                )
                
                // Очищаем и закрываем
                speechService.recognizedText = ""
                dismiss()
            }
        } else {
            Task {
                do {
                    try await speechService.startRecording()
                    isRecording = true
                } catch {
                    print("Ошибка записи: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Выбор книги
struct BookPickerView: View {
    @EnvironmentObject var bookService: BookService
    @Binding var selectedBook: Book?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(bookService.books) { book in
                            Button {
                                selectedBook = book
                                dismiss()
                            } label: {
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
                                    
                                    if selectedBook?.id == book.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.accent)
                                    }
                                }
                                .padding(AppSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .fill(selectedBook?.id == book.id ? AppColors.accent.opacity(0.1) : AppColors.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .strokeBorder(
                                            selectedBook?.id == book.id ? AppColors.accent : AppColors.glassBorder,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                    .padding(AppSpacing.screenPadding)
                }
            }
            .navigationTitle("Выберите книгу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
