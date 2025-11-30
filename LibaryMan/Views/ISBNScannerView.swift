//
//  ISBNScannerView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Сканер ISBN штрих-кодов
struct ISBNScannerView: View {
    @EnvironmentObject var bookService: BookService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var scannerManager = BarcodeScannerManager()
    
    @State private var scannedISBN: String?
    @State private var foundBook: Book?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showingResult = false
    
    var body: some View {
        ZStack {
            // Камера
            if !showingResult {
                cameraView
            } else {
                resultView
            }
        }
        .onChange(of: scannerManager.scannedCode) { _, newValue in
            if let code = newValue, scannedISBN == nil {
                handleScannedCode(code)
            }
        }
    }
    
    // MARK: - Вид камеры
    private var cameraView: some View {
        ZStack {
            // Превью камеры
            BarcodeScannerPreview(scannerManager: scannerManager)
                .ignoresSafeArea()
            
            // Оверлей
            VStack {
                // Хедер
                HStack {
                    GlassIconButton(icon: "xmark", size: 40, iconSize: 16) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Сканер ISBN")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Вспышка
                    GlassIconButton(
                        icon: scannerManager.isFlashOn ? "bolt.fill" : "bolt.slash",
                        size: 40,
                        iconSize: 16,
                        isActive: scannerManager.isFlashOn
                    ) {
                        scannerManager.toggleFlash()
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 60)
                
                Spacer()
                
                // Рамка сканирования
                scanFrame
                
                Spacer()
                
                // Подсказка
                VStack(spacing: AppSpacing.md) {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Ищем книгу...")
                            .font(AppTypography.body)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Наведите камеру на штрих-код книги")
                            .font(AppTypography.body)
                            .foregroundColor(.white)
                        
                        Text("Поддерживаются ISBN-10 и ISBN-13")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            scannerManager.startScanning()
        }
        .onDisappear {
            scannerManager.stopScanning()
        }
    }
    
    // MARK: - Рамка сканирования
    private var scanFrame: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width - 80
            let frameHeight: CGFloat = 150
            
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppColors.accent, AppColors.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                .frame(width: frameWidth, height: frameHeight)
                .overlay(
                    // Линия сканирования
                    Rectangle()
                        .fill(AppColors.accent)
                        .frame(height: 2)
                        .shadow(color: AppColors.accent, radius: 5)
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: 200)
    }
    
    // MARK: - Результат
    private var resultView: some View {
        ZStack {
            AppGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                // Хедер
                HStack {
                    Button("Отмена") {
                        resetScanner()
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("Найдена книга")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button("Добавить") {
                        addBook()
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.accent)
                    .disabled(foundBook == nil)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                
                if let book = foundBook {
                    // Информация о книге
                    VStack(spacing: AppSpacing.lg) {
                        BookCoverView(book: book, size: .large)
                        
                        VStack(spacing: AppSpacing.sm) {
                            Text(book.title)
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text(book.author)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                            
                            if let isbn = scannedISBN {
                                Text("ISBN: \(isbn)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                    }
                    
                    Spacer()
                    
                    // Кнопка добавления
                    GlassButton("Добавить в библиотеку", icon: "plus") {
                        addBook()
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.xxl)
                    
                } else if let error = errorMessage {
                    // Ошибка
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.warning)
                        
                        Text("Книга не найдена")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(error)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        if let isbn = scannedISBN {
                            Text("ISBN: \(isbn)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    
                    Spacer()
                    
                    VStack(spacing: AppSpacing.md) {
                        GlassButton("Сканировать снова", icon: "barcode.viewfinder") {
                            resetScanner()
                        }
                        
                        Button("Добавить вручную") {
                            dismiss()
                            // TODO: открыть форму ручного ввода
                        }
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
    }
    
    // MARK: - Методы
    private func handleScannedCode(_ code: String) {
        // Проверяем, что это ISBN (10 или 13 цифр)
        let cleanCode = code.replacingOccurrences(of: "-", with: "")
        guard cleanCode.count == 10 || cleanCode.count == 13,
              cleanCode.allSatisfy({ $0.isNumber || $0 == "X" }) else {
            return
        }
        
        scannedISBN = code
        isSearching = true
        scannerManager.stopScanning()
        
        // Вибрация
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Поиск книги
        Task {
            do {
                if let book = try await bookService.searchByISBN(code) {
                    foundBook = book
                } else {
                    errorMessage = "Не удалось найти книгу с этим ISBN в базе данных."
                }
            } catch {
                errorMessage = "Ошибка поиска: \(error.localizedDescription)"
            }
            
            isSearching = false
            showingResult = true
        }
    }
    
    private func addBook() {
        guard var book = foundBook else { return }
        book.isbn = scannedISBN
        
        Task {
            try? await bookService.saveBook(book)
            dismiss()
        }
    }
    
    private func resetScanner() {
        scannedISBN = nil
        foundBook = nil
        errorMessage = nil
        showingResult = false
        scannerManager.scannedCode = nil
        scannerManager.startScanning()
    }
}

// MARK: - Менеджер сканера штрих-кодов
class BarcodeScannerManager: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isFlashOn = false
    
    let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        setupScanner()
    }
    
    private func setupScanner() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean13, .ean8, .code128]
        }
    }
    
    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashOn ? .off : .on
            isFlashOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Flash error: \(error)")
        }
    }
}

extension BarcodeScannerManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue,
              scannedCode == nil else {
            return
        }
        
        scannedCode = code
    }
}

// MARK: - Превью сканера
struct BarcodeScannerPreview: UIViewRepresentable {
    let scannerManager: BarcodeScannerManager
    
    func makeUIView(context: Context) -> UIView {
        let view = BarcodeScannerUIView()
        view.scannerManager = scannerManager
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let scannerView = uiView as? BarcodeScannerUIView else { return }
        scannerView.updatePreviewLayer()
    }
}

class BarcodeScannerUIView: UIView {
    var scannerManager: BarcodeScannerManager?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewLayer()
    }
    
    func updatePreviewLayer() {
        if previewLayer == nil, let manager = scannerManager {
            let layer = AVCaptureVideoPreviewLayer(session: manager.captureSession)
            layer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(layer)
            previewLayer = layer
        }
        previewLayer?.frame = bounds
    }
}

// MARK: - Preview
#Preview {
    ISBNScannerView()
        .environmentObject(BookService())
}

