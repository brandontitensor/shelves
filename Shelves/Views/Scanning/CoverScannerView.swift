import SwiftUI
#if canImport(UIKit) && canImport(AVFoundation)
import UIKit
import AVFoundation
import Vision

struct CoverScannerView: View {
    @Binding var searchResults: [BookSearchResult]?
    @Binding var isPresented: Bool
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    @State private var isProcessing = false
    @State private var extractedText: String?
    @State private var errorMessage: String?
    @AppStorage("hasSeenCoverScannerTutorial") private var hasSeenTutorial = false
    @State private var showingTutorial = false

    var body: some View {
        ZStack {
            if permissionDenied {
                permissionDeniedView
            } else {
                // Camera view
                CoverScannerViewControllerRepresentable(
                    isProcessing: $isProcessing,
                    extractedText: $extractedText,
                    searchResults: $searchResults,
                    errorMessage: $errorMessage,
                    isPresented: $isPresented
                )
                .ignoresSafeArea()

                // Overlay UI
                if !isProcessing && !showingTutorial {
                    overlayUI
                }

                // Processing overlay
                if isProcessing {
                    processingOverlay
                }

                // Error overlay
                if let error = errorMessage {
                    errorOverlay(message: error)
                }

                // Tutorial overlay
                if showingTutorial {
                    tutorialOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingTutorial)
                }
            }
        }
        .background(Color.black)
        .onAppear {
            checkCameraPermission()
            // Show tutorial automatically on first use
            if !hasSeenTutorial && !permissionDenied {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingTutorial = true
                }
            }
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel") {
                isPresented = false
            }
        } message: {
            Text("Please allow camera access in Settings to scan book covers.")
        }
    }

    private var overlayUI: some View {
        VStack {
            // Top bar
            HStack {
                // Help button on the left
                Button(action: {
                    showingTutorial = true
                }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)

                Spacer()

                // Cancel button on the right
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
            .padding()

            Spacer()

            // Scanning frame (larger for covers)
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 300, height: 400)
                .overlay(
                    VStack {
                        Spacer()
                        Text("Position book cover or spine within frame")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .offset(y: 220)
                )

            Spacer()

            // Instructions and capture button
            VStack(spacing: 16) {
                Text("Position the book title clearly in the frame")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .padding(.horizontal)

                // Capture button
                Button(action: {
                    triggerCapture()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                        Text("Capture")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                    .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.bottom, 40)
        }
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                VStack(spacing: 12) {
                    Text(processingMessage)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    if let text = extractedText {
                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineLimit(3)
                    }
                }
            }
            .padding(40)
        }
    }

    private var processingMessage: String {
        if extractedText == nil {
            return "Extracting text..."
        } else {
            return "Searching for book..."
        }
    }

    private func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Error icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }

                // Error message
                VStack(spacing: 12) {
                    Text("Scan Failed")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(message)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Extracted text if available
                if let text = extractedText, !text.isEmpty {
                    VStack(spacing: 8) {
                        Text("Detected text:")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineLimit(3)
                    }
                    .padding(.top, 8)
                }

                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Try again - reset error and extracted text
                        errorMessage = nil
                        extractedText = nil
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text("Try Again")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                    .padding(.horizontal, 32)

                    Button(action: {
                        // Enter manually - dismiss scanner so user can use "Add Manually" button
                        isPresented = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16))
                            Text("Enter Manually")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 32)

                    Button(action: {
                        // Cancel - dismiss scanner
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private var tutorialOverlay: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }

                        Text("How to Scan Covers")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Follow these tips for the best results")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 24) {
                        CoverTutorialStep(
                            icon: "book.closed.fill",
                            title: "Position the Book",
                            description: "Place the book cover or spine within the frame. Make sure the title is clearly visible and well-lit."
                        )

                        CoverTutorialStep(
                            icon: "camera.fill",
                            title: "Tap Capture",
                            description: "When the title is positioned correctly, tap the blue Capture button. The app will extract the text and search for your book."
                        )

                        CoverTutorialStep(
                            icon: "square.text.square",
                            title: "ISBN First",
                            description: "If an ISBN is visible on the cover, it will be used first for the most accurate results. Otherwise, the title and author will be extracted."
                        )

                        CoverTutorialStep(
                            icon: "lightbulb.fill",
                            title: "Best Results",
                            description: "Use good lighting, keep the camera steady, and ensure the title text is in focus. You'll see a list of matching books to choose from."
                        )
                    }
                    .padding(.horizontal)

                    // Got It button
                    Button(action: {
                        showingTutorial = false
                        hasSeenTutorial = true
                    }) {
                        Text("Got It!")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
                .padding(.vertical, 40)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("To scan book covers, please allow camera access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(.gray)
        }
        .padding()
    }

    private func triggerCapture() {
        NotificationCenter.default.post(name: .captureBookCover, object: nil)
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            permissionDenied = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        permissionDenied = true
                    }
                }
            }
        case .authorized:
            permissionDenied = false
        @unknown default:
            permissionDenied = true
        }
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let captureBookCover = Notification.Name("captureBookCover")
}

