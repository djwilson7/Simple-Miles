//import Foundation
//import CoreMotion
//
//struct MotionSample: Encodable {
//    let x: Double
//    let y: Double
//    let z: Double
//    let value: Double
//    let timestamp: Date
//}
//
//struct MotionEvent: Encodable {
//    let label: String
//    let timestamp: Date
//    let samples: [MotionSample]
//}
//
//final class MotionDataCollector {
//    private var buffer: [MotionSample] = []
//    private let bufferDuration: TimeInterval = 30
//    private let sampleRate: TimeInterval = 1.0 / 50.0 // 50 Hz expected
//    private let maxBufferSize: Int
//    private let queue = DispatchQueue(label: "motion.data.collector.queue")
//
//    init() {
//        self.maxBufferSize = Int(bufferDuration / sampleRate)
//    }
//
//    func addSample(x: Double, y: Double, z: Double, timestamp: Date = Date()) {
//        queue.async {
//            let magnitude = sqrt(x * x + y * y + z * z)
//            let sample = MotionSample(x: x, y: y, z: z, value: magnitude, timestamp: timestamp)
//            self.buffer.append(sample)
//
//            if self.buffer.count > self.maxBufferSize {
//                self.buffer.removeFirst(self.buffer.count - self.maxBufferSize)
//            }
//        }
//    }
//
//    func extractLabeledEvent(label: String) -> MotionEvent? {
//        return queue.sync {
//            guard buffer.count >= maxBufferSize else {
//                print("[MotionDataCollector] Not enough samples: \(buffer.count)/\(maxBufferSize)")
//                return nil
//            }
//            return MotionEvent(label: label, timestamp: Date(), samples: buffer)
//        }
//    }
//
//    func clear() {
//        queue.async {
//            self.buffer.removeAll()
//        }
//    }
//}
