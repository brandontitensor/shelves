import SwiftUI
#if canImport(UIKit) && canImport(AVFoundation)
import UIKit
import AVFoundation

enum ScannerMode {
    case barcode
    case text
}

struct BarcodeScannerView: View {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    @State private var scannerMode: ScannerMode = .barcode
    @State private var isLoading = false
    @State private var detectedISBN: String?
    
    var body: some View {
        ZStack {
            if permissionDenied {
                permissionDeniedView
            } else {
                scannerView

                // Only show overlay UI when not loading
                if !isLoading {
                    overlayUI
                }

                // Loading overlay with animation
                if isLoading {
                    loadingOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLoading)
                }
            }
        }
        .background(Color.black)
        .onAppear {
            checkCameraPermission()
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
            Text("Please allow camera access in Settings to scan barcodes.")
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Success checkmark animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.green)
                }
                .transition(.scale.combined(with: .opacity))

                VStack(spacing: 12) {
                    Text("ISBN Detected")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    if let isbn = detectedISBN {
                        Text(isbn)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    Text("Looking up book information...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.15))
            )
            .padding(40)
        }
        .transition(.opacity)
    }

    private var scannerView: some View {
        Group {
            if scannerMode == .barcode {
                ScannerViewControllerRepresentable(
                    scannedCode: $scannedCode,
                    isPresented: $isPresented,
                    isLoading: $isLoading,
                    detectedISBN: $detectedISBN
                )
                .ignoresSafeArea()
            } else {
                ISBNTextScannerViewControllerRepresentable(
                    scannedISBN: $scannedCode,
                    isPresented: $isPresented,
                    isLoading: $isLoading,
                    detectedISBN: $detectedISBN
                )
                .ignoresSafeArea()
            }
        }
    }

    private var overlayUI: some View {
        VStack {
            topBar
            Spacer()
            scanningFrame
            Spacer()
            bottomInstructions
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }

            modeSelector
        }
        .padding()
    }

    private var modeSelector: some View {
        HStack(spacing: 0) {
            modeSelectorButton(mode: .barcode, icon: "barcode.viewfinder", title: "Barcode")
            modeSelectorButton(mode: .text, icon: "text.viewfinder", title: "ISBN Text")
        }
        .padding(4)
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
    }

    private func modeSelectorButton(mode: ScannerMode, icon: String, title: String) -> some View {
        Button(action: {
            scannerMode = mode
        }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(scannerMode == mode ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(scannerMode == mode ? Color.white : Color.clear)
            .cornerRadius(8)
        }
    }

    private var scanningFrame: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white, lineWidth: 3)
            .frame(width: 250, height: 150)
            .overlay(
                VStack {
                    Spacer()
                    Text(scannerMode == .barcode ? "Position barcode within frame" : "Position ISBN text within frame")
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                }
                .offset(y: 80)
            )
    }

    private var bottomInstructions: some View {
        VStack(spacing: 8) {
            Text(instructionText)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .font(.system(size: 15))

            if scannerMode == .text {
                Text("Tip: Tap on the ISBN to focus")
                    .foregroundColor(.yellow)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .padding()
    }

    private var instructionText: String {
        scannerMode == .barcode
            ? "Point your camera at the barcode on the back of your book"
            : "Point your camera at the ISBN text (usually found above or below the barcode)"
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To scan barcodes, please allow camera access in Settings.")
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

struct ScannerViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool
    @Binding var isLoading: Bool
    @Binding var detectedISBN: String?

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let controller = BarcodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BarcodeScannerDelegate {
        let parent: ScannerViewControllerRepresentable

        init(_ parent: ScannerViewControllerRepresentable) {
            self.parent = parent
        }

        func didScanBarcode(_ code: String) {
            DispatchQueue.main.async {
                // Show loading state immediately
                self.parent.isLoading = true
                self.parent.detectedISBN = code

                // Delay slightly to show the loading animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.parent.scannedCode = code

                    // Keep loading state and dismiss after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.parent.isPresented = false
                        // Reset loading state after dismissal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.parent.isLoading = false
                            self.parent.detectedISBN = nil
                        }
                    }
                }
            }
        }

        func didFailWithError(_ error: Error) {
            DispatchQueue.main.async {
                print("Scanner error: \(error.localizedDescription)")
                // Don't close on error, let user try again
            }
        }
    }
}

