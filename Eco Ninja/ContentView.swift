//
//  ContentView.swift
//  Eco Ninja
//
//  Created by Maggie on 2025/2/26.
//

import SwiftUI
import SwiftData
import Foundation
import UserNotifications
import LocalAuthentication

enum MenuItem: String, CaseIterable, Hashable, Identifiable {
    case dashboard, foodLogs, recipes, analytics, donations, settings, terms

    var id: String {
            return rawValue
    }
    
    var title: String {
        switch self {
        case .dashboard: return "主頁"
        case .foodLogs: return "紀錄"
        case .recipes: return "食譜"
        case .donations: return "捐贈"
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
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }
}

extension String
{
    var localized: String
    {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }


    func localizedWithComment(comment:String) -> String
    {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: comment)
    }
}


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set the delegate for UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notifications when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification as a banner and play a sound
        completionHandler([.banner, .sound])
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
                    Label(item.title.localized, systemImage: item.icon)
                }
            }
            .navigationTitle("選單".localized)
            .listStyle(.sidebar)
        } detail: {
            // Main Content
            if let selectedItem { // Use if let to safely unwrap selectedItem
                NavigationStack(path: $navigationPath) { // Use NavigationStack with path
                    selectedView(for: selectedItem)
                        .navigationTitle(selectedItem.title.localized)
                }
            }
        }
        .font(.system(size : 20))
    }

    @ViewBuilder
    private func selectedView(for item: MenuItem) -> some View {
        switch item {
        case .dashboard: DashboardView()
        case .foodLogs: LogsView(navigationPath: $navigationPath)
        case .recipes: RecipesView()
        case .donations: DonationView()
        case .terms: TermsView()
        case .settings: SettingsView()
        case .analytics: AnalyticsView()
        }
    }
}

struct DashboardView: View {
    var body: some View {
        Text("主頁")
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
        VStack(spacing: 0) {
            // Manual Search Bar with Reduced Height
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜尋".localized, text: $searchText)
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
                                Text(record.category.rawValue.localized)
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
                            Label("刪除".localized, systemImage: "trash")
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
        .alert("刪除紀錄".localized, isPresented: $showDeleteAlert) {
            Button("刪除".localized, role: .destructive) {
                if let record = recordToDelete {
                    deleteRecord(record)
                }
            }
            Button("取消".localized, role: .cancel) {}
        } message: {
            Text("請問您確定要刪除紀錄嗎？".localized)
        }
        .navigationDestination(for: Record.self) { record in // Navigation destination
            RecordEditor(record: record)
        }
        .font(.system(size : 20))
    }

    private var filteredRecords: [Record] {
        if searchText.isEmpty {
            return records
        } else {
            return records.filter { record in
                record.name.localizedCaseInsensitiveContains(searchText) ||
                record.category.rawValue.localized.localizedCaseInsensitiveContains(searchText) ||
                record.exp.formatted(date: .long, time: .omitted).localizedCaseInsensitiveContains(searchText)
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
            Form {
                TextField("名稱".localized, text: $name)
                Picker("類別".localized, selection: $category) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Text(category.rawValue.localized).tag(category)
                    }
                }
                DatePicker("到期日".localized, selection: $exp, in: Date.now..., displayedComponents: .date)
                Button("確定".localized) {
                    updateRecord(record)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("編輯紀錄".localized)
            .font(.system(size : 20))
        } else {
            NavigationStack {
                Form {
                    TextField("名稱".localized, text: $name)
                    Picker("類別".localized, selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue.localized).tag(category)
                        }
                    }
                    DatePicker("到期日".localized, selection: $exp, in: Date.now..., displayedComponents: .date)
                }
                .navigationTitle("新增紀錄".localized)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("確定".localized) {
                            addRecord()
                            dismiss()
                        }
                    }
                }
            }
            .font(.system(size : 20))
        }
        
    }

    private func addRecord() {
        guard !name.isEmpty else { return }
        let newRecord = Record(name: name, category: category, exp: exp)
        modelContext.insert(newRecord)
        scheduleNotification(for: newRecord)
    }

    private func updateRecord(_ record: Record) {
        guard !name.isEmpty else { return }
        record.name = name
        record.category = category
        record.exp = exp
        scheduleNotification(for: record)
    }
    
    private func scheduleNotification(for record: Record) {
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        let reminderDays = UserDefaults.standard.integer(forKey: "reminderDays")
        let notificationTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date ?? Date()
        
        guard notificationsEnabled else { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests() { requests in
            for request in requests {
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return }
                print("Notification registered with id \(request.identifier) is schedulled for \(trigger.nextTriggerDate()?.description ?? "(not schedulled)")")
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "物品即將到期".localized
        content.body = "\(record.name)" + " 將於 ".localized + "\(record.exp.formatted(date: .abbreviated, time: .omitted)) " + " 到期喔！".localized
        content.sound = UNNotificationSound.default

        let notificationDate = Calendar.current.date(byAdding: .day, value: -reminderDays, to: record.exp)!
        let notificationDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: notificationTime), minute: Calendar.current.component(.minute, from: notificationTime), second: 0, of: notificationDate)!

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDateTime), repeats: false)

        let request = UNNotificationRequest(identifier: record.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }
}


