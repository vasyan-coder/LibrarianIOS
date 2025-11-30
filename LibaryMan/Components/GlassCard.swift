//
//  GlassCard.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

// MARK: - Glass Card компонент
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppSpacing.cardPadding
    var cornerRadius: CGFloat = AppRadius.lg
    var blur: CGFloat = 20
    var opacity: Double = 0.08
    var borderOpacity: Double = 0.15
    
    init(
        padding: CGFloat = AppSpacing.cardPadding,
        cornerRadius: CGFloat = AppRadius.lg,
        blur: CGFloat = 20,
        opacity: Double = 0.08,
        borderOpacity: Double = 0.15,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.blur = blur
        self.opacity = opacity
        self.borderOpacity = borderOpacity
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Размытый фон
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                    
                    // Градиентный оверлей
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(opacity * 1.5),
                                    Color.white.opacity(opacity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Граница
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(borderOpacity),
                                    Color.white.opacity(borderOpacity * 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(AppTypography.headline)
            }
            .foregroundColor(textColor)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(backgroundView)
        }
        .disabled(isLoading)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: AppRadius.full)
                .fill(AppColors.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.full)
                        .strokeBorder(AppColors.accentLight.opacity(0.3), lineWidth: 1)
                )
        case .secondary:
            RoundedRectangle(cornerRadius: AppRadius.full)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.full)
                        .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                )
        case .ghost:
            Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return AppColors.background
        case .secondary, .ghost:
            return AppColors.textPrimary
        }
    }
}

// MARK: - Glass Icon Button
struct GlassIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var iconSize: CGFloat = 20
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(isActive ? AppColors.accent : AppColors.textPrimary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isActive ? AppColors.accent.opacity(0.5) : AppColors.glassBorder,
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Glass TextField
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .font(.system(size: 18))
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.glassBorder, lineWidth: 1)
        )
    }
}

// MARK: - Glass Segmented Control
struct GlassSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String, icon: String?)]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                Button {
                    withAnimation(AppAnimations.quick) {
                        selection = option.value
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                        }
                        Text(option.label)
                            .font(AppTypography.subheadline)
                    }
                    .foregroundColor(selection == option.value ? AppColors.background : AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(selection == option.value ? AppColors.accent : Color.clear)
                    )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.glassBorder, lineWidth: 1)
        )
    }
}

// MARK: - Glass Progress Bar
struct GlassProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var showLabel: Bool = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(AppColors.glassBackground)
                    
                    // Прогресс
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accent, AppColors.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                        .animation(AppAnimations.smooth, value: progress)
                }
            }
            .frame(height: height)
            
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppGradients.background
            .ignoresSafeArea()
        
        VStack(spacing: AppSpacing.lg) {
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Glass Card")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Пример карточки с эффектом жидкого стекла")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            GlassButton("Основная кнопка", icon: "book.fill") {}
            
            GlassButton("Вторичная", icon: "plus", style: .secondary) {}
            
            GlassTextField(placeholder: "Поиск книг...", text: .constant(""), icon: "magnifyingglass")
            
            GlassProgressBar(progress: 0.65, showLabel: true)
            
            HStack {
                GlassIconButton(icon: "mic.fill") {}
                GlassIconButton(icon: "camera.fill") {}
                GlassIconButton(icon: "star.fill", isActive: true) {}
            }
        }
        .padding()
    }
}

