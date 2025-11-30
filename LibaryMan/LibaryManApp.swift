//
//  LibaryManApp.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI

@main
struct LibaryManApp: App {
    
    init() {
        // Настройка внешнего вида навигации
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureAppearance() {
        // Настройка NavigationBar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppColors.textPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(AppColors.accent)
        
        // Настройка TabBar (скрываем стандартный)
        UITabBar.appearance().isHidden = true
        
        // Настройка TextField
        UITextField.appearance().tintColor = UIColor(AppColors.accent)
        
        // Настройка SearchBar
        UISearchBar.appearance().tintColor = UIColor(AppColors.accent)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor(AppColors.cardBackground)
        
        // Настройка списков
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
}

// MARK: - Расширение для Info.plist ключей
/*
 Добавьте в Info.plist:
 
 <key>CFBundleDevelopmentRegion</key>
 <string>ru</string>
 
 <key>CFBundleDisplayName</key>
 <string>Читалка</string>
 
 <key>NSMicrophoneUsageDescription</key>
 <string>Приложению нужен доступ к микрофону для записи голосовых заметок во время чтения.</string>
 
 <key>NSSpeechRecognitionUsageDescription</key>
 <string>Приложению нужен доступ к распознаванию речи для преобразования ваших голосовых заметок в текст.</string>
 
 <key>NSCameraUsageDescription</key>
 <string>Приложению нужен доступ к камере для сканирования цитат из книг.</string>
 
 <key>NSPhotoLibraryUsageDescription</key>
 <string>Приложению нужен доступ к фотографиям для добавления обложек книг.</string>
 */
