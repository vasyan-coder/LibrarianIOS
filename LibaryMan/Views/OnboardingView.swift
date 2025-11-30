//
//  OnboardingView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Онбординг
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "books.vertical.fill",
            title: "Ваша книжная полка",
            description: "Создайте личную библиотеку прочитанных книг и списков для чтения. Добавляйте книги по ISBN или названию.",
            accentColor: AppColors.accent
        ),
        OnboardingPage(
            icon: "mic.fill",
            title: "Заметки голосом",
            description: "Читайте бумажную книгу и просто говорите свои мысли вслух. Скажите «цитата» или «вопрос» для автоматической классификации.",
            accentColor: AppColors.orange
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "AI-помощник",
            description: "Задавайте вопросы о книге и получайте умные ответы. Сохраняйте цитаты с камеры одним нажатием.",
            accentColor: AppColors.noteQuestion
        )
    ]
    
    var body: some View {
        ZStack {
            // Фон
            backgroundView
            
            VStack(spacing: 0) {
                // Пропустить
                HStack {
                    Spacer()
                    
                    Button("Пропустить") {
                        completeOnboarding()
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
                }
                
                // Контент страницы
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Индикаторы и кнопка
                VStack(spacing: AppSpacing.xl) {
                    // Индикаторы страниц
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? AppColors.accent : AppColors.textMuted)
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(AppAnimations.spring, value: currentPage)
                        }
                    }
                    
                    // Кнопка
                    GlassButton(
                        currentPage == pages.count - 1 ? "Начать" : "Далее",
                        icon: currentPage == pages.count - 1 ? "checkmark" : "arrow.right"
                    ) {
                        if currentPage == pages.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation(AppAnimations.spring) {
                                currentPage += 1
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }
                .padding(.bottom, AppSpacing.xxl)
            }
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            AppGradients.background
            
            // Динамическое свечение в зависимости от страницы
            RadialGradient(
                colors: [
                    pages[currentPage].accentColor.opacity(0.3),
                    pages[currentPage].accentColor.opacity(0.1),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .animation(AppAnimations.smooth, value: currentPage)
        }
        .ignoresSafeArea()
    }
    
    private func completeOnboarding() {
        withAnimation(AppAnimations.smooth) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Модель страницы онбординга
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
}

// MARK: - Вид страницы онбординга
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Иконка
            ZStack {
                // Свечение
                Circle()
                    .fill(page.accentColor.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)
                
                // Стеклянный круг
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        page.accentColor.opacity(0.5),
                                        page.accentColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Иконка
                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.accentColor, page.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Текст
            VStack(spacing: AppSpacing.md) {
                Text(page.title)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppSpacing.xl)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}

