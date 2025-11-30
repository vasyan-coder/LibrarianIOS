//
//  SpeechService.swift
//  LibaryMan
//
//  Created by Vasyan on 30.11.2025.
//

import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Ошибки распознавания речи
enum SpeechError: LocalizedError {
    case notAuthorized
    case notAvailable
    case recognitionFailed
    case audioSessionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Доступ к распознаванию речи не разрешён. Пожалуйста, разрешите доступ в настройках."
        case .notAvailable:
            return "Распознавание речи недоступно на этом устройстве."
        case .recognitionFailed:
            return "Не удалось распознать речь. Попробуйте ещё раз."
        case .audioSessionFailed:
            return "Ошибка аудио. Проверьте, что микрофон работает."
        }
    }
}

// MARK: - Делегат для получения результатов
protocol SpeechServiceDelegate: AnyObject {
    func speechService(_ service: SpeechService, didRecognizeText text: String, isFinal: Bool)
    func speechService(_ service: SpeechService, didFailWithError error: Error)
    func speechServiceDidStart(_ service: SpeechService)
    func speechServiceDidStop(_ service: SpeechService)
}

// MARK: - Сервис распознавания речи
class SpeechService: NSObject, ObservableObject {
    
    // MARK: - Published свойства
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    // MARK: - Приватные свойства
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    weak var delegate: SpeechServiceDelegate?
    
    // MARK: - Инициализация
    override init() {
        // Используем русскую локаль
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        super.init()
        
        speechRecognizer?.delegate = self
        checkAuthorization()
    }
    
    // MARK: - Авторизация
    
    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                case .denied, .restricted, .notDetermined:
                    self?.isAuthorized = false
                    self?.errorMessage = SpeechError.notAuthorized.localizedDescription
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Запись и распознавание
    
    func startRecording() async throws {
        // Проверяем авторизацию
        guard isAuthorized else {
            throw SpeechError.notAuthorized
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.notAvailable
        }
        
        // Проверяем разрешение на микрофон
        let micPermission = await requestMicrophonePermission()
        guard micPermission else {
            throw SpeechError.notAuthorized
        }
        
        // Останавливаем предыдущую задачу, если есть
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Настраиваем аудио сессию
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechError.audioSessionFailed
        }
        
        // Создаём запрос на распознавание
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionFailed
        }
        
        let inputNode = audioEngine.inputNode
        
        // Настраиваем запрос
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Добавляем контекстные подсказки для русского языка
        recognitionRequest.contextualStrings = [
            "цитата", "мысль", "вопрос", "заметка",
            "запиши", "запомни", "интересно",
            "почему", "зачем", "как"
        ]
        
        // Создаём задачу распознавания
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                var isFinal = false
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self.recognizedText = text
                    isFinal = result.isFinal
                    
                    self.delegate?.speechService(self, didRecognizeText: text, isFinal: isFinal)
                }
                
                if error != nil || isFinal {
                    self.stopRecordingInternal()
                    
                    if let error = error {
                        self.delegate?.speechService(self, didFailWithError: error)
                    }
                }
            }
        }
        
        // Настраиваем формат записи
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Запускаем аудио движок
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        delegate?.speechServiceDidStart(self)
    }
    
    func stopRecording() {
        stopRecordingInternal()
        delegate?.speechServiceDidStop(self)
    }
    
    private func stopRecordingInternal() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        // Деактивируем аудио сессию
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // MARK: - Обработка текста
    
    /// Разбивает распознанный текст на отдельные заметки
    func parseNotesFromText(_ text: String) -> [(content: String, type: NoteType)] {
        var notes: [(content: String, type: NoteType)] = []
        
        // Разделители для русского языка
        let separators = ["цитата:", "мысль:", "вопрос:", "заметка:"]
        
        var currentText = text
        var segments: [String] = []
        
        // Пытаемся разбить по разделителям
        for separator in separators {
            let parts = currentText.components(separatedBy: separator)
            if parts.count > 1 {
                for (index, part) in parts.enumerated() {
                    if index == 0 && !part.trimmingCharacters(in: .whitespaces).isEmpty {
                        segments.append(part)
                    } else if index > 0 {
                        segments.append(separator + part)
                    }
                }
                currentText = ""
                break
            }
        }
        
        // Если не нашли разделителей, используем весь текст
        if segments.isEmpty && !text.trimmingCharacters(in: .whitespaces).isEmpty {
            segments = [text]
        }
        
        // Классифицируем каждый сегмент
        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let type = Note.classifyFromRussianText(trimmed)
            let cleanContent = Note.cleanTriggerWords(from: trimmed)
            
            notes.append((content: cleanContent, type: type))
        }
        
        return notes
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                self.errorMessage = SpeechError.notAvailable.localizedDescription
            }
        }
    }
}

