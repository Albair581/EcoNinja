//
//  ContentView.swift
//  Eco Ninja
//
//  Created by Maggie on 2025/2/26.
//

import SwiftUI

enum MenuItem: String, CaseIterable, Hashable, Identifiable {
    case dashboard, foodLogs, recipes, analytics, donations, compost, settings, terms

    var id: String {
            return rawValue
    }
    
    var title: String {
        switch self {
        case .dashboard: return "主頁"
        case .foodLogs: return "紀錄"
        case .recipes: return "食譜"
        case .donations: return "捐贈"
        case .compost: return "施肥"
        case .terms: return "條款"
        case .settings: return "設定"
        case .analytics: return "分析";
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .foodLogs: return "list.bullet"
        case .terms: return "doc.text"
        case .settings: return "gear"
        case .recipes: return "book"
        case .donations: return "gift"
        case .compost: return "leaf.arrow.circlepath"
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: MenuItem? = .dashboard
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(MenuItem.allCases, selection: $selectedItem) { item in // Use selection parameter
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.icon)
                }
            }
            .navigationTitle("選單")
            .listStyle(.sidebar)
        } detail: {
            // Main Content
            if let selectedItem { // Use if let to safely unwrap selectedItem
                selectedView(for: selectedItem)
                    .navigationTitle(selectedItem.title)
            }
        }
    }

    @ViewBuilder
    private func selectedView(for item: MenuItem) -> some View {
        switch item {
        case .dashboard: DashboardView()
        case .foodLogs: LogsView()
        case .recipes: RecipesView()
        case .donations: DonationView()
        case .compost: CompostView()
        case .terms: TermsView()
        case .settings: SettingsView()
        case .analytics: AnalyticsView()
        }
    }
}

struct DashboardView: View {
    var body: some View {
        Text("主頁畫面")
            .padding()
    }
}

struct LogsView: View {
    var body: some View {
        Text("紀錄畫面")
            .padding()
    }
}

struct TermsView: View {
    var body: some View {
        Text("條款畫面")
            .padding()
    }
}

struct SettingsView: View {
    var body: some View {
        Text("設定畫面")
            .padding()
    }
}

struct RecipesView: View {
    var body: some View {
        Text("食譜畫面")
            .padding()
    }
}

struct AnalyticsView: View {
    var body: some View {
        Text("分析畫面")
            .padding()
    }
}

struct CompostView: View {
    var body: some View {
        Text("施肥畫面")
            .padding()
    }
}

struct DonationView: View {
    var body: some View {
        Text("捐贈畫面")
            .padding()
    }
}
