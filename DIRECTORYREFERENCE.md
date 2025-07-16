//
//  DIRECTORYREFERENCE.md
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/15/25.
//

SimpleMiles/
├── App/
│   ├── ContentView.swift
│   ├── GoogleServiced-Info.plist
│   ├── Simple_MilesApp.swift
├── Resources/
│   ├── Assests.xcassets
│   ├── SimpleMilesModel.xcdatamodeld
├── Tests/
│   ├── SimpleMilesTests/
│   │   ├── Features/
│   │   │   ├── Authentication/
│   │   │   │   ├── Models/
│   │   │   │   │   ├── UserModelTests.swift
│   │   │   │   ├── Services/
│   │   │   │   │   ├── AuthServiceTests.swift
│   │   │   │   ├── ViewModels/
│   │   │   │   │   ├── AuthViewModelTests.swift
│   │   │   │   ├── Views/
│   │   │   │   │   ├── LoginViewTests.swift
│   │   │   ├── Core/
│   │   │   │   ├── CoreData/
│   │   │   │   │   ├── CoreDataMappingTests.swift
│   │   │   │   │   ├── TripSessionStoreTests.swift
│   │   │   ├── Export/
│   │   │   │   ├── Schema/
│   │   │   │   │   ├── CSVExportSchemaTests.swift
│   │   │   │   │   ├── JSONExportSchemaTests.swift
│   │   │   │   ├── ViewModels/
│   │   │   │   │   ├── TripExportViewModelTests.swift
│   │   │   │   ├── Writers/
│   │   │   │   │   ├── CSVTripWriterTests.swift
│   │   │   │   │   ├── FileExportWriterTests.swift
│   │   │   │   │   ├── JSONTripWriterTests.swift
│   │   │   ├── Map/
│   │   │   │   ├── Renderers/
│   │   │   │   │   ├── TripOverlayRendererTests.swift
│   │   │   │   ├── ViewModels/
│   │   │   │   │   ├── MapViewModelTests.swift
│   │   │   ├── Permissions/
│   │   │   │   ├── Models/
│   │   │   │   │   ├── PrivacyConsentLevelsTests.swift
│   │   │   │   ├── Services/
│   │   │   │   │   ├── PermissionsServiceTests.swift
│   │   │   │   ├── ViewModels/
│   │   │   │   │   ├── Groups/
│   │   │   │   │   │   ├── DataPrivacyPermissionsTests.swift
│   │   │   │   │   │   ├── SystemLevelPermissionsTests.swift
│   │   │   │   │   ├── PermissionsViewModelTests.swift
│   │   │   ├── Settings/
│   │   │   │   ├── Models/
│   │   │   │   │   ├── DistanceUnitTests.swift
│   │   │   │   │   ├── ExportFormatTests.swift
│   │   │   │   │   ├── MotionSensitivityLevelTests.swift
│   │   │   │   │   ├── TimeFormatTests.swift
│   │   │   │   ├── Services/
│   │   │   │   │   ├── SettingsKeysTests.swift
│   │   │   │   │   ├── SettingsStoreTests.swift
│   │   │   │   ├── ViewModels/
│   │   │   │   │   ├── Groups/
│   │   │   │   │   │   ├── ClassificationSettingsTests.swift
│   │   │   │   │   │   ├── DisplaySettingsTests.swift
│   │   │   │   │   │   ├── ExportSettingsTests.swift
│   │   │   │   │   │   ├── RecordingSettingsTests.swift
│   │   │   │   │   ├── SettingsViewModelTests.swift
│   │   │   ├── Trips/
│   │   │   │   ├── Models/
│   │   │   │   │   ├── CoordinateTests.swift
│   │   │   │   │   ├── TripModelTests.swift
│   │   │   │   │   ├── TripSegmentTests.swift
│   │   │   │   │   ├── TripSessionTests.swift
│   │   │   │   │   ├── TripTypeTests.swift
│   │   │   │   ├── Services/
│   │   │   │   │   ├── TripSerializerTests.swift
│   │   │   │   │   ├── TripStorageTests.swift
│   │   │   │   ├── ViewModels/
│   │   │   │   │   ├── TripClassificationViewModelTests.swift
│   │   │   │   │   ├── TripDetailViewModelTests.swift
│   │   │   │   │   ├── TripHistoryViewModelTests.swift
│   │   │   │   │   ├── TripRecordingViewModelTests.swift
│   │   │   │   │   ├── TripSummaryViewModelTests.swift
│   │   │   │   │   ├── TripViewModelTests.swift
│   │   │   ├── TripTracking/
│   │   │   │   ├── Components/
│   │   │   │   │   ├── TripRecorderTests.swift
│   │   │   │   │   ├── TripRecordingStateTests.swift
│   │   │   │   ├── Protocols/
│   │   │   │   │   ├── MovementAnalyzerProtocolTests.swift
│   │   │   │   ├── Services/
│   │   │   │   │   ├── MovementAnalyzerTests.swift
│   │   │   │   │   ├── TripTrackingServiceTest.swift
│   │   ├── Mocks/
│   │   │   ├── MockAuth.swift
│   │   │   ├── MockAuthSession.swift
│   │   │   ├── MockMovementAnalyzer.swift
│   │   │   ├── MockSettingsStore.swift
│   │   │   ├── MockTripSegmentModel.swift
│   │   │   ├── MockTripSessionModel.swift
│   │   │   ├── MockTripSessionStore.swift
│   │   │   ├── MockTripTrackingService.swift
│   │   │   ├── MockUserModel.swift
│   │   ├── Utilites/
│   │   │   ├── Validation/
│   │   │   │   ├── EmailValidationTests.swift
│   │   │   │   ├── PasswordValidationTests.swift
│   ├── Validation/
│   │   ├── EmailValidation.swift
│   │   ├── PasswordValidation.swift
├── Features/
│   ├── Authentication/
│   │   ├── Models/
│   │   │   ├── UserModel.swift
│   │   ├── Services/
│   │   │   ├── AuthProtocol.swift
│   │   │   ├── AuthService.swift
│   │   │   ├── AuthSession.swift
│   │   │   ├── FirebaseAuthSession.swift
│   │   ├── ViewModels/
│   │   │   ├── AuthViewModel.swift
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   ├── Core/
│   │   ├── CoreData/
│   │   │   ├── CoreDataMapping.swift
│   │   │   ├── CoreDataStack.swift
│   │   │   ├── Entities/
│   │   │   │   ├── CDCoordinate+CoreDataClass.swift
│   │   │   │   ├── CDCoordinate+CoreDataProperties.swift
│   │   │   │   ├── CDTripSegment+CoreDataClass.swift
│   │   │   │   ├── CDTripSegment+CoreDataProperties.swift
│   │   │   │   ├── CDTripSession+CoreDataClass.swift
│   │   │   │   ├── CDTripSession+CoreDataProperties.swift
│   ├── Developer/
│   │   ├── ViewModels/
│   │   │   ├── DeveloperPanelViewModel.swift
│   │   ├── Views/
│   │   │   ├── DeveloperPanelView.swift
│   │   │   ├── LiveLocationMapView.swift
│   ├── Exports/
│   │   ├── Presenters/
│   │   │   ├── ShareSheet.swift
│   │   ├── Schemas/
│   │   │   ├── CSVExportSchema.swift
│   │   │   ├── JSONExportSchema.swift
│   │   ├── ViewModels/
│   │   │   ├── TripExportViewModel.swift
│   │   ├── Writers/
│   │   │   ├── FileExportWriter.swift
│   │   │   ├── CSV/
│   │   │   │   ├── CompressionHelper.swift
│   │   │   │   ├── CSVCoordinateWriter.swift
│   │   │   │   ├── CSVTripWriter.swift
│   │   │   │   ├── FileZipper.swift
│   │   │   │   ├── TripExportCoordinator.swift
│   │   │   ├── JSON/
│   │   │   │   ├── JSONTripWriter.swift
│   │   ├── ExportLauncher.swift
│   ├── Map/
│   │   ├── Renderers/
│   │   │   ├── TripOverlayRenderer.swift
│   │   ├── ViewModels/
│   │   │   ├── MapViewModel.swift
│   │   ├── Views/
│   │   │   ├── MapContainerView.swift
│   │   │   ├── MapView.swift
│   ├── Permissions/
│   │   ├── Models/
│   │   │   ├── PrivacyConsentLevel.swift
│   │   ├── Services/
│   │   │   ├── PermissionService.swift
│   │   ├── ViewModels/
│   │   │   ├── Groups/
│   │   │   │   ├── DataPrivacyPermissions.swift
│   │   │   │   ├── SystemLevelPermissions.swift
│   │   │   ├── PermissionsViewModel.swift
│   ├── Settings/
│   │   ├── Models/
│   │   │   ├── DistanceUnit.swift
│   │   │   ├── ExportFormat.swift
│   │   │   ├── MotionSensitivityLevel.swift
│   │   │   ├── TimeFormat.swift
│   │   ├── Services/
│   │   │   ├── SettingsKeys.swift
│   │   │   ├── SettingsStore.swift
│   │   ├── View/
│   │   ├── ViewModels/
│   │   │   ├── SettingGroups/
│   │   │   │   ├── ClassificationSettings.swift
│   │   │   │   ├── DisplaySettings.swift
│   │   │   │   ├── ExportSettings.swift
│   │   │   │   ├── RecordingSettings.swift
│   │   │   ├── SettingsViewModel.swift
│   ├── Trips/
│   │   ├── Models/
│   │   │   ├── CoordinateModel.swift
│   │   │   ├── TripModel.swift
│   │   │   ├── TripSegmentModel.swift
│   │   │   ├── TripSessionModel.swift
│   │   │   ├── TripType.swift
│   │   ├── Protocols/
│   │   │   ├── TripSessionStoringProtocol.swift
│   │   ├── Services/
│   │   │   ├── TripSerializer.swift
│   │   │   ├── TripSessionStore.swift
│   │   │   ├── TripStorageService.swift
│   │   ├── ViewModels/
│   │   │   ├── TripClassificationViewModel.swift
│   │   │   ├── TripDetailViewModel.swift
│   │   │   ├── TripHistoryViewModel.swift
│   │   │   ├── TripRecordingViewModel.swift
│   │   │   ├── TripSummaryViewModel.swift
│   │   ├── Views/
│   ├── TripTracking/
│   │   ├── Components/
│   │   │   ├── TripRecorder.swift
│   │   │   ├── TripRecordingState.swift
│   │   │   ├── TripRecordingStatus.swift
│   │   ├── Protocols/
│   │   │   ├── MovementAnalyzerProtocol.swift
│   │   │   ├── TripTrackingServiceProtocol.swift
│   │   ├── Services/
│   │   │   ├── MovementAnalyzer.swift
│   │   │   ├── TripTrackingService.swift
