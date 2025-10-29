import Foundation
#if canImport(AVFoundation)
import AVFoundation

struct CameraPermissionHelper {
    static func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    static var isCameraAvailable: Bool {
        return AVCaptureDevice.default(for: .video) != nil
    }
}
#endif