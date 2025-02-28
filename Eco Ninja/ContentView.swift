import SwiftUI

enum MenuItem: String, CaseIterable, Hashable, Identifiable {
    case dashboard, foodLogs, terms, settings

    var id: String {
            return rawValue
    }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .foodLogs: return "Food Logs"
        case .terms: return "Terms"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .foodLogs: return "fork.knife"
        case .terms: return "doc.text"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: MenuItem? = .dashboard
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List (MenuItem.allCases, selection: $selectedItem){ item in
                NavigationLink(item.title, value: item)
            }
            .navigationTitle("Menu")
            .listStyle(.sidebar)
        } detail: {
            // Main Content
            if let selectedItem {
                selectedView(for: selectedItem)
                    .navigationTitle(selectedItem.title)
            } else {
                Text("Select an item")
            }
        }
    }

    @ViewBuilder
    private func selectedView(for item: MenuItem) -> some View {
        switch item {
        case .dashboard: DashboardView()
        case .foodLogs: FoodLogsView()
        case .terms: TermsView()
        case .settings: SettingsView()
        }
    }
}

struct DashboardView: View {
    var body: some View {
        Text("Dashboard Content")
            .padding()
    }
}

struct FoodLogsView: View {
    var body: some View {
        Text("Food Logs Content")
            .padding()
    }
}

struct TermsView: View {
    var body: some View {
        Text("TOS and PP Content")
            .padding()
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings Content")
            .padding()
    }
}
