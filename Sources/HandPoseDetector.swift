import Foundation
import Vision
import CoreMedia

public class HandPoseDetector {
    private let handPoseRequest: VNDetectHumanHandPoseRequest
    private let queue = DispatchQueue(label: "com.handmouse.vision", qos: .userInteractive)
    private var isBusy = false
    
    public var onHandDetected: ((HandLandmarks?, Double) -> Void)?
    
    public init() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
    }
    
    public func process(sampleBuffer: CMSampleBuffer) {
        guard !isBusy else { return } // Drop frame if previous is still processing to maintain 0 latency
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        isBusy = true
        queue.async { [weak self] in
            defer { self?.isBusy = false }
            guard let self = self else { return }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([self.handPoseRequest])
                guard let results = self.handPoseRequest.results, let observation = results.first else {
                    self.onHandDetected?(nil, timestamp)
                    return
                }
                
                let landmarks = self.extractLandmarks(from: observation)
                self.onHandDetected?(landmarks, timestamp)
            } catch {
                self.onHandDetected?(nil, timestamp)
            }
        }
    }
    
    private func extractLandmarks(from observation: VNHumanHandPoseObservation) -> HandLandmarks? {
        let allJoints: [VNHumanHandPoseObservation.JointName] = [
            .wrist,
            .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
            .indexMCP, .indexPIP, .indexDIP, .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP, .ringPIP, .ringDIP, .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip
        ]
        
        var points: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        var confidences: [VNHumanHandPoseObservation.JointName: Float] = [:]
        
        for joint in allJoints {
            if let recognized = try? observation.recognizedPoint(joint), recognized.confidence > 0.25 {
                points[joint] = recognized.location
                confidences[joint] = recognized.confidence
            }
        }
        
        // Ensure at least wrist and index are present
        guard points[.wrist] != nil || points[.indexMCP] != nil else {
            return nil
        }
        
        return HandLandmarks(points: points, confidences: confidences)
    }
}
