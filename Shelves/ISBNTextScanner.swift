import SwiftUI
#if canImport(UIKit) && canImport(AVFoundation)
import UIKit
import AVFoundation
import Vision

/// Protocol for ISBN text scanner delegate
protocol ISBNTextScannerDelegate: AnyObject {
    func didDetectISBN(_ isbn: String)
    func didFailWithError(_ error: Error)
}

/// View controller that uses Vision framework to detect and extract ISBN from camera feed
class ISBNTextScannerViewController: UIViewController {
    weak var delegate: ISBNTextScannerDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var hasScannedISBN = false
    private let scanLock = NSLock()

    // Frame throttling to prevent overwhelming the camera service
    private var isProcessingFrame = false
    private var lastProcessedTime: Date = .distantPast
    private let minimumFrameInterval: TimeInterval = 0.2 // Process max 5 frames per second

    // Store video device for tap-to-focus
    private var videoCaptureDevice: AVCaptureDevice?

    // Vision request
    private lazy var textDetectionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: handleDetectedText)
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]
        return request
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        setupCamera()
        setupTapToFocus()
    }

    private func setupTapToFocus() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapToFocus(_ gesture: UITapGestureRecognizer) {
        guard let device = videoCaptureDevice else { return }

        let touchPoint = gesture.location(in: view)
        let focusPoint = CGPoint(
            x: touchPoint.y / view.bounds.height,
            y: 1.0 - (touchPoint.x / view.bounds.width)
        )

        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint

                // First try locked focus at current lens position if supported
                if device.isFocusModeSupported(.locked) {
                    // Reset to continuous first to ensure we can refocus
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                }

                // Then trigger autofocus
                if device.isFocusModeSupported(.autoFocus) {
                    device.focusMode = .autoFocus
                    print("📍 [ISBN Scanner] Focusing at point: \(focusPoint)")
                }
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint

                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                } else if device.isExposureModeSupported(.autoExpose) {
                    device.exposureMode = .autoExpose
                }
            }

            device.unlockForConfiguration()

            // Show focus indicator
            showFocusIndicator(at: touchPoint)

            // Re-enable continuous autofocus after a delay to maintain focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetToContinuousFocus()
            }
        } catch {
            print("⚠️ [ISBN Scanner] Could not focus: \(error)")
        }
    }

    private func resetToContinuousFocus() {
        guard let device = videoCaptureDevice else { return }

        do {
            try device.lockForConfiguration()

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
                print("🔄 [ISBN Scanner] Reset to continuous autofocus")
            }

            device.unlockForConfiguration()
        } catch {
            print("⚠️ [ISBN Scanner] Could not reset focus: \(error)")
        }
    }

    private func showFocusIndicator(at point: CGPoint) {
        let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusView.center = point
        focusView.backgroundColor = .clear
        focusView.layer.borderColor = UIColor.systemYellow.cgColor
        focusView.layer.borderWidth = 2
        focusView.layer.cornerRadius = 40
        focusView.alpha = 0

        view.addSubview(focusView)

        UIView.animate(withDuration: 0.2, animations: {
            focusView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5, animations: {
                focusView.alpha = 0
            }) { _ in
                focusView.removeFromSuperview()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("\n🚀 [ISBN Scanner] Starting new ISBN text scanning session")

        scanLock.lock()
        hasScannedISBN = false
        scanLock.unlock()

        // Reset throttling state
        isProcessingFrame = false
        lastProcessedTime = .distantPast

        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    deinit {
        if let session = captureSession {
            if session.isRunning {
                session.stopRunning()
            }
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
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            print("Camera not authorized")
            return
        }

        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()

        // Use high preset for better text recognition (with throttled processing to prevent crashes)
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
            print("📷 [ISBN Scanner] Set camera preset to .high")
        } else {
            captureSession.sessionPreset = .medium
            print("📷 [ISBN Scanner] Fallback to .medium preset")
        }

        // Try to get the best camera for close-up work
        let device: AVCaptureDevice
        if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            device = dualCamera
            print("📷 [ISBN Scanner] Using dual camera")
        } else if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            device = wideCamera
            print("📷 [ISBN Scanner] Using wide angle camera")
        } else if let defaultCamera = AVCaptureDevice.default(for: .video) {
            device = defaultCamera
            print("📷 [ISBN Scanner] Using default camera")
        } else {
            print("❌ [ISBN Scanner] Camera not available")
            captureSession.commitConfiguration()
            return
        }

        // Store device reference for tap-to-focus
        self.videoCaptureDevice = device

        // Configure camera for close-up text scanning
        do {
            try device.lockForConfiguration()

            // Enable continuous autofocus for better close-up performance
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
                print("📷 [ISBN Scanner] Enabled continuous autofocus")
            }

            // Enable auto-exposure for varying lighting conditions
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
                print("📷 [ISBN Scanner] Enabled continuous auto-exposure")
            }

            // Enable auto white balance
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
                print("📷 [ISBN Scanner] Enabled auto white balance")
            }

            // Set focus point of interest to center (where scanning frame is)
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                print("📷 [ISBN Scanner] Set focus point to center")
            }

            device.unlockForConfiguration()
        } catch {
            print("⚠️ [ISBN Scanner] Could not configure camera focus: \(error)")
        }

        captureSession.commitConfiguration()

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: device)
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

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Could not add video output")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    private func handleDetectedText(request: VNRequest, error: Error?) {
        if let error = error {
            print("❌ [ISBN Scanner] Error detecting text: \(error)")
            return
        }

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            print("⚠️ [ISBN Scanner] No text observations found")
            return
        }

        print("📸 [ISBN Scanner] Processing \(observations.count) text observations")

        // Collect all detected text with context
        var allDetectedText: [String] = []
        var highConfidenceTexts: [(text: String, confidence: Float)] = []

        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string
            let confidence = topCandidate.confidence

            allDetectedText.append(text)
            print("   📝 Detected: '\(text)' (confidence: \(String(format: "%.2f", confidence)))")

            // Only process high-confidence text for ISBN extraction
            if confidence >= 0.5 {
                highConfidenceTexts.append((text: text, confidence: confidence))
            } else {
                print("      ⏭️ [ISBN Scanner] Skipping low confidence text")
            }
        }

        // Check if "ISBN" appears anywhere in the detected text for context
        let hasISBNContext = allDetectedText.contains { $0.uppercased().contains("ISBN") }
        print("   📖 [ISBN Scanner] ISBN context found: \(hasISBNContext)")

        // If no ISBN context found at all, skip processing to avoid false positives
        if !hasISBNContext {
            print("   ⚠️ [ISBN Scanner] No ISBN context in frame, skipping to avoid false positives")
            return
        }

        // Process high-confidence text
        for item in highConfidenceTexts {
            let text = item.text
            let confidence = item.confidence

            // Try to extract ISBN from the detected text
            // We have ISBN context, so we can be more lenient (requireISBNPrefix: false)
            if let isbn = ISBNValidator.extractISBN(from: text, requireISBNPrefix: false) {
                print("✅ [ISBN Scanner] Found ISBN: \(isbn) from text: '\(text)'")

                // Prevent multiple detections
                scanLock.lock()
                let alreadyScanned = hasScannedISBN
                if !alreadyScanned {
                    hasScannedISBN = true
                }
                scanLock.unlock()

                guard !alreadyScanned else {
                    print("⚠️ [ISBN Scanner] Already scanned, ignoring")
                    return
                }

                stopSession()
                print("🎯 [ISBN Scanner] Accepting ISBN: \(isbn)")

                // Provide haptic feedback
                DispatchQueue.main.async {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()

                    // Small delay to ensure user sees the detection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.delegate?.didDetectISBN(isbn)
                    }
                }

                return
            } else {
                print("   ❌ No valid ISBN in: '\(text)'")
            }
        }

        if highConfidenceTexts.isEmpty {
            print("⚠️ [ISBN Scanner] No high-confidence text in this frame")
        }
    }
}