// MARK: - UIViewController Representable

struct CoverScannerViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var isProcessing: Bool
    @Binding var extractedText: String?
    @Binding var searchResults: [BookSearchResult]?
    @Binding var errorMessage: String?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> CoverScannerViewController {
        let controller = CoverScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CoverScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CoverScannerDelegate {
        let parent: CoverScannerViewControllerRepresentable

        init(_ parent: CoverScannerViewControllerRepresentable) {
            self.parent = parent
        }

        func didStartProcessing() {
            DispatchQueue.main.async {
                self.parent.isProcessing = true
            }
        }

        func didExtractText(_ text: String) {
            DispatchQueue.main.async {
                self.parent.extractedText = text
            }
        }

        func didFindResults(_ results: [BookSearchResult]) {
            DispatchQueue.main.async {
                self.parent.searchResults = results
                self.parent.isProcessing = false

                // Dismiss scanner after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.parent.isPresented = false
                }
            }
        }

        func didFailWithError(_ error: String) {
            DispatchQueue.main.async {
                self.parent.errorMessage = error
                self.parent.isProcessing = false
            }
        }
    }
}

// MARK: - Cover Scanner Delegate Protocol

protocol CoverScannerDelegate: AnyObject {
    func didStartProcessing()
    func didExtractText(_ text: String)
    func didFindResults(_ results: [BookSearchResult])
    func didFailWithError(_ error: String)
}

// MARK: - Cover Scanner View Controller

