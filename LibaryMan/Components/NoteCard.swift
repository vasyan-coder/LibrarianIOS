//
//  NoteCard.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Карточка заметки
struct NoteCard: View {
    let note: Note
    var isExpanded: Bool = false
    var onTap: () -> Void = {}
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Заголовок
            HStack(spacing: AppSpacing.sm) {
                // Иконка типа
                Image(systemName: note.type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(noteTypeColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(noteTypeColor.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.type.displayName)
                        .font(AppTypography.caption)
                        .foregroundColor(noteTypeColor)
                    
                    if let page = note.page {
                        Text("Стр. \(page)")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textMuted)
                    }
                }
                
                Spacer()
                
                // Источник
                Image(systemName: note.source.icon)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textMuted)
                
                // Время
                Text(formattedTime)
                    .font(AppTypography.caption2)
                    .foregroundColor(AppColors.textMuted)
                
                // Кнопка раскрытия
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            
            // Контент
            contentView
            
            // AI ответ (если есть и раскрыто)
            if isExpanded, let aiResponse = note.aiResponse {
                Divider()
                    .background(AppColors.glassBorder)
                
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accent)
                    
                    Text(aiResponse)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .italic()
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            noteTypeColor.opacity(0.3),
                            AppColors.glassBorder
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            }
            
            Button {
                UIPasteboard.general.string = note.content
            } label: {
                Label("Копировать", systemImage: "doc.on.doc")
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch note.type {
        case .quote:
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Rectangle()
                    .fill(noteTypeColor)
                    .frame(width: 3)
                    .cornerRadius(1.5)
                
                Text(note.content)
                    .font(AppTypography.quote)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(isExpanded ? nil : 3)
            }
            
        case .question:
            Text(note.content)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(isExpanded ? nil : 3)
            
        case .thought:
            Text(note.content)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(isExpanded ? nil : 3)
        }
    }
    
    private var noteTypeColor: Color {
        switch note.type {
        case .thought: return AppColors.noteThought
        case .quote: return AppColors.noteQuote
        case .question: return AppColors.noteQuestion
        }
    }
    
    private var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: note.createdAt, relativeTo: Date())
    }
}

// MARK: - Компактная карточка заметки (для списка в сессии)
struct CompactNoteCard: View {
    let note: Note
    var number: Int?
    var isExpanded: Bool = false
    var onTap: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                // Номер
                if let number = number {
                    Text(String(format: "%02d", number))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                        .frame(width: 24)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    // Заголовок заметки
                    Text(note.content)
                        .font(note.type == .quote ? AppTypography.bodySerif : AppTypography.body)
                        .fontWeight(note.type == .question ? .medium : .regular)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    // AI ответ
                    if isExpanded, let aiResponse = note.aiResponse {
                        Text(aiResponse)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .italic()
                            .padding(.top, AppSpacing.xs)
                    }
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            
            // Разделитель
            if !isExpanded {
                Rectangle()
                    .fill(AppColors.glassBorder)
                    .frame(height: 1)
                    .padding(.leading, number != nil ? 36 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Индикатор типа заметки
struct NoteTypeIndicator: View {
    let type: NoteType
    var isSelected: Bool = false
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                
                Text(type.displayName)
                    .font(AppTypography.caption)
            }
            .foregroundColor(isSelected ? AppColors.background : typeColor)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? typeColor : typeColor.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .strokeBorder(typeColor.opacity(0.5), lineWidth: 1)
            )
        }
    }
    
    private var typeColor: Color {
        switch type {
        case .thought: return AppColors.noteThought
        case .quote: return AppColors.noteQuote
        case .question: return AppColors.noteQuestion
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppGradients.background
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Фильтры типов
                HStack(spacing: AppSpacing.sm) {
                    ForEach(NoteType.allCases, id: \.self) { type in
                        NoteTypeIndicator(type: type, isSelected: type == .quote)
                    }
                }
                
                // Карточки заметок
                ForEach(Note.samples) { note in
                    NoteCard(note: note, isExpanded: note.type == .question)
                }
                
                // Компактные карточки
                GlassCard {
                    VStack(spacing: 0) {
                        ForEach(Array(Note.samples.enumerated()), id: \.element.id) { index, note in
                            CompactNoteCard(
                                note: note,
                                number: index + 1,
                                isExpanded: index == 0
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