extension ISBNTextScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Don't process if already scanned
        scanLock.lock()
        let alreadyScanned = hasScannedISBN
        scanLock.unlock()

        guard !alreadyScanned else { return }

        // Frame throttling: Skip if already processing or too soon since last frame
        guard !isProcessingFrame else {
            // Silently skip - already processing previous frame
            return
        }

        let now = Date()
        let timeSinceLastFrame = now.timeIntervalSince(lastProcessedTime)
        guard timeSinceLastFrame >= minimumFrameInterval else {
            // Silently skip - too soon since last frame
            return
        }

        // Mark as processing
        isProcessingFrame = true
        lastProcessedTime = now

        print("🎥 [ISBN Scanner] Processing new frame (last frame: \(String(format: "%.2f", timeSinceLastFrame))s ago)")

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        do {
            try imageRequestHandler.perform([textDetectionRequest])
        } catch {
            print("❌ [ISBN Scanner] Failed to perform text detection: \(error)")
        }

        // Reset processing flag
        isProcessingFrame = false
    }
}

/// SwiftUI wrapper for ISBNTextScannerViewController
struct ISBNTextScannerViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedISBN: String?
    @Binding var isPresented: Bool
    @Binding var isLoading: Bool
    @Binding var detectedISBN: String?

    func makeUIViewController(context: Context) -> ISBNTextScannerViewController {
        let controller = ISBNTextScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ISBNTextScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ISBNTextScannerDelegate {
        let parent: ISBNTextScannerViewControllerRepresentable

        init(_ parent: ISBNTextScannerViewControllerRepresentable) {
            self.parent = parent
        }

        func didDetectISBN(_ isbn: String) {
            DispatchQueue.main.async {
                // Show loading state immediately
                self.parent.isLoading = true
                self.parent.detectedISBN = isbn

                // Delay slightly to show the loading animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.parent.scannedISBN = isbn

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
                print("ISBN scanner error: \(error.localizedDescription)")
            }
        }
    }
}
#endif
