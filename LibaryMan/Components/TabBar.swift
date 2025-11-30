//
//  TabBar.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Вкладки приложения
enum AppTab: String, CaseIterable {
    case library = "library"
    case notes = "notes"
    case chat = "chat"
    
    var title: String {
        switch self {
        case .library: return "Библиотека"
        case .notes: return "Заметки"
        case .chat: return "Чат"
        }
    }
    
    var icon: String {
        switch self {
        case .library: return "book.fill"
        case .notes: return "pencil.line"
        case .chat: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var iconOutline: String {
        switch self {
        case .library: return "book"
        case .notes: return "pencil.line"
        case .chat: return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Кастомный TabBar
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    var onAddTap: () -> Void = {}
    var onRecordTap: () -> Void = {}
    
    @State private var isAddMenuExpanded = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Левые вкладки
            ForEach([AppTab.library, AppTab.notes], id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(AppAnimations.spring) {
                        selectedTab = tab
                    }
                }
            }
            
            // Центральные кнопки действий
            centerButtons
            
            // Правая вкладка (чат)
            TabBarItem(
                tab: .chat,
                isSelected: selectedTab == .chat
            ) {
                withAnimation(AppAnimations.spring) {
                    selectedTab = .chat
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            ZStack {
                // Размытый фон
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(.ultraThinMaterial)
                
                // Градиентный оверлей
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Граница
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .strokeBorder(AppColors.glassBorder, lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.sm)
    }
    
    private var centerButtons: some View {
        HStack(spacing: AppSpacing.md) {
            // Кнопка добавления
            Button(action: onAddTap) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                    )
            }
            
            // Кнопка записи
            Button(action: onRecordTap) {
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppColors.cardBackground)
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, AppSpacing.sm)
    }
}

// MARK: - Элемент TabBar
struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.icon : tab.iconOutline)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
                
                Text(tab.title)
                    .font(AppTypography.caption2)
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    var size: CGFloat = 56
    var isRecording: Bool = false
    var action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Пульсирующий круг при записи
                if isRecording {
                    Circle()
                        .fill(AppColors.orange.opacity(0.3))
                        .frame(width: size * 1.5, height: size * 1.5)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }
                
                // Основная кнопка
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isRecording ? [AppColors.orange, AppColors.orangeDark] : [AppColors.accent, AppColors.accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: (isRecording ? AppColors.orange : AppColors.accent).opacity(0.4), radius: 12, y: 4)
                
                // Иконка
                Image(systemName: isRecording ? "stop.fill" : icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            if isRecording {
                pulseAnimation = true
            }
        }
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppGradients.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            // FAB
            HStack {
                Spacer()
                FloatingActionButton(icon: "mic.fill", isRecording: true) {}
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
            }
            
            // TabBar
            CustomTabBar(selectedTab: .constant(.library))
        }
    }
}

