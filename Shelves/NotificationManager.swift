import Foundation
import UserNotifications

enum NotificationFrequency: String, CaseIterable {
    case daily = "Daily"
    case everyOtherDay = "Every Other Day"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"

    var calendarComponent: Calendar.Component {
        return .day
    }

    var interval: Int {
        switch self {
        case .daily: return 1
        case .everyOtherDay: return 2
        case .weekly: return 7
        case .biweekly: return 14
        }
    }
}

enum NotificationType: String, CaseIterable {
    case currentlyReading = "Currently Reading"
    case wantToRead = "Want to Read"
    case generalReading = "General Reading"
    
    var description: String {
        switch self {
        case .currentlyReading:
            return "Remind me about books I'm currently reading"
        case .wantToRead:
            return "Remind me about books I want to read"
        case .generalReading:
            return "General reading motivation"
        }
    }
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    @Published var frequency: NotificationFrequency = .daily
    @Published var enabledTypes: Set<NotificationType> = [.currentlyReading, .generalReading]
    @Published var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 19 // 7 PM
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private init() {
        loadSettings()
        checkPermissionStatus()
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.hasPermission = granted
                if granted {
                    self.saveSettings()
                }
            }
            
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleReadingReminders() {
        guard hasPermission else { return }
        
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule new notifications based on settings
        let calendar = Calendar.current
        let now = Date()
        
        for i in 1...30 { // Schedule for next 30 occurrences
            guard let nextDate = calendar.date(byAdding: frequency.calendarComponent, value: frequency.interval * i, to: now) else {
                continue
            }
            let triggerDate = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: nextDate)
            
            // Update trigger to use the user's preferred time
            let preferredComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            var finalComponents = triggerDate
            finalComponents.hour = preferredComponents.hour
            finalComponents.minute = preferredComponents.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: finalComponents, repeats: false)
            
            // Create notification content based on enabled types
            if let content = createNotificationContent() {
                let request = UNNotificationRequest(
                    identifier: "reading-reminder-\(i)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification: \(error)")
                    }
                }
            }
        }
    }

    func cancelReadingReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func createNotificationContent() -> UNMutableNotificationContent? {
        let content = UNMutableNotificationContent()
        
        // Randomly select from enabled notification types
        let enabledTypesArray = Array(enabledTypes)
        guard !enabledTypesArray.isEmpty else { return nil }

        guard let selectedType = enabledTypesArray.randomElement() else {
            return nil
        }
        
        switch selectedType {
        case .currentlyReading:
            content.title = "📖 Continue Your Reading Journey"
            content.body = "Pick up where you left off with your current book!"
            
        case .wantToRead:
            content.title = "📚 Time to Start Something New"
            content.body = "Check out that book you've been wanting to read!"
            
        case .generalReading:
            let messages = [
                "A few pages today can make a big difference!",
                "Your next great book is waiting for you.",
                "Reading time! Even 10 minutes counts.",
                "Escape into a good story today.",
                "Feed your mind with some reading."
            ]
            content.title = "📚 Reading Time"
            content.body = messages.randomElement() ?? "Time to read!"
        }
        
        content.sound = .default
        content.categoryIdentifier = "READING_REMINDER"
        
        return content
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(frequency.rawValue, forKey: "notificationFrequency")
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        
        let enabledTypesStrings = enabledTypes.map { $0.rawValue }
        UserDefaults.standard.set(enabledTypesStrings, forKey: "enabledNotificationTypes")
    }
    
    private func loadSettings() {
        if let frequencyString = UserDefaults.standard.string(forKey: "notificationFrequency"),
           let loadedFrequency = NotificationFrequency(rawValue: frequencyString) {
            frequency = loadedFrequency
        }
        
        if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            reminderTime = savedTime
        }
        
        if let enabledTypesStrings = UserDefaults.standard.array(forKey: "enabledNotificationTypes") as? [String] {
            enabledTypes = Set(enabledTypesStrings.compactMap { NotificationType(rawValue: $0) })
        }
    }
}