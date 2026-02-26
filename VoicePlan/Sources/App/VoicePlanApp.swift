import SwiftUI
import SwiftData

@main
struct VoicePlanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PlanItem.self, VoiceMemo.self, PlanList.self])
        
        #if os(macOS)
        Settings {
            Text("VoicePlan Settings")
                .padding()
        }
        #endif
    }
}
