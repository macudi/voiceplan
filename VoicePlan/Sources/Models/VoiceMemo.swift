import Foundation
import SwiftData

/// A voice recording with its transcription and extracted actions.
@Model
final class VoiceMemo {
    var id: String
    var transcription: String
    var rawTranscription: String    // Before editing
    var recordedAt: Date
    var durationSeconds: Double
    var audioFilePath: String?      // Local file URL
    
    // Processing
    var isProcessed: Bool
    var extractedItems: [String]    // IDs of PlanItems created from this memo
    
    init(transcription: String, duration: Double) {
        self.id = UUID().uuidString
        self.transcription = transcription
        self.rawTranscription = transcription
        self.recordedAt = Date()
        self.durationSeconds = duration
        self.isProcessed = false
        self.extractedItems = []
    }
}
