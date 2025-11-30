//
//  ChatView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Экран чата
struct ChatView: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var bookService: BookService
    
    @State private var searchText = ""
    @State private var selectedSession: ChatSession?
    @State private var showingNewChat = false
    @State private var showingBookPicker = false
    
    private var groupedSessions: [(date: String, sessions: [ChatSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: chatService.chatSessions) { session -> String in
            if calendar.isDateInToday(session.updatedAt) {
                return "СЕГОДНЯ"
            } else if calendar.isDateInYesterday(session.updatedAt) {
                return "ВЧЕРА"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ru_RU")
                formatter.dateFormat = "d MMMM"
                return formatter.string(from: session.updatedAt).uppercased()
            }
        }
        
        return grouped.map { (date: $0.key, sessions: $0.value) }
            .sorted { session1, session2 in
                guard let first = session1.sessions.first?.updatedAt,
                      let second = session2.sessions.first?.updatedAt else {
                    return false
                }
                return first > second
            }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                if chatService.chatSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Чат")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.sm) {
                        GlassIconButton(icon: "plus.bubble", size: 36, iconSize: 16) {
                            showingBookPicker = true
                        }
                        
                        GlassIconButton(icon: "magnifyingglass", size: 36, iconSize: 16) {
                            // Поиск
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedSession) { session in
                if let book = bookService.books.first(where: { $0.id == session.bookId }) {
                    ChatDetailView(session: session, book: book)
                        .environmentObject(chatService)
                }
            }
            .sheet(isPresented: $showingBookPicker) {
                NewChatBookPicker(onSelectBook: { book in
                    startNewChat(with: book)
                })
                .environmentObject(bookService)
            }
        }
    }
    
    private func startNewChat(with book: Book) {
        let session = chatService.createSession(for: book.id)
        selectedSession = session
    }
    
    // MARK: - Фон
    private var backgroundView: some View {
        ZStack {
            AppGradients.background
            AppGradients.warmGlow
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Список сессий
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg, pinnedViews: .sectionHeaders) {
                ForEach(groupedSessions, id: \.date) { group in
                    Section {
                        ForEach(group.sessions) { session in
                            ChatSessionCard(
                                session: session,
                                book: bookService.books.first { $0.id == session.bookId }
                            ) {
                                selectedSession = session
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.date)
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textSecondary)
                                .tracking(1)
                            
                            Spacer()
                            
                            Text("\(group.sessions.count) \(pluralizeSession(group.sessions.count))")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Rectangle()
                                .fill(AppColors.background.opacity(0.8))
                                .blur(radius: 10)
                        )
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Пустое состояние
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textMuted)
            
            Text("Нет разговоров")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Задавайте вопросы о книгах во время сессий чтения, или начните новый чат")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            
            if !bookService.books.isEmpty {
                GlassButton("Начать чат о книге", icon: "plus.bubble") {
                    showingBookPicker = true
                }
            }
        }
    }
    
    private func pluralizeSession(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        
        if mod100 >= 11 && mod100 <= 19 {
            return "сессий"
        }
        
        switch mod10 {
        case 1:
            return "сессия"
        case 2, 3, 4:
            return "сессии"
        default:
            return "сессий"
        }
    }
}

// MARK: - Карточка сессии чата
struct ChatSessionCard: View {
    let session: ChatSession
    let book: Book?
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    // Время
                    Text(formattedTime)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                    
                    Text("Только начато")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textMuted)
                }
                .frame(width: 50)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    // Название книги
                    if let book = book {
                        Text(book.title.uppercased())
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(0.5)
                    }
                    
                    // Заголовок сессии
                    Text(session.displayTitle)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                    
                    // Количество сообщений
                    Text("\(session.messageCount) \(pluralizeItem(session.messageCount))")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(AppColors.glassBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, AppSpacing.screenPadding)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "H:mm"
        return formatter.string(from: session.updatedAt)
    }
    
    private func pluralizeItem(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        
        if mod100 >= 11 && mod100 <= 19 {
            return "элементов"
        }
        
        switch mod10 {
        case 1:
            return "элемент"
        case 2, 3, 4:
            return "элемента"
        default:
            return "элементов"
        }
    }
}

// MARK: - Детальный экран чата
struct ChatDetailView: View {
    let session: ChatSession
    let book: Book
    
    @EnvironmentObject var chatService: ChatService
    @Environment(\.dismiss) private var dismiss
    
