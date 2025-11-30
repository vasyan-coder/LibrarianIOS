//
//  AddBookView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Экран добавления книги
struct AddBookView: View {
    @EnvironmentObject var bookService: BookService
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var showManualEntry = false
    @State private var showISBNScanner = false
    @State private var errorMessage: String?
    
    // Для ручного ввода
    @State private var manualTitle = ""
    @State private var manualAuthor = ""
    @State private var manualISBN = ""
    @State private var manualPageCount = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                VStack(spacing: 0) {
                    // Поиск
                    searchSection
                    
                    // Контент
                    if showManualEntry {
                        manualEntryForm
                    } else {
                        searchResultsView
                    }
                }
            }
            .navigationTitle("Добавить книгу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.md) {
                        // Сканер ISBN
                        Button {
                            showISBNScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(AppColors.accent)
                        
                        Button(showManualEntry ? "Поиск" : "Вручную") {
                            withAnimation(AppAnimations.spring) {
                                showManualEntry.toggle()
                            }
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            }
            .fullScreenCover(isPresented: $showISBNScanner) {
                ISBNScannerView()
                    .environmentObject(bookService)
            }
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
    
    // MARK: - Секция поиска
    private var searchSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Название, автор или ISBN...", text: $searchQuery)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textMuted)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(AppColors.glassBorder, lineWidth: 1)
            )
            
            // Подсказка
            if !showManualEntry {
                Text("Поиск по Google Books. Для русских книг лучше искать по ISBN.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, AppSpacing.md)
    }
    
    // MARK: - Результаты поиска
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                        .padding(.top, AppSpacing.xxl)
                } else if let error = errorMessage {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.warning)
                        
                        Text(error)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.xxl)
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    emptySearchState
                } else if searchResults.isEmpty {
                    initialState
                } else {
                    ForEach(searchResults) { book in
                        SearchResultCard(book: book) {
                            addBook(book)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.vertical, AppSpacing.lg)
        }
    }
    
    // MARK: - Начальное состояние
    private var initialState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textMuted)
            
            Text("Найдите книгу")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Введите название, имя автора или ISBN для поиска")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xxl)
    }
    
    // MARK: - Пустой результат поиска
    private var emptySearchState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(AppColors.textMuted)
            
            Text("Ничего не найдено")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Попробуйте изменить запрос или добавьте книгу вручную")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            GlassButton("Добавить вручную", icon: "plus", style: .secondary) {
                withAnimation(AppAnimations.spring) {
                    showManualEntry = true
                }
            }
        }
        .padding(.top, AppSpacing.xxl)
    }
    
    // MARK: - Форма ручного ввода
    private var manualEntryForm: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Название книги *")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    GlassTextField(
                        placeholder: "Например: Мастер и Маргарита",
                        text: $manualTitle,
                        icon: "book"
                    )
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Автор *")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    GlassTextField(
                        placeholder: "Например: Михаил Булгаков",
                        text: $manualAuthor,
                        icon: "person"
                    )
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("ISBN (необязательно)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    GlassTextField(
                        placeholder: "978-5-17-090335-1",
                        text: $manualISBN,
                        icon: "barcode"
                    )
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Количество страниц (необязательно)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    GlassTextField(
                        placeholder: "480",
                        text: $manualPageCount,
                        icon: "doc.text"
                    )
                    .keyboardType(.numberPad)
                }
                
                Spacer(minLength: AppSpacing.xl)
                
                GlassButton("Добавить книгу", icon: "plus") {
                    addManualBook()
                }
                .disabled(manualTitle.isEmpty || manualAuthor.isEmpty)
                .opacity(manualTitle.isEmpty || manualAuthor.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.vertical, AppSpacing.lg)
        }
    }
    
    // MARK: - Методы
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                // Проверяем, похоже ли на ISBN
                let cleanQuery = searchQuery.replacingOccurrences(of: "-", with: "")
                if cleanQuery.count >= 10 && cleanQuery.allSatisfy({ $0.isNumber || $0 == "X" }) {
                    if let book = try await bookService.searchByISBN(searchQuery) {
                        searchResults = [book]
                    } else {
                        searchResults = []
                    }
                } else {
                    searchResults = try await bookService.searchBooks(query: searchQuery)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isSearching = false
        }
    }
    
    private func addBook(_ book: Book) {
        Task {
            try? await bookService.saveBook(book)
            dismiss()
        }
    }
    
    private func addManualBook() {
        let book = Book(
            title: manualTitle,
            author: manualAuthor,
            isbn: manualISBN.isEmpty ? nil : manualISBN,
            pageCount: Int(manualPageCount)
        )
        
        Task {
            try? await bookService.saveBook(book)
            dismiss()
        }
    }
}

// MARK: - Карточка результата поиска
struct SearchResultCard: View {
    let book: Book
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            BookCoverView(book: book, size: .small)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(book.title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: AppSpacing.sm) {
                    if let year = book.publishedYear {
                        Text("\(year)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)
                    }
                    
                    if let pages = book.pageCount {
                        Text("•")
                            .foregroundColor(AppColors.textMuted)
                        Text("\(pages) стр.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.accent)
            }
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

// MARK: - Экран редактирования книги
struct EditBookView: View {
    let book: Book
    let onSave: (Book) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var author: String
    @State private var isbn: String
    @State private var pageCount: String
    @State private var currentPage: String
    @State private var selectedStatus: ReadingStatus
    
    init(book: Book, onSave: @escaping (Book) -> Void) {
        self.book = book
        self.onSave = onSave
        
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _isbn = State(initialValue: book.isbn ?? "")
        _pageCount = State(initialValue: book.pageCount.map { String($0) } ?? "")
        _currentPage = State(initialValue: String(book.currentPage))
        _selectedStatus = State(initialValue: book.status)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Обложка
                        BookCoverView(book: book, size: .large)
                            .padding(.top, AppSpacing.lg)
                        
                        // Форма
                        VStack(spacing: AppSpacing.lg) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Название")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                GlassTextField(placeholder: "Название книги", text: $title)
                            }
                            
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Автор")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                GlassTextField(placeholder: "Автор", text: $author)
                            }
                            
                            HStack(spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("Всего страниц")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    GlassTextField(placeholder: "0", text: $pageCount)
                                        .keyboardType(.numberPad)
                                }
                                
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("Текущая страница")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    GlassTextField(placeholder: "0", text: $currentPage)
                                        .keyboardType(.numberPad)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Статус")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppSpacing.sm) {
                                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                                            FilterChip(
                                                title: status.displayName,
                                                icon: status.icon,
                                                isSelected: selectedStatus == status,
                                                color: status.color
                                            ) {
                                                selectedStatus = status
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                        
                        Spacer(minLength: AppSpacing.xxl)
                        
                        GlassButton("Сохранить", icon: "checkmark") {
                            saveChanges()
                        }
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedBook = book
        updatedBook.title = title
        updatedBook.author = author
        updatedBook.isbn = isbn.isEmpty ? nil : isbn
        updatedBook.pageCount = Int(pageCount)
        updatedBook.currentPage = Int(currentPage) ?? 0
        updatedBook.status = selectedStatus
        
        onSave(updatedBook)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddBookView()
        .environmentObject(BookService())
}