struct TermsView: View {
    var body: some View {
        Text("條款")
            .padding()
    }
}


struct SecureInputView: View {
    
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecured {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                        .autocorrectionDisabled(true)
                }
            }.padding(.trailing, 32)

            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
        }
    }
}

// preview canva in the right hand side to test layout
#Preview {
    Credentials()
}

struct SettingsView: View {
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var reminderDays: Int = UserDefaults.standard.integer(forKey: "reminderDays")
    @State private var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var notificationTime: Date = UserDefaults.standard.object(forKey: "notificationTime") as? Date ?? Date()
    
    @State private var isAuthenticated = false // State to track authentication
    @State private var navigateToCredentials = false
    
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("個人資料")) {
                    TextField("姓名", text: $userName)
                        .onChange(of: userName) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "userName")
                        }
                }
                
                Section(header: Text("通知設定")) {
                    Stepper("到期前 \(reminderDays) 天提醒", value: $reminderDays, in: 0...31)
                        .onChange(of: reminderDays) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "reminderDays")
                            updateExistingNotifications(using: modelContext)
                        }
                    DatePicker("通知時間", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        .onChange(of: notificationTime) { _, _ in
                            UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
                            updateExistingNotifications(using: modelContext)
                        }
                    Toggle("啟用通知", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { oldValue, newValue in
                            if newValue {
                                requestNotificationPermission { granted in
                                    if granted {
                                        notificationsEnabled = true
                                        UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                                        updateExistingNotifications(using: modelContext)
                                    } else {
                                        notificationsEnabled = false
                                    }
                                }
                            } else {
                                notificationsEnabled = false
                                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                                removeAllNotifications()
                            }
                        }
                }
                Section(header: Text("其他資料")) {
                    // Use a Button to trigger authentication
                    Button(action: {
                        authenticateUser { success in
                            if success {
                                navigateToCredentials = true // Navigate after successful authentication
                            } else {
                                print("Authentication failed")
                            }
                        }
                    }) {
                        Label("重要資料".localized, systemImage: "key")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToCredentials) {
            Credentials() // Navigate to Crendentials view
        }
    }
    
    // Authentication Function
    private func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access important data"
            
            // Perform biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true) // Authentication succeeded
                    } else {
                        completion(false) // Authentication failed
                    }
                }
            }
        } else {
            // Fallback to device passcode if biometrics are not available
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to access important data") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true) // Authentication succeeded
                    } else {
                        completion(false) // Authentication failed
                    }
                }
            }
        }
    }

    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted.")
                    completion(true)
                } else {
                    print("Notification permission denied.")
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    completion(false)
                }
            }
        }
    }
    
    private func updateExistingNotifications(using modelContext: ModelContext) {
        // First, remove all existing notifications
        print("Removed all notifications.")
        removeAllNotifications()
        
        // Then, fetch all records and schedule new notifications
        let descriptor = FetchDescriptor<Record>()
        if let records = try? modelContext.fetch(descriptor) {
            for record in records {
                print(record.exp.formatted(date: .abbreviated, time: .omitted))
                scheduleNotification(for: record)
            }
        }
    }

    private func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleNotification(for record: Record) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "物品即將到期".localized
        content.body = "\(record.name)" + " 將於 ".localized + "\(record.exp.formatted(date: .abbreviated, time: .omitted)) " + " 到期喔！".localized
        content.sound = UNNotificationSound.default
        
        let notificationDate = Calendar.current.date(byAdding: .day, value: -reminderDays, to: record.exp)!
        let notificationDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: notificationTime), minute: Calendar.current.component(.minute, from: notificationTime), second: 0, of: notificationDate)!

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDateTime), repeats: false)

        let request = UNNotificationRequest(identifier: record.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }
}


struct Credentials: View {
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "spoonacularApiKey") ?? ""
    
    var body: some View {
        Form{
            Section(header: Text("API 設定")) {
//                SecureField("Spoonacular API 密鑰".localized, text: $apiKey)
//                    .onChange(of: apiKey) { _, newValue in
//                        UserDefaults.standard.set(newValue, forKey: "spoonacularApiKey")
//                    }
                SecureInputView("Spoonacular API 密鑰".localized, text: $apiKey)
                    .onChange(of: apiKey) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "spoonacularApiKey")
                    }
            }
        }
    }
}


struct RecipesView: View {
    var body: some View {
        Text("分析")
            .padding()
    }
}


struct AnalyticsView: View {
    var body: some View {
        Text("分析")
            .padding()
    }
}

struct DonationView: View {
    var body: some View {
        Text("捐贈")
            .padding()
    }
}