    @State private var messageText = ""
    @State private var isRecording = false
    @FocusState private var isInputFocused: Bool
    
    // Получаем актуальную сессию из сервиса (ищем по bookId, чтобы видеть все сообщения)
    private var currentSession: ChatSession {
        // Сначала пробуем найти по ID сессии
        if let found = chatService.chatSessions.first(where: { $0.id == session.id }) {
            return found
        }
        // Если не нашли, ищем любую сессию для этой книги
        if let found = chatService.chatSessions.first(where: { $0.bookId == book.id }) {
            return found
        }
        return session
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Кастомный хедер
            chatHeader
            
            // Сообщения
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(currentSession.messages.filter { $0.role != .system }) { message in
                            ChatMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if chatService.isLoading {
                            LoadingBubble()
                        }
                    }
                    .padding()
                }
                .onChange(of: currentSession.messages.count) { _, _ in
                    if let lastMessage = currentSession.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Поле ввода
            inputSection
        }
        .background(backgroundView)
        .navigationBarHidden(true)
    }
    
    private var chatHeader: some View {
        HStack(spacing: AppSpacing.md) {
            // Кнопка назад
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
            
            Spacer()
            
            // Название книги
            VStack(spacing: 2) {
                Text(book.title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Пустое место для симметрии
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, AppSpacing.sm)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }
    
    private var backgroundView: some View {
        ZStack {
            AppGradients.background
            AppGradients.warmGlow
        }
        .ignoresSafeArea()
    }
    
    private var inputSection: some View {
        HStack(spacing: AppSpacing.sm) {
            // Текстовое поле
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "command")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accent)
                
                TextField("Спросите о книге...", text: $messageText)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
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
            
            // Кнопка записи/отправки
            GlassIconButton(
                icon: messageText.isEmpty ? "waveform" : "arrow.up",
                size: 44,
                iconSize: 18,
                isActive: !messageText.isEmpty
            ) {
                if messageText.isEmpty {
                    isRecording.toggle()
                } else {
                    sendMessage()
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let text = messageText
        messageText = ""
        isInputFocused = false
        
        Task {
            try? await chatService.sendMessage(
                text,
                book: book,
                sessionId: currentSession.id
            )
        }
    }
}

// MARK: - Пузырь сообщения
struct ChatMessageBubble: View {
    let message: ChatMessage
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: AppSpacing.xs) {
                Text(message.content)
                    .font(AppTypography.body)
                    .foregroundColor(isUser ? AppColors.background : AppColors.textPrimary)
                
                Text(formattedTime)
                    .font(AppTypography.caption2)
                    .foregroundColor(isUser ? AppColors.background.opacity(0.7) : AppColors.textMuted)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(isUser ? AppColors.accent : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .strokeBorder(
                        isUser ? AppColors.accentLight.opacity(0.3) : AppColors.glassBorder,
                        lineWidth: 1
                    )
            )
            
            if !isUser { Spacer() }
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "H:mm"
        return formatter.string(from: message.createdAt)
    }
}

// MARK: - Индикатор загрузки
struct LoadingBubble: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppColors.textMuted)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animationPhase
                        )
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.cardBackground)
            )
            
            Spacer()
        }
        .onAppear {
            animationPhase = 2
        }
    }
}

// MARK: - Выбор книги для нового чата
struct NewChatBookPicker: View {
    @EnvironmentObject var bookService: BookService
    @Environment(\.dismiss) private var dismiss
    
    let onSelectBook: (Book) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                if bookService.books.isEmpty {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.textMuted)
                        
                        Text("Нет книг")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Сначала добавьте книгу в библиотеку")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(bookService.books) { book in
                                Button {
                                    onSelectBook(book)
                                    dismiss()
                                } label: {
                                    HStack(spacing: AppSpacing.md) {
                                        BookCoverView(book: book, size: .small)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(book.title)
                                                .font(AppTypography.headline)
                                                .foregroundColor(AppColors.textPrimary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            
                                            Text(book.author)
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textMuted)
                                    }
                                    .padding(AppSpacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                            .fill(AppColors.cardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                            .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(AppSpacing.screenPadding)
                    }
                }
            }
            .navigationTitle("Выберите книгу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview
#Preview {
    ChatView()
        .environmentObject(ChatService())
        .environmentObject(BookService())
}

