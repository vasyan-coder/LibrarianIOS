//
//  BookCoverView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Размеры обложки
enum BookCoverSize {
    case small      // Для списков
    case medium     // Для сетки
    case large      // Для детальной страницы
    
    var width: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 120
        case .large: return 180
        }
    }
    
    var height: CGFloat {
        width * 1.5
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 10
        case .large: return 14
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 8
        case .large: return 16
        }
    }
}

// MARK: - Компонент обложки книги
struct BookCoverView: View {
    let book: Book
    var size: BookCoverSize = .medium
    var showProgress: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Обложка
            coverImage
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: size.shadowRadius,
                    x: 0,
                    y: size.shadowRadius / 2
                )
            
            // Прогресс чтения
            if showProgress && book.status == .reading && book.readingProgress > 0 {
                progressOverlay
            }
        }
    }
    
    @ViewBuilder
    private var coverImage: some View {
        if let coverURL = book.coverURL, let url = URL(string: coverURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderView
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else if let localData = book.localCoverData,
                  let uiImage = UIImage(data: localData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                colors: [
                    colorForTitle(book.title),
                    colorForTitle(book.title).opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Паттерн
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    for i in stride(from: 0, to: width + height, by: 20) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: i))
                    }
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
            
            // Текст
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: size == .large ? 40 : size == .medium ? 28 : 18))
                    .foregroundColor(.white.opacity(0.8))
                
                if size != .small {
                    Text(book.title)
                        .font(size == .large ? AppTypography.headline : AppTypography.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, AppSpacing.sm)
                }
            }
        }
    }
    
    private var progressOverlay: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(AppColors.accent)
                    .frame(width: size.width * book.readingProgress, height: 4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
    
    // Генерация цвета на основе названия
    private func colorForTitle(_ title: String) -> Color {
        let hash = title.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.5, brightness: 0.4)
    }
}

// MARK: - Карточка книги для сетки
struct BookGridCard: View {
    let book: Book
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                BookCoverView(book: book, size: .medium, showProgress: true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(AppTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.author)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: BookCoverSize.medium.width)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Карточка книги для списка
struct BookListCard: View {
    let book: Book
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                BookCoverView(book: book, size: .small, showProgress: true)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(book.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.author)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Label(book.status.displayName, systemImage: book.status.icon)
                            .font(AppTypography.caption)
                            .foregroundColor(book.status.color)
                        
                        if book.status == .reading {
                            Text("•")
                                .foregroundColor(AppColors.textMuted)
                            Text(book.progressText)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
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
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppGradients.background
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Большая обложка
                BookCoverView(book: Book.sample, size: .large, showProgress: true)
                
                // Сетка
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.lg) {
                    ForEach(Book.samples) { book in
                        BookGridCard(book: book)
                    }
                }
                .padding(.horizontal)
                
                // Список
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Book.samples) { book in
                        BookListCard(book: book)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

