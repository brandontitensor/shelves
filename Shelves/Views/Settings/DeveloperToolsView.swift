//
//  DeveloperToolsView.swift
//  Shelves
//
//  Hidden developer tools and feature flags
//

import SwiftUI

struct DeveloperToolsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var developerSettings: DeveloperSettings

    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    ScrollView {
                        VStack(spacing: ShelvesDesign.Spacing.lg) {
                            headerSection
                            featureFlagsSection
                            actionsSection
                        }
                        .padding(ShelvesDesign.Spacing.md)
                        .padding(.bottom, ShelvesDesign.Spacing.xl)
                    }
                )
                .navigationTitle("Developer Tools")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }

    private var headerSection: some View {
        VStack(spacing: ShelvesDesign.Spacing.md) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(ShelvesDesign.Colors.antiqueGold)

            Text("Developer Mode")
                .font(ShelvesDesign.Typography.titleLarge)
                .foregroundColor(ShelvesDesign.Colors.text)

            Text("Control which development features are visible in the app. These settings persist across app launches.")
                .font(ShelvesDesign.Typography.bodyMedium)
                .foregroundColor(ShelvesDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, ShelvesDesign.Spacing.lg)
    }

    private var featureFlagsSection: some View {
        SettingsCard(
            title: "Feature Flags",
            subtitle: "Toggle developer features",
            icon: "flag.fill",
            iconColor: ShelvesDesign.Colors.forestGreen
        ) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                FeatureToggle(
                    title: "Test Data Generator",
                    description: "Show option to populate library with 100 test books",
                    icon: "books.vertical.fill",
                    isOn: $developerSettings.showTestDataGenerator
                )

                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)

                FeatureToggle(
                    title: "Clear All Books",
                    description: "Show option to clear entire library in development section",
                    icon: "trash.fill",
                    isOn: $developerSettings.showClearDataOption
                )

                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)

                FeatureToggle(
                    title: "Library Statistics",
                    description: "Show detailed library stats in settings",
                    icon: "chart.bar.fill",
                    isOn: $developerSettings.showLibraryStats
                )

                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)

                FeatureToggle(
                    title: "Debug Logging",
                    description: "Enable verbose console logging (requires app restart)",
                    icon: "text.alignleft",
                    isOn: $developerSettings.enableDebugLogging
                )

                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)

                FeatureToggle(
                    title: "Performance Metrics",
                    description: "Show performance metrics and memory usage",
                    icon: "speedometer",
                    isOn: $developerSettings.showPerformanceMetrics
                )
            }
        }
    }

    private var actionsSection: some View {
        SettingsCard(
            title: "Quick Actions",
            subtitle: "Manage developer settings",
            icon: "bolt.fill",
            iconColor: ShelvesDesign.Colors.burgundy
        ) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                Button {
                    developerSettings.enableAllFeatures()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Enable All Features")
                            .font(ShelvesDesign.Typography.labelLarge)
                            .foregroundColor(ShelvesDesign.Colors.text)
                        Spacer()
                    }
                    .padding(.vertical, ShelvesDesign.Spacing.sm)
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)

                Button {
                    developerSettings.resetAllSettings()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .foregroundColor(.orange)
                        Text("Disable All Features")
                            .font(ShelvesDesign.Typography.labelLarge)
                            .foregroundColor(ShelvesDesign.Colors.text)
                        Spacer()
                    }
                    .padding(.vertical, ShelvesDesign.Spacing.sm)
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)

                Button {
                    developerSettings.isDeveloperModeEnabled = false
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Exit Developer Mode")
                            .font(ShelvesDesign.Typography.labelLarge)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, ShelvesDesign.Spacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct FeatureToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(ShelvesDesign.Colors.chestnut)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(title)
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.text)

                    Text(description)
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(ShelvesDesign.Colors.antiqueGold)
            }
        }
    }
}
