import AVFoundation
import Foundation
import Speech

/// Handles audio recording and speech-to-text transcription.
@Observable
final class VoiceRecorder {
    var isRecording = false
    var transcription = ""
    var isTranscribing = false
    var recordingDuration: TimeInterval = 0
    var audioLevel: Float = 0       // 0-1, for waveform visualization
    
    private var audioRecorder: AVAudioRecorder?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-PE"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var timer: Timer?
    private var startTime: Date?
    
    // MARK: - Permissions
    func requestPermissions() async -> Bool {
        let speechAuth = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        let audioAuth: Bool
        #if os(macOS)
        audioAuth = true // macOS doesn't require explicit audio permission
        #else
        audioAuth = await AVAudioApplication.requestRecordPermission()
        #endif
        
        return speechAuth && audioAuth
    }
    
    // MARK: - Recording with Live Transcription
    func startRecording() {
        guard !isRecording else { return }
        
        transcription = ""
        isRecording = true
        isTranscribing = true
        startTime = Date()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level for visualization
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                sum += abs(channelData[i])
            }
            let avg = sum / Float(frameLength)
            DispatchQueue.main.async {
                self?.audioLevel = min(1.0, avg * 10)
            }
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result {
                DispatchQueue.main.async {
                    self?.transcription = result.bestTranscription.formattedString
                }
            }
            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async {
                    self?.isTranscribing = false
                }
            }
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
        
        // Duration timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let start = self?.startTime else { return }
            self?.recordingDuration = Date().timeIntervalSince(start)
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        timer?.invalidate()
        
        isRecording = false
        audioLevel = 0
    }
    
    // MARK: - Duration formatting
    var durationString: String {
        let mins = Int(recordingDuration) / 60
        let secs = Int(recordingDuration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
