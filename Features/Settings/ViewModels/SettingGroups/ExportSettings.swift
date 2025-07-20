import Foundation

final class ExportSettings: ExportSettingsProtocol {
    @Published var includeRawCoordinates: Bool
    @Published var exportFieldOptions: Set<ExportField>
    @Published var defaultExportFileNamePrefix: String

    init(store: SettingsStoreProtocol) {
        self.includeRawCoordinates = store.includeRawCoordinates
        self.exportFieldOptions = store.exportFieldOptions
        self.defaultExportFileNamePrefix = store.defaultExportFileNamePrefix
    }
}
