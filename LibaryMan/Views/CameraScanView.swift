//
//  CameraScanView.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import SwiftUI
import AVFoundation
import Vision
import Combine

// MARK: - Экран сканирования камерой
struct CameraScanView: View {
    let book: Book
    let onCapture: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var ocrService = OCRService()
    
    @State private var capturedImage: UIImage?
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var showingResult = false
    
    var body: some View {
        ZStack {
            // Камера или результат
            if showingResult {
                resultView
            } else {
                cameraView
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Вид камеры
    private var cameraView: some View {
        ZStack {
            // Превью камеры
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Оверлей
            VStack {
                // Хедер
                HStack {
                    GlassIconButton(icon: "xmark", size: 40, iconSize: 16) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    // Вспышка
                    GlassIconButton(
                        icon: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash",
                        size: 40,
                        iconSize: 16,
                        isActive: cameraManager.isFlashOn
                    ) {
                        cameraManager.toggleFlash()
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 60)
                
                Spacer()
                
                // Рамка для сканирования
                scanFrame
                
                Spacer()
                
                // Подсказка и кнопка
                VStack(spacing: AppSpacing.lg) {
                    Text("Наведите камеру на текст")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white)
                    
                    // Кнопка съёмки
                    Button {
                        capturePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .strokeBorder(.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .disabled(isProcessing)
                    
                    Text("Сканировать цитату")
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 50)
            }
            
            // Индикатор загрузки
            if isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Распознаём текст...")
                        .font(AppTypography.body)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // MARK: - Рамка сканирования
    private var scanFrame: some View {
        GeometryReader { geometry in
            let frameWidth = geometry.size.width - 60
            
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [AppColors.accent, AppColors.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: frameWidth, height: 200)
                .overlay(
                    // Уголки
                    ZStack {
                        // Верхний левый
                        CornerShape()
                            .stroke(AppColors.accent, lineWidth: 4)
                            .frame(width: 30, height: 30)
                            .position(x: 15, y: 15)
                        
                        // Верхний правый
                        CornerShape()
                            .rotation(.degrees(90))
                            .stroke(AppColors.accent, lineWidth: 4)
                            .frame(width: 30, height: 30)
                            .position(x: frameWidth - 15, y: 15)
                        
                        // Нижний левый
                        CornerShape()
                            .rotation(.degrees(-90))
                            .stroke(AppColors.orange, lineWidth: 4)
                            .frame(width: 30, height: 30)
                            .position(x: 15, y: 185)
                        
                        // Нижний правый
                        CornerShape()
                            .rotation(.degrees(180))
                            .stroke(AppColors.orange, lineWidth: 4)
                            .frame(width: 30, height: 30)
                            .position(x: frameWidth - 15, y: 185)
                    }
                )
                .position(x: geometry.size.width / 2, y: 100)
        }
        .frame(height: 200)
    }
    
    // MARK: - Вид результата
    private var resultView: some View {
        ZStack {
            AppGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.lg) {
                // Хедер
                HStack {
                    Button("Отмена") {
                        showingResult = false
                        recognizedText = ""
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("Результат")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button("Готово") {
                        onCapture(recognizedText)
                        dismiss()
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.accent)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                
                // Превью изображения
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                        .cornerRadius(AppRadius.md)
                        .padding(.horizontal, AppSpacing.screenPadding)
                }
                
                // Распознанный текст
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(AppColors.accent)
                            
                            Text("Распознанный текст")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = recognizedText
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        
                        TextEditor(text: $recognizedText)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                
                // Информация о книге
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "book.fill")
                        .foregroundColor(AppColors.textMuted)
                    
                    Text("Будет сохранено в: \(book.title)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textMuted)
                }
                
                Spacer()
                
                // Кнопка сохранения
                GlassButton("Сохранить как цитату", icon: "quote.opening") {
                    onCapture(recognizedText)
                    dismiss()
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
    }
    
    // MARK: - Методы
    private func capturePhoto() {
        isProcessing = true
        
        cameraManager.capturePhoto { image in
            guard let image = image else {
                isProcessing = false
                return
            }
            
            capturedImage = image
            
            Task {
                do {
                    let text = try await ocrService.recognizeText(from: image)
                    recognizedText = ocrService.extractQuote(from: text)
                    showingResult = true
                } catch {
                    print("OCR Error: \(error.localizedDescription)")
                }
                isProcessing = false
            }
        }
    }
}

// MARK: - Форма уголка
struct CornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// MARK: - Менеджер камеры
class CameraManager: NSObject, ObservableObject {
    @Published var isFlashOn = false
    
    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            captureCompletion?(nil)
            return
        }
        
        captureCompletion?(image)
    }
}

// MARK: - Превью камеры
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        view.cameraManager = cameraManager
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewView = uiView as? CameraPreviewUIView else { return }
        previewView.updatePreviewLayer()
    }
}

// MARK: - UIView для превью камеры
class CameraPreviewUIView: UIView {
    var cameraManager: CameraManager?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewLayer()
    }
    
    func updatePreviewLayer() {
        if previewLayer == nil, let manager = cameraManager {
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
    CameraScanView(book: Book.sample) { text in
        print("Captured: \(text)")
    }
}

