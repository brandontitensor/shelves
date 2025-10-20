import SwiftUI
#if canImport(UIKit) && canImport(AVFoundation)
import UIKit
import AVFoundation

struct BarcodeScannerView: View {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    
    var body: some View {
        ZStack {
            if permissionDenied {
                permissionDeniedView
            } else {
                ScannerViewControllerRepresentable(scannedCode: $scannedCode, isPresented: $isPresented)
                    .ignoresSafeArea()
                
                // Overlay UI
                VStack {
                    // Top bar
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
                    .padding()
                    
                    Spacer()
                    
                    // Scanning frame
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 250, height: 150)
                        .overlay(
                            VStack {
                                Spacer()
                                Text("Position barcode within frame")
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                            }
                            .offset(y: 80)
                        )
                    
                    Spacer()
                    
                    // Bottom instruction
                    Text("Point your camera at the barcode on the back of your book")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
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
                self.parent.scannedCode = code
                self.parent.isPresented = false
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
        if !alreadyScanned {
            hasScanned = true
        }
        scanLock.unlock()

        guard !alreadyScanned else { return }

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            stopSession()

            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            // Small delay to ensure user sees the scan happened
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.delegate?.didScanBarcode(stringValue)
            }
        }
    }
}
#endif