//
//  LibraryView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Экран библиотеки
struct LibraryView: View {
    @EnvironmentObject var bookService: BookService
    @Binding var showingSettings: Bool
    
    @State private var searchText = ""
    @State private var isGridView = true
    @State private var selectedFilter: ReadingStatus?
    @State private var showingAddBook = false
    @State private var selectedBook: Book?
    
    private var filteredBooks: [Book] {
        var books = bookService.books
        
        // Фильтр по статусу
        if let filter = selectedFilter {
            books = books.filter { $0.status == filter }
        }
        
        // Поиск
        if !searchText.isEmpty {
            books = books.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return books
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                backgroundView
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Фильтры
                        filterSection
                        
                        // Контент
                        if filteredBooks.isEmpty {
                            emptyStateView
                        } else if isGridView {
                            gridView
                        } else {
                            listView
                        }
                    }
                    .padding(.bottom, 100) // Отступ для TabBar
                }
            }
            .navigationTitle("Библиотека")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.sm) {
                        // Переключатель вида
                        GlassIconButton(
                            icon: isGridView ? "rectangle.grid.2x2" : "list.bullet",
                            size: 36,
                            iconSize: 16
                        ) {
                            withAnimation(AppAnimations.spring) {
                                isGridView.toggle()
                            }
                        }
                        
                        // Настройки
                        GlassIconButton(icon: "gearshape", size: 36, iconSize: 16) {
                            showingSettings = true
                        }
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Поиск книг..."
            )
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .navigationDestination(item: $selectedBook) { book in
                BookDetailView(book: book)
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
    
    // MARK: - Секция фильтров
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // Все книги
                FilterChip(
                    title: "Все",
                    count: bookService.books.count,
                    isSelected: selectedFilter == nil
                ) {
                    withAnimation(AppAnimations.quick) {
                        selectedFilter = nil
                    }
                }
                
                // По статусам
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    let count = bookService.booksByStatus(status).count
                    if count > 0 {
                        FilterChip(
                            title: status.displayName,
                            icon: status.icon,
                            count: count,
                            isSelected: selectedFilter == status,
                            color: status.color
                        ) {
                            withAnimation(AppAnimations.quick) {
                                selectedFilter = selectedFilter == status ? nil : status
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }
    
    // MARK: - Сетка книг
    private var gridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.lg),
                GridItem(.flexible(), spacing: AppSpacing.lg)
            ],
            spacing: AppSpacing.xl
        ) {
            ForEach(filteredBooks) { book in
                BookGridCard(book: book) {
                    selectedBook = book
                }
                .contextMenu {
                    bookContextMenu(for: book)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .animation(AppAnimations.spring, value: filteredBooks.map { $0.id })
    }
    
    // MARK: - Список книг
    private var listView: some View {
        LazyVStack(spacing: AppSpacing.sm) {
            ForEach(filteredBooks) { book in
                BookListCard(book: book) {
                    selectedBook = book
                }
                .contextMenu {
                    bookContextMenu(for: book)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .animation(AppAnimations.spring, value: filteredBooks.map { $0.id })
    }
    
    // MARK: - Контекстное меню книги
    @ViewBuilder
    private func bookContextMenu(for book: Book) -> some View {
        Button {
            selectedBook = book
        } label: {
            Label("Открыть", systemImage: "book")
        }
        
        Divider()
        
        Menu {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                Button {
                    updateBookStatus(book, to: status)
                } label: {
                    Label(status.displayName, systemImage: status.icon)
                }
            }
        } label: {
            Label("Изменить статус", systemImage: "bookmark")
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteBook(book)
        } label: {
            Label("Удалить", systemImage: "trash")
        }
    }
    
    // MARK: - Действия
    private func updateBookStatus(_ book: Book, to status: ReadingStatus) {
        var updatedBook = book
        updatedBook.status = status
        
        if status == .reading && updatedBook.dateStarted == nil {
            updatedBook.dateStarted = Date()
        } else if status == .finished {
            updatedBook.dateFinished = Date()
        }
        
        Task {
            try? await bookService.updateBook(updatedBook)
        }
    }
    
    private func deleteBook(_ book: Book) {
        Task {
            try? await bookService.deleteBook(book)
        }
    }
    
    // MARK: - Пустое состояние
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textMuted)
            
            Text(searchText.isEmpty ? "Ваша библиотека пуста" : "Ничего не найдено")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text(searchText.isEmpty
                 ? "Добавьте первую книгу, чтобы начать"
                 : "Попробуйте изменить запрос")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                GlassButton("Добавить книгу", icon: "plus") {
                    showingAddBook = true
                }
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Чип фильтра
struct FilterChip: View {
    let title: String
    var icon: String?
    var count: Int?
    var isSelected: Bool = false
    var color: Color = AppColors.accent
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                
                Text(title)
                    .font(AppTypography.subheadline)
                
                if let count = count {
                    Text("\(count)")
                        .font(AppTypography.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : AppColors.glassBackground)
                        )
                }
            }
            .foregroundColor(isSelected ? AppColors.background : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? color : AppColors.glassBackground)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? color.opacity(0.5) : AppColors.glassBorder,
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Preview
#Preview {
    LibraryView(showingSettings: .constant(false))
        .environmentObject(BookService())
}