class CoverScannerViewController: UIViewController {
    weak var delegate: CoverScannerDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoCaptureDevice: AVCaptureDevice?
    private var videoOutput: AVCaptureVideoDataOutput!
    private var captureRequested = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        setupCamera()
        setupCaptureNotification()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let session = captureSession {
            if session.isRunning {
                session.stopRunning()
            }
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }
        }
        delegate = nil
    }

    private func setupCaptureNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCaptureRequest),
            name: .captureBookCover,
            object: nil
        )
    }

    @objc private func handleCaptureRequest() {
        print("📸 [CoverScanner] Capture requested")
        captureRequested = true
    }

    private func setupCamera() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            print("❌ [CoverScanner] Camera not authorized")
            return
        }

        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()

        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ?? AVCaptureDevice.default(for: .video) else {
            print("❌ [CoverScanner] Camera not available")
            captureSession.commitConfiguration()
            return
        }

        self.videoCaptureDevice = device

        // Configure device
        do {
            try device.lockForConfiguration()

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            device.unlockForConfiguration()
        } catch {
            print("⚠️ [CoverScanner] Could not configure camera: \(error)")
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch {
            print("❌ [CoverScanner] Error creating video input: \(error)")
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "coverScanQueue"))

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    private func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func stopSession() {
        guard let session = captureSession, session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }

    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        print("📸 [CoverScanner] Processing frame for text")

        delegate?.didStartProcessing()

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ [CoverScanner] Text recognition error: \(error)")
                self.delegate?.didFailWithError("Failed to read text from image")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.delegate?.didFailWithError("No text found on cover")
                return
            }

            print("📸 [CoverScanner] Found \(observations.count) text observations (before filtering)")

            // Filter observations to only include text within the scanning frame
            // The frame overlay is 300x400 centered on screen
            // Convert to normalized coordinates (0-1, with 0,0 at bottom-left)
            let filteredObservations = self.filterObservationsInScanningFrame(observations)
            print("📸 [CoverScanner] Found \(filteredObservations.count) text observations inside scanning frame")

            // Extract all text for ISBN detection
            let allText = filteredObservations.compactMap { observation -> String? in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")

            // PRIORITY 1: Try to find and use ISBN first
            if let isbn = self.extractISBN(from: allText) {
                print("📚 [CoverScanner] Found ISBN on cover: \(isbn)")
                self.delegate?.didExtractText("ISBN: \(isbn)")

                // Try ISBN lookup
                Task {
                    do {
                        let bookData = try await OpenLibraryService.shared.fetchBookData(isbn: isbn)
                        // Convert to search result format
                        let result = BookSearchResult(
                            title: bookData.title,
                            author: bookData.author,
                            isbn: isbn,
                            coverURL: bookData.coverImageURL,
                            publishYear: bookData.publishedDate,
                            matchScore: 1.0  // Perfect match via ISBN
                        )
                        self.delegate?.didFindResults([result])
                    } catch {
                        print("⚠️ [CoverScanner] ISBN lookup failed: \(error.localizedDescription)")
                        print("📖 [CoverScanner] Falling back to title/author search")
                        // Fall back to title/author parsing
                        self.searchByTitleAuthor(observations: filteredObservations)
                    }
                }
                return  // Exit early - wait for ISBN lookup or fallback
            }

            // PRIORITY 2: No ISBN found, use title/author parsing
            self.searchByTitleAuthor(observations: filteredObservations)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("❌ [CoverScanner] Failed to perform text detection: \(error)")
            delegate?.didFailWithError("Failed to process image")
        }
    }

    private func extractISBN(from text: String) -> String? {
        print("📚 [ISBN] Searching for ISBN in text: \(text.prefix(100))")

        // Pattern to find ISBN-like sequences (with common OCR errors)
        // Matches: ISBN digits with separators, or standalone digit sequences
        let isbnPattern = "(?:ISBN[:\\s-]?)?([0-9IlO:]{10,17}[Xx]?)"

        guard let regex = try? NSRegularExpression(pattern: isbnPattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        print("📚 [ISBN] Found \(matches.count) potential ISBN patterns")

        for match in matches {
            guard let matchRange = Range(match.range(at: 1), in: text) else { continue }
            let candidate = String(text[matchRange])

            print("📚 [ISBN] Testing candidate: '\(candidate)'")

            // Clean and correct common OCR errors
            let corrected = correctOCRErrors(candidate)
            print("📚 [ISBN] After OCR correction: '\(corrected)'")

            // Remove all separators
            let digitsOnly = corrected.filter { $0.isNumber || $0.uppercased() == "X" }
            print("📚 [ISBN] Digits only: '\(digitsOnly)'")

            // Try to validate as ISBN-13
            if digitsOnly.count == 13 {
                if ISBNValidator.isValidISBN13(digitsOnly) {
                    print("✅ [ISBN] Valid ISBN-13 found: \(digitsOnly)")
                    return digitsOnly
                } else {
                    print("❌ [ISBN] Invalid ISBN-13 checksum: \(digitsOnly)")
                }
            }

            // Try to validate as ISBN-10
            if digitsOnly.count == 10 {
                if ISBNValidator.isValidISBN10(digitsOnly) {
                    print("✅ [ISBN] Valid ISBN-10 found: \(digitsOnly)")
                    return digitsOnly
                } else {
                    print("❌ [ISBN] Invalid ISBN-10 checksum: \(digitsOnly)")
                }
            }
        }

        print("📚 [ISBN] No valid ISBN found in text")
        return nil
    }

    /// Correct common OCR errors in potential ISBN strings
    private func correctOCRErrors(_ text: String) -> String {
        var corrected = text

        // Common OCR mistakes
        corrected = corrected.replacingOccurrences(of: ":", with: "8")  // Colon → 8
        corrected = corrected.replacingOccurrences(of: "l", with: "1")  // lowercase L → 1
        corrected = corrected.replacingOccurrences(of: "I", with: "1")  // uppercase I → 1
        corrected = corrected.replacingOccurrences(of: "O", with: "0")  // uppercase O → 0
        corrected = corrected.replacingOccurrences(of: "o", with: "0")  // lowercase o → 0

        return corrected
    }

    /// Filters text observations to only include those within the scanning frame overlay
    private func filterObservationsInScanningFrame(_ observations: [VNRecognizedTextObservation]) -> [VNRecognizedTextObservation] {
        // Define the region of interest (ROI) in normalized coordinates
        // Vision coordinates: (0,0) = bottom-left, (1,1) = top-right
        // The scanning frame is roughly the center 60% of the image
        let roiMinX: CGFloat = 0.15  // 15% from left
        let roiMaxX: CGFloat = 0.85  // 85% from left
        let roiMinY: CGFloat = 0.20  // 20% from bottom
        let roiMaxY: CGFloat = 0.85  // 85% from bottom

        return observations.filter { observation in
            let bounds = observation.boundingBox
            let centerX = bounds.midX
            let centerY = bounds.midY

            let isInside = centerX >= roiMinX && centerX <= roiMaxX &&
                          centerY >= roiMinY && centerY <= roiMaxY

            if !isInside {
                if let text = observation.topCandidates(1).first?.string {
                    print("📸 [CoverScanner] Filtering out text outside frame: '\(text)' at (\(String(format: "%.2f", centerX)), \(String(format: "%.2f", centerY)))")
                }
            }

            return isInside
        }
    }

    private func searchByTitleAuthor(observations: [VNRecognizedTextObservation]) {
        // Parse the text to extract title/author
        let parser = BookCoverParser()
        let candidates = parser.parseTextObservations(observations)

        guard !candidates.isEmpty else {
            self.delegate?.didFailWithError("Could not identify book title")
            return
        }

        let bestCandidate = candidates.first!
        let displayText = bestCandidate.author != nil
            ? "\(bestCandidate.title) by \(bestCandidate.author!)"
            : bestCandidate.title

        self.delegate?.didExtractText(displayText)

        // Search Open Library with fallback strategies
        Task {
            var allResults: [BookSearchResult] = []

            // Try all candidates in order of confidence
            for candidate in candidates {
                do {
                    let results = try await OpenLibraryService.shared.searchByTitleAuthor(
                        title: candidate.title,
                        author: candidate.author
                    )

                    if !results.isEmpty {
                        print("✅ [CoverScanner] Found \(results.count) results for '\(candidate.title)' by '\(candidate.author ?? "any")'")
                        allResults.append(contentsOf: results)
                        break  // Stop on first successful search
                    } else {
                        print("⚠️ [CoverScanner] No results for '\(candidate.title)' by '\(candidate.author ?? "any")', trying next candidate...")
                    }
                } catch {
                    print("⚠️ [CoverScanner] Search error for '\(candidate.title)': \(error.localizedDescription)")
                }
            }

            if allResults.isEmpty {
                self.delegate?.didFailWithError("No books found matching any extracted titles")
            } else {
                self.delegate?.didFindResults(allResults)
            }
        }
    }
}

extension CoverScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard captureRequested else { return }
        captureRequested = false  // Process only once

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Stop the session while processing
        stopSession()

        // Process the frame
        processFrame(pixelBuffer)
    }
}

// MARK: - Cover Tutorial Step Helper

struct CoverTutorialStep: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#endif
