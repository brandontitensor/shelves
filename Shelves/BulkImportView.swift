import SwiftUI
import UniformTypeIdentifiers

struct BulkImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedFormat: ImportFormat = .csv
    @State private var showingFilePicker = false
    @State private var showingImportResult = false
    @State private var isImporting = false
    @State private var importResult: ImportResult?
    @State private var selectedFileURL: URL?
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    ScrollView {
                        VStack(spacing: ShelvesDesign.Spacing.lg) {
                            headerSection
                            formatSelectionSection
                            fileSelectionSection
                            
                            if let url = selectedFileURL {
                                previewSection(url: url)
                            }
                            
                            instructionsSection
                        }
                        .padding(ShelvesDesign.Spacing.md)
                        .padding(.bottom, ShelvesDesign.Spacing.xl)
                    }
                )
                .navigationTitle("Import Books")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Import") {
                            startImport()
                        }
                        .disabled(selectedFileURL == nil || isImporting)
                    }
                }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: selectedFormat.supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFileURL = url
                }
            case .failure:
                // File selection failed
                break
            }
        }
        .sheet(isPresented: $showingImportResult) {
            ImportResultView(result: importResult ?? ImportResult(
                successCount: 0,
                failedCount: 0,
                duplicateCount: 0,
                errors: [],
                importedBooks: []
            ))
        }
        .overlay(
            Group {
                if isImporting {
                    ImportingOverlay()
                }
            }
        )
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            HStack {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.title2)
                    .foregroundColor(ShelvesDesign.Colors.primary)
                
                Text("Bulk Import")
                    .font(ShelvesDesign.Typography.headlineLarge)
                    .foregroundColor(ShelvesDesign.Colors.text)
                
                Spacer()
            }
            
            Text("Import multiple books from a file to quickly build your library.")
                .font(ShelvesDesign.Typography.bodyMedium)
                .foregroundColor(ShelvesDesign.Colors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(WarmCardBackground())
    }
    
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("File Format")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            VStack(spacing: ShelvesDesign.Spacing.sm) {
                ForEach(ImportFormat.allCases, id: \.rawValue) { format in
                    FormatOption(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        selectedFormat = format
                        selectedFileURL = nil // Reset file selection when format changes
                    }
                }
            }
        }
        .padding()
        .background(WarmCardBackground())
    }
    
    private var fileSelectionSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Select File")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.title2)
                        .foregroundColor(ShelvesDesign.Colors.primary)
                    
                    VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                        Text(selectedFileURL?.lastPathComponent ?? "Choose File")
                            .font(ShelvesDesign.Typography.labelLarge)
                            .foregroundColor(ShelvesDesign.Colors.text)
                        
                        Text("Tap to browse for \(selectedFormat.rawValue) files")
                            .font(ShelvesDesign.Typography.bodySmall)
                            .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
                        .fill(selectedFileURL != nil ? ShelvesDesign.Colors.primary.opacity(0.1) : Color.clear)
                        .stroke(ShelvesDesign.Colors.primary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(WarmCardBackground())
    }
    
    private func previewSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("File Preview")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.sm) {
                HStack {
                    Text("File Name:")
                        .font(ShelvesDesign.Typography.labelMedium)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    
                    Text(url.lastPathComponent)
                        .font(ShelvesDesign.Typography.bodyMedium)
                        .foregroundColor(ShelvesDesign.Colors.text)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if let fileSize = getFileSize(url: url) {
                    HStack {
                        Text("File Size:")
                            .font(ShelvesDesign.Typography.labelMedium)
                            .foregroundColor(ShelvesDesign.Colors.textSecondary)
                        
                        Text(fileSize)
                            .font(ShelvesDesign.Typography.bodyMedium)
                            .foregroundColor(ShelvesDesign.Colors.text)
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, ShelvesDesign.Spacing.sm)
            .padding(.horizontal, ShelvesDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.small)
                    .fill(ShelvesDesign.Colors.surface.opacity(0.5))
            )
        }
        .padding()
        .background(WarmCardBackground())
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Import Instructions")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.sm) {
                ForEach(getInstructionsForFormat(), id: \.self) { instruction in
                    HStack(alignment: .top, spacing: ShelvesDesign.Spacing.sm) {
                        Text("•")
                            .font(ShelvesDesign.Typography.bodyMedium)
                            .foregroundColor(ShelvesDesign.Colors.primary)
                        
                        Text(instruction)
                            .font(ShelvesDesign.Typography.bodyMedium)
                            .foregroundColor(ShelvesDesign.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding()
        .background(WarmCardBackground())
    }
    
    private func getInstructionsForFormat() -> [String] {
        switch selectedFormat {
        case .csv:
            return [
                "First row should contain column headers",
                "Required column: 'Title' or 'Book Title'",
                "Optional columns: Author, ISBN, Library, Genre, Pages, Rating, Notes",
                "Use quotes around values containing commas",
                "Duplicates will be automatically detected and skipped"
            ]
        case .json:
            return [
                "Must be a valid JSON file",
                "Should contain an array of book objects",
                "Each book must have at least a 'title' field",
                "Supports nested structures with 'books' array",
                "Existing Shelves export files are supported"
            ]
        case .txt:
            return [
                "One book per line",
                "Format: 'Title by Author' or just 'Title'",
                "Simple text format for basic imports",
                "Additional details can be added later"
            ]
        }
    }
    
    private func getFileSize(url: URL) -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            // Error getting file size
        }
        return nil
    }
    
    private func startImport() {
        guard let fileURL = selectedFileURL else { return }
        
        isImporting = true
        
        Task {
            let result = await DataImportService.shared.importBooks(
                from: fileURL,
                format: selectedFormat,
                context: viewContext
            )
            
            await MainActor.run {
                self.isImporting = false
                self.importResult = result
                self.showingImportResult = true
            }
        }
    }
}

