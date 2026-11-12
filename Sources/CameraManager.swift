import Foundation
import AVFoundation

public protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutputSampleBuffer sampleBuffer: CMSampleBuffer)
    func cameraManager(_ manager: CameraManager, didUpdateFPS fps: Double)
}

public class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public weak var delegate: CameraManagerDelegate?
    
    public let captureSession = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.handmouse.camera", qos: .userInteractive)
    
    public private(set) var availableDevices: [AVCaptureDevice] = []
    public private(set) var currentDevice: AVCaptureDevice?
    
    // FPS tracking
    private var frameCount: Int = 0
    private var lastFPSCheckTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    
    public override init() {
        super.init()
        discoverDevices()
    }
    
    public func discoverDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        self.availableDevices = discoverySession.devices
        self.currentDevice = discoverySession.devices.first ?? AVCaptureDevice.default(for: .video)
    }
    
    public static var cameraAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    public static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    public func setup() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high
            
            if let device = self.currentDevice ?? AVCaptureDevice.default(for: .video) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                        self.videoInput = input
                    }
                } catch {
                    print("Error initializing camera input: \(error)")
                }
            }
            
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    public func start() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    public func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    public func switchCamera(to device: AVCaptureDevice) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            
            if let currentInput = self.videoInput {
                self.captureSession.removeInput(currentInput)
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoInput = newInput
                    self.currentDevice = device
                }
            } catch {
                print("Failed to switch camera: \(error)")
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Track FPS
        frameCount += 1
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastFPSCheckTime >= 1.0 {
            let fps = Double(frameCount) / (now - lastFPSCheckTime)
            frameCount = 0
            lastFPSCheckTime = now
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.cameraManager(self, didUpdateFPS: fps)
            }
        }
        
        delegate?.cameraManager(self, didOutputSampleBuffer: sampleBuffer)
    }
}