protocol BarcodeScannerDelegate: AnyObject {
    func didScanBarcode(_ code: String)
    func didFailWithError(_ error: Error)
}

class BarcodeScannerViewController: UIViewController {
    weak var delegate: BarcodeScannerDelegate?
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var hasScanned = false
    private let scanLock = NSLock()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scanLock.lock()
        hasScanned = false
        scanLock.unlock()
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    deinit {
        // Ensure capture session is fully stopped and cleaned up
        if let session = captureSession {
            if session.isRunning {
                session.stopRunning()
            }
            // Remove all inputs and outputs
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }
        }
        delegate = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
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
    
    private func setupCamera() {
        // Check camera permissions first
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            print("Camera not authorized")
            return
        }
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error creating video input: \(error)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Could not add video input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // Support multiple barcode types common on books
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .code128, .code39, .code93, .upce
            ]
        } else {
            print("Could not add metadata output")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
}

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Prevent multiple scans with thread-safe check
        scanLock.lock()
        let alreadyScanned = hasScanned
        scanLock.unlock()

        guard !alreadyScanned else { return }

        // Collect all detected barcodes
        var detectedCodes: [(code: String, type: AVMetadataObject.ObjectType)] = []

        for metadataObject in metadataObjects {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { continue }
            guard let stringValue = readableObject.stringValue else { continue }
            detectedCodes.append((code: stringValue, type: readableObject.type))
        }

        guard !detectedCodes.isEmpty else { return }

        // Categorize barcodes by type and validity
        var bookISBN13Codes: [(String, AVMetadataObject.ObjectType)] = []  // 978/979 prefix ISBNs
        var isbn10Codes: [(String, AVMetadataObject.ObjectType)] = []
        var otherISBNCodes: [(String, AVMetadataObject.ObjectType)] = []
        var nonISBNCodes: [(String, AVMetadataObject.ObjectType)] = []

        for detected in detectedCodes {
            let normalized = ISBNValidator.normalize(detected.code)

            // Check if it's a book ISBN-13 (978/979 prefix) - HIGHEST PRIORITY
            if ISBNValidator.isBookISBN13(normalized) {
                bookISBN13Codes.append((detected.code, detected.type))
            }
            // Check if it's a valid ISBN-10
            else if ISBNValidator.isValidISBN10(normalized) {
                isbn10Codes.append((detected.code, detected.type))
            }
            // Check if it's any other valid ISBN-13 (might be non-book)
            else if ISBNValidator.isValidISBN13(normalized) {
                otherISBNCodes.append((detected.code, detected.type))
            }
            // Not an ISBN at all
            else {
                nonISBNCodes.append((detected.code, detected.type))
            }
        }

        // Choose the best barcode with strict prioritization:
        // 1. Book ISBN-13 with 978/979 prefix from EAN-13 barcode (MOST RELIABLE)
        // 2. Book ISBN-13 with 978/979 prefix from any barcode type
        // 3. Valid ISBN-10 from any barcode type
        // 4. Other valid ISBN-13 (non-book prefix, could be false positive)
        // 5. Fall back to any barcode
        var selectedCode: String?

        // Priority 1: Book ISBN-13 from EAN-13 barcode type
        if let bookISBN = bookISBN13Codes.first(where: { $0.1 == .ean13 }) {
            selectedCode = bookISBN.0
        }
        // Priority 2: Any book ISBN-13
        else if let bookISBN = bookISBN13Codes.first {
            selectedCode = bookISBN.0
        }
        // Priority 3: ISBN-10
        else if let isbn10 = isbn10Codes.first {
            selectedCode = isbn10.0
        }
        // Priority 4: Other ISBN-13 (could be UPC that passed checksum)
        else if let otherISBN = otherISBNCodes.first {
            selectedCode = otherISBN.0
        }
        // Priority 5: Any barcode as fallback
        else if let fallback = nonISBNCodes.first {
            selectedCode = fallback.0
        }

        guard let finalCode = selectedCode else { return }

        // Mark as scanned and stop session
        scanLock.lock()
        hasScanned = true
        scanLock.unlock()

        stopSession()

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Small delay to ensure user sees the scan happened
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.delegate?.didScanBarcode(finalCode)
        }
    }
}
#endif