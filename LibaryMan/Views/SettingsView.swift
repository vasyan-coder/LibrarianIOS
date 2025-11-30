//
//  SettingsView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Экран настроек
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    @State private var showingImportSheet = false
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Профиль / О приложении
                        appInfoSection
                        
                        // Библиотека
                        librarySection
                        
                        // Голосовые заметки
                        voiceSection
                        
                        // Внешний вид
                        appearanceSection
                        
                        // Данные
                        dataSection
                        
                        // О приложении
                        aboutSection
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.accent)
                }
            }
            .alert("Сбросить данные?", isPresented: $showingResetAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Сбросить", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Все книги, заметки и сессии чтения будут удалены. Это действие нельзя отменить.")
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
    
    // MARK: - Информация о приложении
    private var appInfoSection: some View {
        GlassCard {
            HStack(spacing: AppSpacing.md) {
                // Иконка приложения
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent, AppColors.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Читалка")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Версия 1.0.0")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Секция библиотеки
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("БИБЛИОТЕКА")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
                .tracking(1)
                .padding(.leading, AppSpacing.sm)
            
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "square.and.arrow.down",
                        title: "Импорт из CSV",
                        subtitle: "Загрузить список книг"
                    ) {
                        showingImportSheet = true
                    }
                    
                    Divider()
                        .background(AppColors.glassBorder)
                    
                    SettingsRow(
                        icon: "square.and.arrow.up",
                        title: "Экспорт библиотеки",
                        subtitle: "Сохранить в файл"
                    ) {
                        showingExportSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Секция голосовых заметок
    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("ГОЛОСОВЫЕ ЗАМЕТКИ")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
                .tracking(1)
                .padding(.leading, AppSpacing.sm)
            
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "mic.fill",
                        title: "Распознавание речи",
                        subtitle: "Русский язык"
                    ) {
                        // Открыть настройки языка
                    }
                    
                    Divider()
                        .background(AppColors.glassBorder)
                    
                    SettingsRow(
                        icon: "waveform",
                        title: "Триггерные слова",
                        subtitle: "цитата, мысль, вопрос"
                    ) {
                        // Настройка триггеров
                    }
                }
            }
        }
    }
    
    // MARK: - Секция внешнего вида
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("ВНЕШНИЙ ВИД")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
                .tracking(1)
                .padding(.leading, AppSpacing.sm)
            
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "moon.fill",
                        title: "Тёмная тема",
                        subtitle: "Всегда включена"
                    ) {
                        // Настройка темы
                    }
                    
                    Divider()
                        .background(AppColors.glassBorder)
                    
                    SettingsRow(
                        icon: "textformat.size",
                        title: "Размер текста",
                        subtitle: "Системный"
                    ) {
                        // Настройка размера
                    }
                }
            }
        }
    }
    
    // MARK: - Секция данных
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("ДАННЫЕ")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
                .tracking(1)
                .padding(.leading, AppSpacing.sm)
            
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "arrow.clockwise",
                        title: "Показать онбординг",
                        subtitle: "Пройти обучение заново"
                    ) {
                        hasCompletedOnboarding = false
                        dismiss()
                    }
                    
                    Divider()
                        .background(AppColors.glassBorder)
                    
                    SettingsRow(
                        icon: "trash",
                        title: "Сбросить все данные",
                        subtitle: "Удалить книги и заметки",
                        isDestructive: true
                    ) {
                        showingResetAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - О приложении
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("О ПРИЛОЖЕНИИ")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
                .tracking(1)
                .padding(.leading, AppSpacing.sm)
            
            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "star.fill",
                        title: "Оценить приложение",
                        subtitle: "App Store"
                    ) {
                        // Открыть App Store
                    }
                    
                    Divider()
                        .background(AppColors.glassBorder)
                    
                    SettingsRow(
                        icon: "envelope.fill",
                        title: "Обратная связь",
                        subtitle: "Написать разработчику"
                    ) {
                        // Открыть почту
                    }
                    
                    Divider()
                        .background(AppColors.glassBorder)
                    
                    SettingsRow(
                        icon: "doc.text.fill",
                        title: "Политика конфиденциальности",
                        subtitle: ""
                    ) {
                        // Открыть политику
                    }
                }
            }
        }
    }
    
    // MARK: - Методы
    private func resetAllData() {
        UserDefaults.standard.removeObject(forKey: "saved_books")
        UserDefaults.standard.removeObject(forKey: "saved_notes")
        UserDefaults.standard.removeObject(forKey: "reading_sessions")
        UserDefaults.standard.removeObject(forKey: "chat_sessions")
        
        // Перезапуск приложения потребуется
    }
}

// MARK: - Строка настроек
struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    var isDestructive: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isDestructive ? AppColors.error : AppColors.accent)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundColor(isDestructive ? AppColors.error : AppColors.textPrimary)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(AppSpacing.md)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}

