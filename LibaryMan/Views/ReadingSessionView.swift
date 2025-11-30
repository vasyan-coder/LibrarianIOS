//
//  ReadingSessionView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Экран сессии чтения
struct ReadingSessionView: View {
    let book: Book
    
    @EnvironmentObject var bookService: BookService
    @EnvironmentObject var sessionService: SessionService
    @EnvironmentObject var noteService: NoteService
    @EnvironmentObject var chatService: ChatService
    @StateObject private var speechService = SpeechService()
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var session: ReadingSession?
    @State private var isRecording = false
    @State private var showingEndSession = false
    @State private var currentPage: Int = 0
    @State private var messageText = ""
    @State private var sessionNotes: [Note] = []
    @State private var expandedNoteId: UUID?
    @State private var keyInsight: String?
    @State private var isAnalyzing = false
    
    // Таймер для отображения длительности
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Фон
            backgroundView
            
            VStack(spacing: 0) {
                // Хедер
                headerView
                
                // Контент
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Статистика сессии
                        sessionStatsView
                        
                        // Ключевой инсайт
                        if let insight = keyInsight {
                            insightCard(insight)
                        } else if isAnalyzing {
                            analyzingCard
                        }
                        
                        // Заметки
                        if !sessionNotes.isEmpty {
                            notesSection
                        }
                        
                        Spacer(minLength: 200)
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, AppSpacing.md)
                }
                
                // Нижняя панель
                bottomPanel
            }
        }
        .onAppear {
            startSession()
        }
        .onDisappear {
            stopTimer()
        }
        .sheet(isPresented: $showingEndSession) {
            EndSessionSheet(
                session: session,
                book: book,
                notes: sessionNotes,
                onEnd: { endPage in
                    endSession(endPage: endPage)
                }
            )
        }
        .onChange(of: speechService.isRecording) { _, isNowRecording in
            // Когда запись останавливается, обрабатываем распознанный текст
            if !isNowRecording && !speechService.recognizedText.isEmpty {
                processRecognizedText(speechService.recognizedText)
            }
        }
    }
    
    // MARK: - Фон
    private var backgroundView: some View {
        ZStack {
            AppGradients.background
            
            // Свечение
            RadialGradient(
                colors: [
                    AppColors.orange.opacity(0.2),
                    AppColors.accent.opacity(0.1),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 600
            )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Хедер
    private var headerView: some View {
        HStack {
            // Кнопка закрытия
            GlassIconButton(icon: "xmark", size: 36, iconSize: 14) {
                if session != nil {
                    showingEndSession = true
                } else {
                    dismiss()
                }
            }
            
            Spacer()
            
            // Кнопка завершения
            Button("Готово") {
                showingEndSession = true
            }
            .font(AppTypography.headline)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, AppSpacing.md)
    }
    
    // MARK: - Статистика сессии
    private var sessionStatsView: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Сессия чтения")
                .font(AppTypography.largeTitle)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.xl) {
                // Время
                VStack(spacing: AppSpacing.xs) {
                    Text(formattedElapsedTime)
                        .font(.system(size: 32, weight: .light, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("ДЛИТЕЛЬНОСТЬ")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)
                }
                
                // Разделитель
                Text("—")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textMuted)
                
                // Страница
                VStack(spacing: AppSpacing.xs) {
                    Text("—")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("СТРАНИЦА")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)
                }
                
                // Разделитель
                Text("—")
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textMuted)
                
                // Вопросы
                VStack(spacing: AppSpacing.xs) {
                    Text("\(sessionNotes.filter { $0.type == .question }.count)")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("ВОПРОСОВ")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)
                }
            }
        }
        .padding(.vertical, AppSpacing.xl)
    }
    
    // MARK: - Карточка инсайта
    private func insightCard(_ insight: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("КЛЮЧЕВОЙ ИНСАЙТ")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                }
                
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppColors.accent)
                    
                    Text(insight)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Карточка анализа
    private var analyzingCard: some View {
        GlassCard {
            HStack(spacing: AppSpacing.md) {
                Text("КЛЮЧЕВОЙ ИНСАЙТ")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textMuted)
                    .tracking(1)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textMuted)
            }
            
            HStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                    .scaleEffect(0.8)
                
                Text("Анализируем сессию...")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Секция заметок
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("РАЗГОВОР")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
                .tracking(1)
            
            ForEach(Array(sessionNotes.enumerated()), id: \.element.id) { index, note in
                CompactNoteCard(
                    note: note,
                    number: index + 1,
                    isExpanded: expandedNoteId == note.id
                ) {
                    withAnimation(AppAnimations.spring) {
                        expandedNoteId = expandedNoteId == note.id ? nil : note.id
                    }
                }
            }
        }
    }
    
    // MARK: - Нижняя панель
    private var bottomPanel: some View {
        VStack(spacing: AppSpacing.md) {
            // Подсказки для вопросов
            if !isRecording {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        SuggestionChip(text: "Перекрёстные ссылки глав...") {
                            // Обработка
                        }
                        
                        SuggestionChip(text: "Кто такой \(book.author.components(separatedBy: " ").last ?? "автор")?") {
                            askQuestion("Кто такой \(book.author)?")
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                }
            }
            
            // Поле ввода или кнопка записи
            HStack(spacing: AppSpacing.md) {
                if isRecording {
                    // Показываем распознанный текст
                    Text(speechService.recognizedText.isEmpty ? "Говорите..." : speechService.recognizedText)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .fill(AppColors.cardBackground)
                        )
                } else {
                    // Поле ввода вопроса
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "command")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.accent)
                        
                        TextField("Спросите о книге...", text: $messageText)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .onSubmit {
                                if !messageText.isEmpty {
                                    askQuestion(messageText)
                                    messageText = ""
                                }
                            }
                    }
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                    )
                }
                
                // Кнопка записи
                FloatingActionButton(
                    icon: "mic.fill",
                    size: 56,
                    isRecording: isRecording
                ) {
                    toggleRecording()
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.top, AppSpacing.md)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Форматированное время
    private var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Методы
    
    private func startSession() {
        session = sessionService.startSession(for: book.id, startPage: book.currentPage)
        currentPage = book.currentPage
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func toggleRecording() {
        if isRecording {
            speechService.stopRecording()
            isRecording = false
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
    
    private func processRecognizedText(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Создаём заметку из распознанного текста
        let note = noteService.createNoteFromVoice(
            text: text,
            bookId: book.id,
            sessionId: session?.id,
            page: currentPage > 0 ? currentPage : nil
        )
        
        sessionNotes.insert(note, at: 0)
        
        // Добавляем в сессию
        if let sessionId = session?.id {
            sessionService.addNoteToSession(note.id, sessionId: sessionId)
        }
        
        // Отправляем голосовое сообщение в чат (все типы заметок)
        Task {
            await sendVoiceNoteToChat(note)
        }
        
        // Если это вопрос, получаем ответ от AI
        if note.type == .question {
            Task {
                await getAIResponse(for: note)
            }
        }
        
        // Очищаем распознанный текст
        speechService.recognizedText = ""
    }
    
    private func sendVoiceNoteToChat(_ note: Note) async {
        // Формируем сообщение с указанием типа заметки
        let prefix: String
        switch note.type {
        case .quote:
            prefix = "📖 Цитата: "
        case .thought:
            prefix = "💭 Мысль: "
        case .question:
            prefix = "❓ Вопрос: "
        }
        
        let messageContent = prefix + note.content
        
        do {
            try await chatService.sendMessage(
                messageContent,
                book: book,
                sessionId: nil
            )
        } catch {
            print("Ошибка отправки голосовой заметки в чат: \(error.localizedDescription)")
        }
    }
    
    private func askQuestion(_ question: String) {
        let note = Note(
            bookId: book.id,
            sessionId: session?.id,
            content: question,
            type: .question,
            source: .manual,
            page: currentPage > 0 ? currentPage : nil
        )
        
        noteService.addNote(note)
        sessionNotes.insert(note, at: 0)
        
        if let sessionId = session?.id {
            sessionService.addNoteToSession(note.id, sessionId: sessionId)
        }
        
        Task {
            await getAIResponse(for: note)
        }
    }
    
    private func getAIResponse(for note: Note) async {
        do {
            // Получаем ответ AI на вопрос (сообщение уже отправлено в sendVoiceNoteToChat)
            let response = try await chatService.answerNoteQuestion(note: note, book: book)
            
            // Обновляем заметку с ответом
            var updatedNote = note
            updatedNote.aiResponse = response
            noteService.updateNote(updatedNote)
            
            // Обновляем локальный список
            if let index = sessionNotes.firstIndex(where: { $0.id == note.id }) {
                sessionNotes[index] = updatedNote
            }
        } catch {
            print("Ошибка получения ответа AI: \(error.localizedDescription)")
        }
    }
    
    private func endSession(endPage: Int?) {
        stopTimer()
        
        // Обновляем прогресс книги
        if let endPage = endPage, endPage > 0 {
            var updatedBook = book
            updatedBook.currentPage = endPage
            
            // Если дочитали до конца — отмечаем как прочитанную
            if let pageCount = updatedBook.pageCount, endPage >= pageCount {
                updatedBook.status = .finished
                updatedBook.dateFinished = Date()
            } else if updatedBook.status == .wantToRead {
                // Если начали читать — меняем статус
                updatedBook.status = .reading
                updatedBook.dateStarted = Date()
            }
            
            Task {
                try? await bookService.updateBook(updatedBook)
            }
        }
        
        if let session = session {
            // Генерируем инсайт
            if !sessionNotes.isEmpty {
                isAnalyzing = true
                Task {
                    do {
                        let insight = try await chatService.generateSessionInsight(
                            session: session,
                            book: book,
                            notes: sessionNotes
                        )
                        keyInsight = insight
                        
                        sessionService.endSession(session, endPage: endPage, keyInsight: insight)
                    } catch {
                        sessionService.endSession(session, endPage: endPage)
                    }
                    isAnalyzing = false
                }
            } else {
                sessionService.endSession(session, endPage: endPage)
            }
        }
        
        dismiss()
    }
}

// MARK: - Чип подсказки
struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    Capsule()
                        .fill(AppColors.cardBackground)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Шторка завершения сессии
struct EndSessionSheet: View {
    let session: ReadingSession?
    let book: Book
    let notes: [Note]
    let onEnd: (Int?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var endPage: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.xl) {
                    // Статистика
                    VStack(spacing: AppSpacing.md) {
                        Text("Завершить сессию?")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let session = session {
                            Text("Вы читали \(session.formattedDuration)")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Text("Создано заметок: \(notes.count)")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textMuted)
                    }
                    
                    // Ввод страницы
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("На какой странице остановились?")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        GlassTextField(
                            placeholder: "Номер страницы",
                            text: $endPage,
                            icon: "book"
                        )
                        .keyboardType(.numberPad)
                    }
                    
                    Spacer()
                    
                    // Кнопки
                    VStack(spacing: AppSpacing.md) {
                        GlassButton("Завершить сессию", icon: "checkmark") {
                            let page = Int(endPage)
                            onEnd(page)
                            dismiss()
                        }
                        
                        Button("Продолжить чтение") {
                            dismiss()
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(AppSpacing.screenPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview
#Preview {
    ReadingSessionView(book: Book.sample)
        .environmentObject(BookService())
        .environmentObject(SessionService())
        .environmentObject(NoteService())
        .environmentObject(ChatService())
}

