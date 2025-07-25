//import Foundation
//import CreateML
//import CoreML
//import TabularData
//
//struct MotionTrainingRecord: Codable {
//    let label: String
//    let samples: [Float]
//}
//
//final class TripStartTrainer {
//    private let logsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("motion_logs")
//
//    func trainModel(completion: @escaping (Result<URL, Error>) -> Void) {
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                let records = try self.loadTrainingData()
//                let url = try self.trainModel(with: records)
//                completion(.success(url))
//            } catch {
//                completion(.failure(error))
//            }
//        }
//    }
//
//    /// Refactored internal model training for data reuse.
//    func trainModel(with records: [MotionTrainingRecord]) throws -> URL {
//        let frame = try self.createDataFrame(from: records)
//        let model = try MLLogisticRegressionClassifier(trainingData: frame, targetColumn: "label")
//        let modelURL = self.modelSaveURL()
//        try model.write(to: modelURL)
//        return modelURL
//    }
//
//    private func loadTrainingData() throws -> [MotionTrainingRecord] {
//        guard FileManager.default.fileExists(atPath: logsDirectory.path) else { return [] }
//
//        let files = try FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
//        var records: [MotionTrainingRecord] = []
//
//        for file in files where file.pathExtension == "json" {
//            let data = try Data(contentsOf: file)
//            let record = try JSONDecoder().decode(MotionTrainingRecord.self, from: data)
//            records.append(record)
//        }
//
//        return records
//    }
//
//    private func createDataFrame(from records: [MotionTrainingRecord]) throws -> DataFrame {
//        // Flatten to column-major dictionary
//        let labels = records.map { $0.label }
//        let samples = records.map { $0.samples }
//
//        var frame = DataFrame()
//        frame.append(column: Column(name: "label", contents: labels))
//        frame.append(column: Column(name: "accelerometer_input", contents: samples))
//        return frame
//    }
//
//    private func modelSaveURL() -> URL {
//        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//        return dir.appendingPathComponent("TripStartModel.mlmodel")
//    }
//
//    func writeMotionEvent(_ event: MotionEvent) {
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
//        let filename = "\(event.label)_\(Int(event.timestamp.timeIntervalSince1970)).json"
//        let url = logsDirectory.appendingPathComponent(filename)
//
//        do {
//            let trainingRecord = MotionTrainingRecord(label: event.label, samples: event.samples.map { Float($0.value) })
//            let data = try encoder.encode(trainingRecord)
//            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
//            try data.write(to: url)
//        } catch {
//            print("Failed to write motion event: \(error)")
//        }
//    }
//    
//    static func train(with events: [MotionEvent]) throws -> URL {
//        let trainer = TripStartTrainer()
//
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
//        try FileManager.default.createDirectory(at: trainer.logsDirectory, withIntermediateDirectories: true, attributes: nil)
//
//        for event in events {
//            let record = MotionTrainingRecord(label: event.label, samples: event.samples.map { Float($0.value) })
//            let filename = "\(event.label)_\(Int(event.timestamp.timeIntervalSince1970)).json"
//            let url = trainer.logsDirectory.appendingPathComponent(filename)
//            let data = try encoder.encode(record)
//            try data.write(to: url)
//        }
//
//        var result: Result<URL, Error>!
//        let semaphore = DispatchSemaphore(value: 0)
//        trainer.trainModel { r in
//            result = r
//            semaphore.signal()
//        }
//        semaphore.wait()
//
//        switch result {
//        case .success(let url):
//            ModelStore.shared.updateModelURL(url)
//            return url
//        case .failure(let error): throw error
//        case .none: throw NSError(domain: "TripStartTrainer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Training failed"])
//        }
//    }
//}
