//
//  ContentView.swift
//  Eco Ninja
//
//  Created by Maggie on 2025/2/26.
//

import SwiftUI
import SwiftData

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
    @State private var selectedItem: MenuItem? = nil
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    @State private var navigationPath = NavigationPath()

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
                NavigationStack(path: $navigationPath) { // Use NavigationStack with path
                    selectedView(for: selectedItem)
                        .navigationTitle(selectedItem.title)
                }
            }
        }
    }

    @ViewBuilder
    private func selectedView(for item: MenuItem) -> some View {
        switch item {
        case .dashboard: DashboardView()
        case .foodLogs: LogsView(navigationPath: $navigationPath)
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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.exp, order: .forward) private var records: [Record]
    @State private var isAddingRecord = false
    @State private var searchText = ""
    @State private var recordToDelete: Record?
    @State private var showDeleteAlert = false
    @State private var editingRecord: Record?
    @State private var showEditSheet = false// State to hold the record being edited
    @State private var selectedRecord: Record?
    
    @Binding var navigationPath: NavigationPath

    var body: some View {
//        NavigationView {
            VStack(spacing: 0) {
                // Manual Search Bar with Reduced Height
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("搜尋", text: $searchText)
                        .padding(.horizontal)
                }
                .padding(.vertical, 8) // Reduced vertical padding
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .frame(height: 36)

                List {
                    ForEach(filteredRecords) { record in
                        NavigationLink(value: record) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(record.name)
                                        .font(.headline)
                                    Text(record.category.rawValue)
                                        .font(.subheadline)
                                    Text(record.exp, style: .date)
                                        .font(.caption)
                                }
                                Spacer()
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button(role: .destructive) {
                                recordToDelete = record
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }                    }
                }
                .listStyle(PlainListStyle())
            }
//            .navigationTitle("紀錄")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingRecord = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingRecord) {
                RecordEditor() // Use the combined editor for adding
            }
            .alert("刪除紀錄", isPresented: $showDeleteAlert) {
                Button("刪除", role: .destructive) {
                    if let record = recordToDelete {
                        deleteRecord(record)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("請問您確定要刪除紀錄嗎？")
            }
            .navigationDestination(for: Record.self) { record in // Navigation destination
                RecordEditor(record: record)
            }
    }

    private var filteredRecords: [Record] {
        if searchText.isEmpty {
            return records
        } else {
            return records.filter { record in
                record.name.localizedCaseInsensitiveContains(searchText) ||
                record.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                record.exp.formatted(date: .abbreviated, time: .omitted).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func deleteRecord(_ record: Record) {
        modelContext.delete(record)
        recordToDelete = nil
    }
}


struct RecordEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // To dismiss the sheet
    // Optional record for both adding and editing
    @State private var name: String = ""
    @State private var category: Category = .grains
    @State private var exp: Date = Date()
    var record: Record?

    init(record: Record? = nil) { // Initialize with optional record
        self.record = record
        if let record = record {
            _name = State(initialValue: record.name)
            _category = State(initialValue: record.category)
            _exp = State(initialValue: record.exp)
        }
    }

    var body: some View {
        if let record = record {
            //        NavigationView {
            Form {
                TextField("名稱", text: $name)
                Picker("類別", selection: $category) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                DatePicker("到期日", selection: $exp, in: Date.now..., displayedComponents: .date)
            }
            .navigationTitle("編輯紀錄")
            .toolbar {
                //                ToolbarItem(placement: .cancellationAction) {
                //                    Button("取消") {
                //                        dismiss()
                //                    }
                //                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確定") {
//                        if let record = record {
                            updateRecord(record)
//                        } else {
//                            addRecord()
//                        }
                        dismiss()
                    }
                }
            }//        }
        } else {
            NavigationStack {
                Form {
                    TextField("名稱", text: $name)
                    Picker("類別", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    DatePicker("到期日", selection: $exp, in: Date.now..., displayedComponents: .date)
                }
                .navigationTitle("新增紀錄")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("確定") {
                            addRecord()
                            dismiss()
                        }
                    }
                }
            }
        }
        
    }

    private func addRecord() {
        guard !name.isEmpty else { return }
        let newRecord = Record(name: name, category: category, exp: exp)
        modelContext.insert(newRecord)
    }

    private func updateRecord(_ record: Record) {
        guard !name.isEmpty else { return }
        record.name = name
        record.category = category
        record.exp = exp
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
