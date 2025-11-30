//
//  AppTheme.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Цветовая схема приложения
struct AppColors {
    // Основные цвета
    static let background = Color(hex: "1A1410")
    static let backgroundGradientStart = Color(hex: "2D1810")
    static let backgroundGradientMiddle = Color(hex: "1A1410")
    static let backgroundGradientEnd = Color(hex: "0D0A08")
    
    // Акцентные цвета (тёплые оттенки)
    static let accent = Color(hex: "D4A574")
    static let accentLight = Color(hex: "E8C9A0")
    static let accentDark = Color(hex: "8B6914")
    
    // Оранжевые акценты
    static let orange = Color(hex: "E07830")
    static let orangeLight = Color(hex: "F09050")
    static let orangeDark = Color(hex: "B85820")
    
    // Текст
    static let textPrimary = Color(hex: "F5F0E8")
    static let textSecondary = Color(hex: "A89888")
    static let textMuted = Color(hex: "6B5B4B")
    
    // Glass эффекты
    static let glassBackground = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.15)
    static let glassHighlight = Color.white.opacity(0.25)
    
    // Карточки
    static let cardBackground = Color(hex: "2A2018").opacity(0.8)
    static let cardBorder = Color(hex: "3D3028")
    
    // Статусы
    static let success = Color(hex: "4CAF50")
    static let warning = Color(hex: "FFC107")
    static let error = Color(hex: "F44336")
    
    // Типы заметок
    static let noteThought = Color(hex: "FFD54F")
    static let noteQuote = Color(hex: "CE93D8")
    static let noteQuestion = Color(hex: "4DD0E1")
}

// MARK: - Расширение Color для HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Типографика
struct AppTypography {
    // Заголовки
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .serif)
    static let title = Font.system(size: 28, weight: .bold, design: .serif)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .serif)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Основной текст
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let bodySerif = Font.system(size: 17, weight: .regular, design: .serif)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    
    // Мелкий текст
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)
    
    // Специальные
    static let monospaced = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let quote = Font.system(size: 16, weight: .regular, design: .serif).italic()
}

// MARK: - Градиенты
struct AppGradients {
    static let background = LinearGradient(
        colors: [
            AppColors.backgroundGradientStart,
            AppColors.backgroundGradientMiddle,
            AppColors.backgroundGradientEnd
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let warmGlow = RadialGradient(
        colors: [
            AppColors.orange.opacity(0.3),
            AppColors.backgroundGradientStart.opacity(0.1),
            Color.clear
        ],
        center: .top,
        startRadius: 0,
        endRadius: 400
    )
    
    static let accent = LinearGradient(
        colors: [AppColors.accent, AppColors.accentDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glass = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGlow = RadialGradient(
        colors: [
            AppColors.accent.opacity(0.2),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 150
    )
}

// MARK: - Размеры и отступы
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
}

struct AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 100
}

// MARK: - Тени
struct AppShadows {
    static let small = Shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
    static let glow = Shadow(color: AppColors.accent.opacity(0.3), radius: 12, x: 0, y: 0)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Анимации
struct AppAnimations {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let smooth = Animation.easeInOut(duration: 0.4)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

