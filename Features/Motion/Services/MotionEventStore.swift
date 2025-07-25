//import Foundation
//
//final class MotionEventStore {
//    static let shared = MotionEventStore()
//    private init() {}
//
//    private var events: [MotionEvent] = []
//    private let trainingThreshold: Int = 30
//
//    var isReadyToTrain: Bool {
//        return events.count >= trainingThreshold
//    }
//
//    func append(_ event: MotionEvent) {
//        events.append(event)
//        print("[MotionEventStore] Appended event. Total stored: \(events.count)")
//        print("[MotionEventStore] Event Label: \(event.label), Timestamp: \(event.timestamp)")
//
//        if events.count % trainingThreshold == 0 {
//            DispatchQueue.global(qos: .background).async {
//                do {
////                    let _ = try TripStartTrainer.train(with: self.events)
//                } catch {
//                    print("Training failed: \(error)")
//                }
//            }
//        }
//    }
//
//    func allEvents() -> [MotionEvent] {
//        return events
//    }
//
//    func clear() {
//        events.removeAll()
//    }
//
//    func export(to url: URL) throws {
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
//        let data = try encoder.encode(events)
//        try data.write(to: url)
//    }
//}
//
//extension Notification.Name {
//    static let readyToTrain = Notification.Name("MotionEventStore.readyToTrain")
//}
