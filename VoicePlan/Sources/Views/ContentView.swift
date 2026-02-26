import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showRecordSheet = false
    
    var body: some View {
        #if os(macOS)
        macOSContent
        #else
        iOSContent
        #endif
    }
    
    // MARK: - iOS/iPadOS/visionOS
    var iOSContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                InboxView(listName: "Inbox")
            }
            .tabItem { Label("Inbox", systemImage: "tray.fill") }
            .tag(0)
            
            NavigationStack {
                InboxView(listName: "Today")
            }
            .tabItem { Label("Today", systemImage: "star.fill") }
            .tag(1)
            
            NavigationStack {
                CalendarView()
            }
            .tabItem { Label("Calendar", systemImage: "calendar") }
            .tag(2)
            
            NavigationStack {
                InboxView(listName: "Upcoming")
            }
            .tabItem { Label("Upcoming", systemImage: "clock") }
            .tag(3)
            
            NavigationStack {
                InboxView(listName: "Someday")
            }
            .tabItem { Label("Someday", systemImage: "archivebox") }
            .tag(4)
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(Color(hex: "4A90D9"))
        #if os(visionOS)
        .glassBackgroundEffect()
        .ornament(
            visibility: .visible,
            attachmentAnchor: .scene(.bottom),
            contentAlignment: .center
        ) {
            recordButton
                .padding(.bottom, 12)
        }
        #else
        .overlay(alignment: .bottom) {
            recordButton
                .offset(y: -30)
        }
        #endif
        .sheet(isPresented: $showRecordSheet) {
            RecordView()
                .presentationSizing(.form)
        }
    }
    
    // MARK: - macOS
    var macOSContent: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section("Views") {
                    Label("Inbox", systemImage: "tray.fill").tag(0)
                    Label("Today", systemImage: "star.fill").tag(1)
                    Label("Calendar", systemImage: "calendar").tag(2)
                    Label("Upcoming", systemImage: "clock").tag(3)
                    Label("Someday", systemImage: "archivebox").tag(4)
                }
            }
            .navigationTitle("VoicePlan")
            .toolbar {
                ToolbarItem {
                    Button {
                        showRecordSheet = true
                    } label: {
                        Label("Record", systemImage: "mic.fill")
                    }
                    .tint(.red)
                    #if !os(macOS)
                    .hoverEffect(.highlight)
                    #endif
                }
            }
        } detail: {
            switch selectedTab {
            case 0: NavigationStack { InboxView(listName: "Inbox") }
            case 1: NavigationStack { InboxView(listName: "Today") }
            case 2: NavigationStack { CalendarView() }
            case 3: NavigationStack { InboxView(listName: "Upcoming") }
            case 4: NavigationStack { InboxView(listName: "Someday") }
            default: EmptyView()
            }
        }
        .tint(Color(hex: "4A90D9"))
        .sheet(isPresented: $showRecordSheet) {
            RecordView()
                .presentationSizing(.form)
                .frame(minWidth: 500, minHeight: 600)
        }
    }
    
    private var recordButton: some View {
        Button {
            showRecordSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                    .shadow(color: .red.opacity(0.35), radius: 10, y: 4)
                
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .glassEffect(.circular)
        .hoverEffect(.highlight)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlanItem.self, VoiceMemo.self, PlanList.self], inMemory: true)
}
