//import Foundation
//import CoreML
//
//struct TripStartModel {
//    private var model: MLModel?
//
//    init() {
//        loadModel()
//    }
//
//    init(model: MLModel) {
//        self.model = model
//    }
//
//    mutating func loadModel() {
//        if let url = try? modelURL(),
//           let loadedModel = try? MLModel(contentsOf: url) {
//            self.model = loadedModel
//        } else {
//            print("TripStartModel: Failed to load model from disk.")
//        }
//    }
//
//    func predict(samples: [MotionSample]) -> Bool {
//        guard let model = model else { return false }
//
//        let input = TripStartInput(samples: samples)
//
//        do {
//            let prediction = try model.prediction(from: input)
//            if let label = prediction.featureValue(for: "label")?.stringValue {
//                return label == "trip_start"
//            }
//            return false
//        } catch {
//            print("TripStartModel: Prediction error - \(error)")
//            return false
//        }
//    }
//
//    mutating func retrain(with events: [MotionEvent]) {
//        // Placeholder for on-device retraining using MLUpdateTask
//        // Load stored MotionEvent records into a MLBatchProvider and invoke update()
//    }
//
//    private func modelURL() throws -> URL {
//        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//        return directory.appendingPathComponent("TripStartModel.mlmodelc")
//    }
//}
//
//// MARK: - Placeholder Structs
//
//class TripStartInput: MLFeatureProvider {
//    let samples: [MotionSample]
//
//    init(samples: [MotionSample]) {
//        self.samples = samples
//    }
//
//    var featureNames: Set<String> {
//        return ["accelerometer_input"]
//    }
//
//    func featureValue(for featureName: String) -> MLFeatureValue? {
//        guard featureName == "accelerometer_input" else { return nil }
//
//        let maxCount = 128
//        let magnitudes = samples.map { sqrt($0.x * $0.x + $0.y * $0.y + $0.z * $0.z) }
//
//        // Pad with zeros or truncate to exactly 128 values
//        let padded: [Float]
//        if magnitudes.count >= maxCount {
//            padded = Array(magnitudes.suffix(from: magnitudes.count - maxCount)).map { Float($0) }
//        } else {
//            padded = magnitudes.map { Float($0) } + Array(repeating: 0, count: maxCount - magnitudes.count)
//        }
//
//        return try? MLFeatureValue(multiArray: MLMultiArray(padded))
//    }
//}
//
//// MARK: - MLMultiArray Helper Extension
//
//extension MLMultiArray {
//    convenience init(_ floatArray: [Float]) throws {
//        try self.init(shape: [NSNumber(value: floatArray.count)], dataType: .float32)
//        for (i, val) in floatArray.enumerated() {
//            self[i] = NSNumber(value: val)
//        }
//    }
//}
