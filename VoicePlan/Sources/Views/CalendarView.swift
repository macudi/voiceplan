import SwiftUI
import SwiftData

/// Monthly calendar view with task/event dots and day detail.
struct CalendarView: View {
    @Query private var allItems: [PlanItem]
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let weekdays = ["L", "M", "M", "J", "V", "S", "D"]
    
    var selectedDateItems: [PlanItem] {
        allItems.filter { item in
            guard let due = item.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: selectedDate)
        }
        .sorted { ($0.dueTime ?? .distantFuture) < ($1.dueTime ?? .distantFuture) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button {
                    withAnimation { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)! }
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)! }
                } label: {
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                }
            }
            .padding()
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            let days = calendarDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        DayCell(
                            date: day,
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(day),
                            hasItems: hasItems(on: day),
                            itemCount: itemCount(on: day)
                        )
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.2)) {
                                selectedDate = day
                            }
                        }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            // Selected day items
            VStack(alignment: .leading, spacing: 8) {
                Text(dayDetailTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                if selectedDateItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No items on this day")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    List(selectedDateItems) { item in
                        PlanItemRow(item: item)
                    }
                    .listStyle(.plain)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Calendar")
    }
    
    // MARK: - Helpers
    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "es")
        return f.string(from: displayedMonth).capitalized
    }
    
    private var dayDetailTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMMM"
        f.locale = Locale(identifier: "es")
        return f.string(from: selectedDate).capitalized
    }
    
    private func calendarDays() -> [Date?] {
        let month = calendar.component(.month, from: displayedMonth)
        let year = calendar.component(.year, from: displayedMonth)
        
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        
        let firstWeekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7 // Mon=0
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(date)
            }
        }
        
        // Pad to fill last row
        while days.count % 7 != 0 { days.append(nil) }
        
        return days
    }
    
    private func hasItems(on date: Date) -> Bool {
        allItems.contains { item in
            guard let due = item.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: date)
        }
    }
    
    private func itemCount(on date: Date) -> Int {
        allItems.filter { item in
            guard let due = item.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: date) && !item.isCompleted
        }.count
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasItems: Bool
    let itemCount: Int
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color(hex: "4A90D9"))
                        .frame(width: 34, height: 34)
                } else if isToday {
                    Circle()
                        .stroke(Color(hex: "4A90D9"), lineWidth: 2)
                        .frame(width: 34, height: 34)
                }
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : (isToday ? Color(hex: "4A90D9") : .primary))
            }
            
            // Dots for items
            HStack(spacing: 2) {
                ForEach(0..<min(itemCount, 3), id: \.self) { _ in
                    Circle()
                        .fill(isSelected ? Color(hex: "4A90D9") : Color(hex: "FF8C42"))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
            .opacity(hasItems ? 1 : 0)
        }
        .frame(height: 44)
    }
}
