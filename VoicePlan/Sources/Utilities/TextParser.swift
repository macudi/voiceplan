import Foundation

/// Parses transcribed text to extract tasks, events, reminders, and notes.
/// Smart NLP-lite parsing for Spanish and English.
struct TextParser {
    
    struct ParsedResult {
        var title: String
        var category: ItemCategory
        var dueDate: Date?
        var dueTime: Date?
        var priority: ItemPriority
        var isEvent: Bool
        var eventDuration: Int?     // minutes
    }
    
    /// Parse a single transcription into one or more actions.
    static func parse(_ text: String) -> [ParsedResult] {
        let sentences = splitSentences(text)
        return sentences.map { parseSentence($0) }
    }
    
    // MARK: - Sentence Splitting
    private static func splitSentences(_ text: String) -> [String] {
        // Split by periods, "y también", "además", newlines
        let separators = [".", "\n", " y también ", " además ", " luego ", " después "]
        var current = [text]
        
        for sep in separators {
            current = current.flatMap { $0.components(separatedBy: sep) }
        }
        
        return current
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 3 }
    }
    
    // MARK: - Single Sentence Parsing
    private static func parseSentence(_ text: String) -> ParsedResult {
        let lower = text.lowercased()
        
        // Detect category
        let category = detectCategory(lower)
        
        // Detect date/time
        let (date, time) = detectDateTime(lower)
        
        // Detect priority
        let priority = detectPriority(lower)
        
        // Detect if it's an event
        let isEvent = category == .event || 
                      lower.contains("reunión") || lower.contains("reunion") ||
                      lower.contains("meeting") || lower.contains("cita") ||
                      lower.contains("llamada") || lower.contains("call")
        
        // Detect duration for events
        let duration = detectDuration(lower)
        
        // Clean title — remove date/time keywords
        let title = cleanTitle(text)
        
        return ParsedResult(
            title: title,
            category: category,
            dueDate: date,
            dueTime: time,
            priority: priority,
            isEvent: isEvent,
            eventDuration: duration
        )
    }
    
    // MARK: - Category Detection
    private static func detectCategory(_ text: String) -> ItemCategory {
        // Events
        let eventKeywords = ["reunión", "reunion", "meeting", "cita", "evento", "event",
                            "llamada", "call", "almuerzo", "lunch", "dinner", "cena"]
        if eventKeywords.contains(where: { text.contains($0) }) { return .event }
        
        // Reminders
        let reminderKeywords = ["recordar", "remind", "no olvidar", "don't forget",
                               "acordar", "remember", "recordatorio"]
        if reminderKeywords.contains(where: { text.contains($0) }) { return .reminder }
        
        // Ideas
        let ideaKeywords = ["idea", "podría", "could", "what if", "qué tal si",
                           "pensar en", "think about", "explorar"]
        if ideaKeywords.contains(where: { text.contains($0) }) { return .idea }
        
        // Notes
        let noteKeywords = ["nota", "note", "apuntar", "anotar", "escribir"]
        if noteKeywords.contains(where: { text.contains($0) }) { return .note }
        
        // Default: task
        return .task
    }
    
    // MARK: - Date/Time Detection
    private static func detectDateTime(_ text: String) -> (Date?, Date?) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var date: Date?
        var time: Date?
        
        // Relative dates
        if text.contains("hoy") || text.contains("today") {
            date = today
        } else if text.contains("mañana") || text.contains("tomorrow") {
            date = cal.date(byAdding: .day, value: 1, to: today)
        } else if text.contains("pasado mañana") || text.contains("day after tomorrow") {
            date = cal.date(byAdding: .day, value: 2, to: today)
        } else if text.contains("lunes") || text.contains("monday") {
            date = nextWeekday(1)
        } else if text.contains("martes") || text.contains("tuesday") {
            date = nextWeekday(2)
        } else if text.contains("miércoles") || text.contains("miercoles") || text.contains("wednesday") {
            date = nextWeekday(3)
        } else if text.contains("jueves") || text.contains("thursday") {
            date = nextWeekday(4)
        } else if text.contains("viernes") || text.contains("friday") {
            date = nextWeekday(5)
        } else if text.contains("próxima semana") || text.contains("next week") {
            date = cal.date(byAdding: .weekOfYear, value: 1, to: today)
        } else if text.contains("próximo mes") || text.contains("next month") {
            date = cal.date(byAdding: .month, value: 1, to: today)
        }
        
        // Time detection: "a las 3", "at 3pm", "3:30"
        let timePatterns: [(String, (String) -> Date?)] = [
            (#"a las (\d{1,2})"#, { match in makeTime(hour: Int(match)!) }),
            (#"at (\d{1,2})"#, { match in makeTime(hour: Int(match)!) }),
            (#"(\d{1,2}):(\d{2})"#, { _ in nil }), // handled separately
            (#"(\d{1,2}) ?(am|pm)"#, { _ in nil }),
        ]
        
        // Simple time extraction: "a las X" or "at X"
        if let range = text.range(of: #"a las (\d{1,2})"#, options: .regularExpression) {
            let match = text[range]
            if let hour = Int(match.filter(\.isNumber)) {
                time = makeTime(hour: hour >= 1 && hour <= 7 ? hour + 12 : hour)
                if date == nil { date = today }
            }
        } else if let range = text.range(of: #"(\d{1,2}):(\d{2})"#, options: .regularExpression) {
            let parts = text[range].split(separator: ":")
            if let h = Int(parts[0]), let m = Int(parts[1]) {
                time = makeTime(hour: h, minute: m)
                if date == nil { date = today }
            }
        }
        
        return (date, time)
    }
    
    private static func nextWeekday(_ target: Int) -> Date { // 1=Mon, 7=Sun
        let cal = Calendar.current
        let today = Date()
        let current = cal.component(.weekday, from: today)
        // Convert to Mon=1 system
        let currentMon = (current + 5) % 7 + 1
        let daysAhead = (target - currentMon + 7) % 7
        return cal.date(byAdding: .day, value: daysAhead == 0 ? 7 : daysAhead, to: cal.startOfDay(for: today))!
    }
    
    private static func makeTime(hour: Int, minute: Int = 0) -> Date {
        let cal = Calendar.current
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
    }
    
    // MARK: - Priority Detection
    private static func detectPriority(_ text: String) -> ItemPriority {
        let urgentKeywords = ["urgente", "urgent", "asap", "ya", "inmediato", "immediately", "crítico", "critical"]
        let highKeywords = ["importante", "important", "prioridad", "priority"]
        let lowKeywords = ["cuando pueda", "when possible", "sin prisa", "no rush", "algún día"]
        
        if urgentKeywords.contains(where: { text.contains($0) }) { return .urgent }
        if highKeywords.contains(where: { text.contains($0) }) { return .high }
        if lowKeywords.contains(where: { text.contains($0) }) { return .low }
        return .normal
    }
    
    // MARK: - Duration Detection
    private static func detectDuration(_ text: String) -> Int? {
        if text.contains("1 hora") || text.contains("one hour") || text.contains("1h") { return 60 }
        if text.contains("30 min") || text.contains("media hora") { return 30 }
        if text.contains("2 hora") || text.contains("two hour") || text.contains("2h") { return 120 }
        if text.contains("15 min") { return 15 }
        return nil
    }
    
    // MARK: - Title Cleanup
    private static func cleanTitle(_ text: String) -> String {
        var clean = text
        
        // Remove common filler words at the start
        let prefixes = ["recordar ", "remind me to ", "no olvidar ", "tengo que ",
                       "necesito ", "i need to ", "hay que ", "agregar ", "add "]
        for prefix in prefixes {
            if clean.lowercased().hasPrefix(prefix) {
                clean = String(clean.dropFirst(prefix.count))
                break
            }
        }
        
        // Capitalize first letter
        if let first = clean.first {
            clean = first.uppercased() + clean.dropFirst()
        }
        
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