struct FormatOption: View {
    let format: ImportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(format.rawValue)
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
                    Text(format.description)
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                }
                
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

struct ImportingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(ShelvesDesign.Colors.primary)
                
                Text("Importing Books...")
                    .font(ShelvesDesign.Typography.headlineMedium)
                    .foregroundColor(.white)
                
                Text("Please wait while we process your file")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(ShelvesDesign.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.large)
                    .fill(.ultraThinMaterial)
            )
            .padding(ShelvesDesign.Spacing.xl)
        }
    }
}

struct ImportResultView: View {
    let result: ImportResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    ScrollView {
                        VStack(spacing: ShelvesDesign.Spacing.lg) {
                            resultSummarySection
                            
                            if !result.errors.isEmpty {
                                errorsSection
                            }
                            
                            if !result.importedBooks.isEmpty {
                                previewSection
                            }
                        }
                        .padding(ShelvesDesign.Spacing.md)
                        .padding(.bottom, ShelvesDesign.Spacing.xl)
                    }
                )
                .navigationTitle("Import Results")
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
    
    private var resultSummarySection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            HStack {
                Image(systemName: result.successCount > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(result.successCount > 0 ? .green : .orange)
                
                Text("Import Complete")
                    .font(ShelvesDesign.Typography.headlineLarge)
                    .foregroundColor(ShelvesDesign.Colors.text)
                
                Spacer()
            }
            
            VStack(spacing: ShelvesDesign.Spacing.sm) {
                StatRow(label: "Successfully Imported", value: "\(result.successCount)", color: .green)
                
                if result.duplicateCount > 0 {
                    StatRow(label: "Duplicates Skipped", value: "\(result.duplicateCount)", color: .orange)
                }
                
                if result.failedCount > 0 {
                    StatRow(label: "Failed to Import", value: "\(result.failedCount)", color: .red)
                }
            }
        }
        .padding()
        .background(WarmCardBackground())
    }
    
    private var errorsSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Errors")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.sm) {
                ForEach(Array(result.errors.prefix(5).enumerated()), id: \.offset) { index, error in
                    HStack(alignment: .top, spacing: ShelvesDesign.Spacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text(error)
                            .font(ShelvesDesign.Typography.bodySmall)
                            .foregroundColor(ShelvesDesign.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                if result.errors.count > 5 {
                    Text("... and \(result.errors.count - 5) more errors")
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(WarmCardBackground())
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Sample Imported Books")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            VStack(spacing: ShelvesDesign.Spacing.sm) {
                ForEach(Array(result.importedBooks.prefix(3).enumerated()), id: \.offset) { index, book in
                    HStack(alignment: .top, spacing: ShelvesDesign.Spacing.md) {
                        Image(systemName: "book.fill")
                            .foregroundColor(ShelvesDesign.Colors.primary)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                            Text(book.title)
                                .font(ShelvesDesign.Typography.labelLarge)
                                .foregroundColor(ShelvesDesign.Colors.text)
                                .lineLimit(2)
                            
                            if let author = book.author {
                                Text("by \(author)")
                                    .font(ShelvesDesign.Typography.bodySmall)
                                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, ShelvesDesign.Spacing.sm)
                    
                    if index < 2 && result.importedBooks.count > index + 1 {
                        Divider()
                            .background(ShelvesDesign.Colors.textSecondary.opacity(0.2))
                    }
                }
                
                if result.importedBooks.count > 3 {
                    Text("... and \(result.importedBooks.count - 3) more books")
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                        .italic()
                        .padding(.top, ShelvesDesign.Spacing.sm)
                }
            }
        }
        .padding()
        .background(WarmCardBackground())
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(ShelvesDesign.Typography.labelMedium)
                .foregroundColor(ShelvesDesign.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(ShelvesDesign.Typography.labelLarge)
                .foregroundColor(color)
        }
    }
}

#Preview {
    BulkImportView()
        .environmentObject(ThemeManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}