import Foundation
import SwiftData

/// User-created lists (like Things areas/projects)
@Model
final class PlanList {
    var name: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    var isDefault: Bool     // Inbox, Today, etc. — can't be deleted
    
    init(name: String, icon: String = "list.bullet", colorHex: String = "4A90D9", sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = false
    }
    
    static var defaultLists: [PlanList] {
        let lists = [
            PlanList(name: "Inbox", icon: "tray.fill", colorHex: "4A90D9", sortOrder: 0),
            PlanList(name: "Today", icon: "star.fill", colorHex: "FFD60A", sortOrder: 1),
            PlanList(name: "Upcoming", icon: "calendar", colorHex: "FF8C42", sortOrder: 2),
            PlanList(name: "Someday", icon: "archivebox", colorHex: "8E8E93", sortOrder: 3),
        ]
        lists.forEach { $0.isDefault = true }
        return lists
    }
}
