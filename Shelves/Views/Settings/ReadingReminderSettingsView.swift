import SwiftUI

struct ReadingReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    ScrollView {
                        VStack(spacing: ShelvesDesign.Spacing.lg) {
                            headerSection
                            
                            if themeManager.notificationsEnabled {
                                frequencySection
                                timeSection
                                notificationTypesSection
                            } else {
                                enabledPromptSection
                            }
                        }
                        .padding(ShelvesDesign.Spacing.md)
                        .padding(.bottom, ShelvesDesign.Spacing.xl)
                    }
                )
                .navigationTitle("Reading Reminders")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive reading reminders, please enable notifications for Shelves in Settings.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(ShelvesDesign.Colors.primary)
                
                Text("Reading Reminders")
                    .font(ShelvesDesign.Typography.headlineLarge)
                    .foregroundColor(ShelvesDesign.Colors.text)
                
                Spacer()
            }
            
            Text("Get gentle nudges to maintain your reading habit and discover new books.")
                .font(ShelvesDesign.Typography.bodyMedium)
                .foregroundColor(ShelvesDesign.Colors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            WarmCardBackground()
        )
    }
    
    private var enabledPromptSection: some View {
        VStack(spacing: ShelvesDesign.Spacing.lg) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 48))
                    .foregroundColor(ShelvesDesign.Colors.textSecondary.opacity(0.6))
                
                Text("Enable Reading Reminders")
                    .font(ShelvesDesign.Typography.headlineMedium)
                    .foregroundColor(ShelvesDesign.Colors.text)
                
                Text("Turn on reading reminders to get motivated to read regularly and stay on top of your reading goals.")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Toggle("Enable Reading Reminders", isOn: $themeManager.notificationsEnabled)
                .font(ShelvesDesign.Typography.labelLarge)
                .foregroundColor(ShelvesDesign.Colors.text)
                .padding(.horizontal)
        }
        .padding()
        .background(
            WarmCardBackground()
        )
    }
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Frequency")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            VStack(spacing: ShelvesDesign.Spacing.sm) {
                ForEach(NotificationFrequency.allCases, id: \.rawValue) { frequency in
                    FrequencyOption(
                        frequency: frequency,
                        isSelected: notificationManager.frequency == frequency
                    ) {
                        notificationManager.frequency = frequency
                        if themeManager.notificationsEnabled {
                            notificationManager.scheduleReadingReminders()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            WarmCardBackground()
        )
    }
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Reminder Time")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            DatePicker(
                "Time",
                selection: $notificationManager.reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .onChange(of: notificationManager.reminderTime) { _, _ in
                if themeManager.notificationsEnabled {
                    notificationManager.scheduleReadingReminders()
                }
            }
        }
        .padding()
        .background(
            WarmCardBackground()
        )
    }
    
    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Notification Types")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            Text("Choose what types of reading reminders you'd like to receive:")
                .font(ShelvesDesign.Typography.bodySmall)
                .foregroundColor(ShelvesDesign.Colors.textSecondary)
            
            VStack(spacing: ShelvesDesign.Spacing.sm) {
                ForEach(NotificationType.allCases, id: \.rawValue) { type in
                    NotificationTypeToggle(
                        type: type,
                        isEnabled: notificationManager.enabledTypes.contains(type)
                    ) { isEnabled in
                        if isEnabled {
                            notificationManager.enabledTypes.insert(type)
                        } else {
                            notificationManager.enabledTypes.remove(type)
                        }
                        
                        if themeManager.notificationsEnabled {
                            notificationManager.scheduleReadingReminders()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            WarmCardBackground()
        )
    }
}

struct FrequencyOption: View {
    let frequency: NotificationFrequency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(frequency.rawValue)
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.text)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? ShelvesDesign.Colors.primary : ShelvesDesign.Colors.textSecondary)
                    .font(.title3)
            }
            .padding(.vertical, ShelvesDesign.Spacing.sm)
            .padding(.horizontal, ShelvesDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.small)
                    .fill(isSelected ? ShelvesDesign.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationTypeToggle: View {
    let type: NotificationType
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            )) {
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(type.rawValue)
                        .font(ShelvesDesign.Typography.labelMedium)
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
                    Text(type.description)
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                }
            }
            .padding(.vertical, ShelvesDesign.Spacing.sm)
        }
    }
}

#Preview {
    ReadingReminderSettingsView()
        .environmentObject(ThemeManager.shared)
}