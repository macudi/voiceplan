import SwiftUI
import SwiftData

/// Things-style inbox view — shows all items in a specific list.
struct InboxView: View {
    let listName: String
    
    @Query private var allItems: [PlanItem]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddItem = false
    @State private var newItemTitle = ""
    
    var items: [PlanItem] {
        allItems.filter { $0.listName == listName && !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    var completedItems: [PlanItem] {
        allItems.filter { $0.listName == listName && $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
    
    var body: some View {
        List {
            // Quick add
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color(hex: "4A90D9"))
                        .font(.title3)
                    
                    TextField("New item...", text: $newItemTitle)
                        .onSubmit { addItem() }
                    
                    if !newItemTitle.isEmpty {
                        Button("Add") { addItem() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "4A90D9"))
                            .controlSize(.small)
                    }
                }
            }
            
            // Active items
            if items.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: emptyIcon)
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text(emptyMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                Section("\(items.count) items") {
                    ForEach(items) { item in
                        PlanItemRow(item: item)
                    }
                    .onDelete { offsets in
                        for i in offsets { modelContext.delete(items[i]) }
                    }
                }
            }
            
            // Completed
            if !completedItems.isEmpty {
                Section("Completed (\(completedItems.count))") {
                    ForEach(completedItems.prefix(10)) { item in
                        PlanItemRow(item: item)
                    }
                    .onDelete { offsets in
                        for i in offsets { modelContext.delete(completedItems[i]) }
                    }
                }
            }
        }
        .navigationTitle(listName)
    }
    
    private func addItem() {
        guard !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let item = PlanItem(title: newItemTitle, listName: listName)
        if listName == "Today" { item.dueDate = Date() }
        modelContext.insert(item)
        newItemTitle = ""
    }
    
    private var emptyIcon: String {
        switch listName {
        case "Inbox": "tray"
        case "Today": "star"
        case "Upcoming": "calendar"
        default: "archivebox"
        }
    }
    
    private var emptyMessage: String {
        switch listName {
        case "Inbox": "Inbox is clear! 🎉"
        case "Today": "Nothing planned for today"
        case "Upcoming": "No upcoming items"
        default: "Nothing here yet"
        }
    }
}

// MARK: - Plan Item Row
struct PlanItemRow: View {
    @Bindable var item: PlanItem
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    item.isCompleted.toggle()
                    item.completedAt = item.isCompleted ? Date() : nil
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted
                        ? Color(hex: item.category.color)
                        : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if item.isFromVoice {
                        Image(systemName: "waveform")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Text(item.title)
                        .font(.body)
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                }
                
                HStack(spacing: 8) {
                    // Category badge
                    Image(systemName: item.category.icon)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: item.category.color))
                    
                    // Due date
                    if let due = item.dueDate {
                        Label(formatDue(due), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(item.isOverdue ? .red : .secondary)
                    }
                    
                    // Time
                    if let time = item.dueTime {
                        Label(formatTime(time), systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Priority
                    if item.priority == .high || item.priority == .urgent {
                        Image(systemName: item.priority.icon)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDue(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
