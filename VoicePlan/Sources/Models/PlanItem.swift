import Foundation
import SwiftData

/// A task/event/note created from voice or manual input.
/// This is the core entity — can live in Inbox, Today, Upcoming, or Someday.
@Model
final class PlanItem {
    var title: String
    var notes: String
    var createdAt: Date
    var dueDate: Date?
    var dueTime: Date?          // Optional specific time
    var completedAt: Date?
    var isCompleted: Bool
    
    // Organization
    var category: ItemCategory
    var priority: ItemPriority
    var tags: [String]
    var listName: String        // "Inbox", "Work", "Personal", etc.
    
    // Voice origin
    var voiceMemoID: String?    // Links to VoiceMemo if created from voice
    var isFromVoice: Bool
    
    // Calendar
    var isEvent: Bool           // True = calendar event, False = task
    var eventDuration: Int?     // Minutes, for events
    
    // Recurrence
    var recurrence: Recurrence?
    
    init(title: String, category: ItemCategory = .task, listName: String = "Inbox") {
        self.title = title
        self.notes = ""
        self.createdAt = Date()
        self.isCompleted = false
        self.category = category
        self.priority = .normal
        self.tags = []
        self.listName = listName
        self.isFromVoice = false
        self.isEvent = false
    }
    
    // MARK: - Computed
    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Calendar.current.startOfDay(for: Date())
    }
    
    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }
    
    var isDueSoon: Bool {
        guard let due = dueDate else { return false }
        let daysAway = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        return daysAway <= 3 && daysAway >= 0
    }
}

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case task = "Task"
    case event = "Event"
    case note = "Note"
    case reminder = "Reminder"
    case idea = "Idea"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .task: "checkmark.circle"
        case .event: "calendar"
        case .note: "note.text"
        case .reminder: "bell"
        case .idea: "lightbulb"
        }
    }
    
    var color: String {
        switch self {
        case .task: "4A90D9"
        case .event: "FF8C42"
        case .note: "8E8E93"
        case .reminder: "FF3B30"
        case .idea: "FFD60A"
        }
    }
}

enum ItemPriority: Int, Codable, CaseIterable, Identifiable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    var id: Int { rawValue }
    
    var label: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        case .urgent: "Urgent"
        }
    }
    
    var icon: String {
        switch self {
        case .low: "arrow.down"
        case .normal: "minus"
        case .high: "arrow.up"
        case .urgent: "exclamationmark.2"
        }
    }
}

enum Recurrence: String, Codable, CaseIterable, Identifiable {
    case daily, weekdays, weekly, biweekly, monthly
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekly: "Every week"
        case .biweekly: "Every 2 weeks"
        case .monthly: "Every month"
        }
    }
}
