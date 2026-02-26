import SwiftUI
import SwiftData

/// The voice recording interface — big red button, live waveform, live transcription.
struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var recorder = VoiceRecorder()
    @State private var parsedItems: [TextParser.ParsedResult] = []
    @State private var showResults = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showResults {
                    resultsView
                } else {
                    recordingView
                }
            }
            .navigationTitle(showResults ? "Review" : "Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .hoverEffect(.highlight)
                }
            }
        }
        .sensoryFeedback(.impact, trigger: recorder.isRecording)
        .sensoryFeedback(.impact, trigger: showResults)
        #if os(visionOS)
        .glassBackgroundEffect()
        #endif
    }
    
    // MARK: - Recording View
    var recordingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Waveform visualization
            WaveformView(level: recorder.audioLevel, isActive: recorder.isRecording)
                .frame(height: 100)
                .padding(.horizontal)
            
            // Duration
            Text(recorder.durationString)
                .font(.system(size: 24, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            
            // Live transcription
            if !recorder.transcription.isEmpty {
                ScrollView {
                    Text(recorder.transcription)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular)
                }
                .frame(maxHeight: 150)
                .padding(.horizontal)
            } else if recorder.isRecording {
                Text("Listening...")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .glassEffect(.regular)
            }
            
            Spacer()
            
            // Record button
            Button {
                if recorder.isRecording {
                    recorder.stopRecording()
                    // Parse transcription
                    if !recorder.transcription.isEmpty {
                        parsedItems = TextParser.parse(recorder.transcription)
                        withAnimation(.spring(duration: 0.4)) {
                            showResults = true
                        }
                    }
                } else {
                    Task {
                        let granted = await recorder.requestPermissions()
                        if granted {
                            recorder.startRecording()
                        }
                    }
                }
            } label: {
                ZStack {
                    // Pulse ring when recording
                    if recorder.isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 3)
                            .frame(width: 96, height: 96)
                            .scaleEffect(recorder.isRecording ? 1.3 : 1)
                            .opacity(recorder.isRecording ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1).repeatForever(autoreverses: false),
                                value: recorder.isRecording
                            )
                    }
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Group {
                                if recorder.isRecording {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 28, height: 28)
                                }
                            }
                        )
                        .shadow(color: .red.opacity(0.3), radius: 10, y: 4)
                }
            }
            .buttonStyle(.plain)
            .glassEffect(.circular)
            .hoverEffect(.highlight)
            
            Text(recorder.isRecording ? "Tap to stop" : "Tap to record")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
                .frame(height: 40)
        }
    }
    
    // MARK: - Results View
    var resultsView: some View {
        VStack(spacing: 16) {
            // Original transcription
            VStack(alignment: .leading, spacing: 8) {
                Label("Transcription", systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(recorder.transcription)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Extracted items
            Label("Extracted Items (\(parsedItems.count))", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(parsedItems.enumerated()), id: \.offset) { index, item in
                        ParsedItemRow(item: item)
                    }
                }
                .padding(.horizontal)
            }
            
            // Save button
            Button {
                saveItems()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save All (\(parsedItems.count) items)")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "4A90D9"), in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
            }
            .hoverEffect(.highlight)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Save
    private func saveItems() {
        let memo = VoiceMemo(
            transcription: recorder.transcription,
            duration: recorder.recordingDuration
        )
        modelContext.insert(memo)
        
        for parsed in parsedItems {
            let item = PlanItem(title: parsed.title, category: parsed.category)
            item.dueDate = parsed.dueDate
            item.dueTime = parsed.dueTime
            item.priority = parsed.priority
            item.isEvent = parsed.isEvent
            item.eventDuration = parsed.eventDuration
            item.isFromVoice = true
            item.voiceMemoID = memo.id
            
            // Auto-assign list based on date
            if parsed.dueDate != nil {
                if Calendar.current.isDateInToday(parsed.dueDate!) {
                    item.listName = "Today"
                } else {
                    item.listName = "Upcoming"
                }
            }
            
            modelContext.insert(item)
            memo.extractedItems.append(item.title)
        }
        
        memo.isProcessed = true
    }
}

// MARK: - Parsed Item Row
struct ParsedItemRow: View {
    let item: TextParser.ParsedResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.title3)
                .foregroundStyle(Color(hex: item.category.color))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: item.category.color).opacity(0.15),
                                    in: Capsule())
                        .foregroundStyle(Color(hex: item.category.color))
                    
                    if let date = item.dueDate {
                        Label(formatDate(date), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if item.priority == .high || item.priority == .urgent {
                        Label(item.priority.label, systemImage: item.priority.icon)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .glassEffect(.regular)
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }
}

// MARK: - Waveform
struct WaveformView: View {
    let level: Float
    let isActive: Bool
    
    @State private var bars: [CGFloat] = Array(repeating: 0.1, count: 30)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    MeshGradient(
                        width: 2,
                        height: 2,
                        points: [
                            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(1.0, 0.0),
                            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(1.0, 1.0)
                        ],
                        colors: [
                            Color.red.opacity(0.92),
                            Color.orange.opacity(0.9),
                            Color.pink.opacity(0.88),
                            Color.blue.opacity(0.85)
                        ]
                    )
                    .opacity(isActive ? 0.36 : 0.1)
                )
                .glassEffect(.regular)
            
            HStack(spacing: 3) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, height in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isActive ? Color.white.opacity(0.88) : Color.gray.opacity(0.22))
                        .frame(width: 4, height: max(4, height * 80))
                        .animation(.spring(duration: 0.15), value: height)
                }
            }
        }
        .onChange(of: level) { _, newLevel in
            guard isActive else { return }
            // Shift bars left, add new level on right
            bars.removeFirst()
            bars.append(CGFloat(newLevel) + CGFloat.random(in: 0...0.15))
        }
    }
}

// MARK: - Color Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
