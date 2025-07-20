import Foundation

enum ExportField: String, CaseIterable, Codable, Hashable {
    case distance
    case date
    case startTime
    case endTime
    case startCoordinates
    case endCoordinates
    case duration
    case path
}

protocol ExportSettingsProtocol: ObservableObject {
    var includeRawCoordinates: Bool { get set }
    var exportFieldOptions: Set<ExportField> { get set }
    var defaultExportFileNamePrefix: String { get set }
}
