//
//  ModelGuide.swift
//  SimpleMiles
//
//  File Guide for "Model"
//
//  Purpose:
//  A concise, copy‑pasteable guide for defining domain model types.
//  Prefer small, immutable value types; keep models framework‑free where possible.
//  Make serialization, identity, and formatting explicit and testable.
//

// MARK: - What belongs in a Model file
/*
 - One primary type that represents domain data (struct preferred)
 - Conformances: Equatable, Hashable, Identifiable, Codable as needed
 - Initialization invariants and lightweight validation
 - Value semantics (prefer let, small mutating APIs if needed)
 - Mapping to/from storage/transport types (DTOs) in separate helpers
 - No UI or networking code; keep models platform‑agnostic
*/

// MARK: - Section Order (for all Model files)
/*
 1) Imports (Foundation first; avoid UI frameworks)
 2) File-level doc (what the model represents)
 3) Primary type declaration (struct preferred)
 4) Nested Types (supporting enums, small helpers)
 5) Stored Properties (prefer let; document units)
 6) Init(s) with validation and defaults
 7) Computed properties / derived values (pure)
 8) Domain methods (pure or mutating, well-scoped)
 9) Protocol conformances (Equatable/Hashable/Codable/Identifiable)
10) Mapping Helpers (DTO <-> Domain) if applicable
11) Test fixtures (static samples) guarded by DEBUG
*/

// MARK: - Naming & Scope
/*
 - Name types with clear domain intent (TripMeta, TripSegment, Distance, Money)
 - Keep helpers internal/fileprivate; expose minimal public API
 - Document units (meters, seconds) in property comments to avoid ambiguity
 - Use ISO 8601 and UTC for wire formats; keep Date in the domain if possible
*/

// MARK: - Mutability & Thread-Safety
/*
 - Prefer immutable structs; if mutability is required, constrain via small mutating methods
 - If a reference type is required, ensure thread-safety or actor isolation at a higher layer
 - Avoid capturing global state; models should be deterministic and easy to test
*/

// MARK: - Errors & Validation
/*
 - Validate invariants in initializers (e.g., non-negative distances)
 - Use small domain error enums for failable operations
 - Keep throwing initializers minimal; prefer explicit factory methods if complex
*/

// MARK: - Units & Formatting
/*
 - Store canonical units internally (e.g., meters, seconds)
 - Keep presentation formatting outside (e.g., DistanceUtility/TimeUtility)
 - Provide derived computed values in canonical units only (km, hours) if needed
*/

// MARK: - Copy/Paste Template (Value Model)
/*
import Foundation

/// Represents a finalized trip summary row stored in the database.
/// Distances are stored in meters; durations in seconds; timestamps in milliseconds since epoch.
struct TripMeta: Equatable, Hashable, Identifiable, Codable {

    // MARK: - Identity
    var id: String

    // MARK: - Stored Properties (canonical units)
    /// Trip classification type (domain enum backed by Int in storage).
    var type: TripType
    /// Start timestamp in milliseconds since 1970-01-01 UTC.
    var startTs: Int64
    /// End timestamp in milliseconds since 1970-01-01 UTC.
    var endTs: Int64
    /// Total distance in meters.
    var distanceM: Double
    /// Total duration in seconds.
    var durationS: Double

    // MARK: - Bounding Box (optional for quick filtering)
    var bboxMinLat: Int
    var bboxMinLon: Int
    var bboxMaxLat: Int
    var bboxMaxLon: Int

    // MARK: - Metadata
    var sizeBytes: Int64
    var version: Int

    // MARK: - Init (validation)
    init(
        id: String,
        type: TripType,
        startTs: Int64,
        endTs: Int64,
        distanceM: Double,
        durationS: Double,
        bboxMinLat: Int,
        bboxMinLon: Int,
        bboxMaxLat: Int,
        bboxMaxLon: Int,
        sizeBytes: Int64,
        version: Int
    ) {
        precondition(endTs >= startTs, "endTs must be >= startTs")
        precondition(distanceM >= 0, "distance must be non-negative")
        precondition(durationS >= 0, "duration must be non-negative")
        self.id = id
        self.type = type
        self.startTs = startTs
        self.endTs = endTs
        self.distanceM = distanceM
        self.durationS = durationS
        self.bboxMinLat = bboxMinLat
        self.bboxMinLon = bboxMinLon
        self.bboxMaxLat = bboxMaxLat
        self.bboxMaxLon = bboxMaxLon
        self.sizeBytes = sizeBytes
        self.version = version
    }

    // MARK: - Computed / Derived
    var startDate: Date { Date(timeIntervalSince1970: TimeInterval(startTs) / 1000.0) }
    var endDate: Date { Date(timeIntervalSince1970: TimeInterval(endTs) / 1000.0) }
    var isEmpty: Bool { distanceM == 0 || durationS == 0 }

    // MARK: - Domain Methods (pure)
    func with(type newType: TripType) -> TripMeta {
        var copy = self
        copy.type = newType
        return copy
    }

    // MARK: - Codable (custom keys if needed)
    private enum CodingKeys: String, CodingKey {
        case id, type, startTs, endTs, distanceM, durationS
        case bboxMinLat, bboxMinLon, bboxMaxLat, bboxMaxLon
        case sizeBytes, version
    }
}
*/

// MARK: - Copy/Paste Template (DTO and Mapper)
/*
import Foundation

/// Wire/storage representation (e.g., database row or JSON) for TripMeta.
/// Keep this as close to the storage schema as possible.
struct TripMetaDTO: Codable, Equatable {
    var id: String
    var type: Int
    var start_ts: Int64
    var end_ts: Int64
    var distance_m: Double
    var duration_s: Double
    var bbox_min_lat: Int
    var bbox_min_lon: Int
    var bbox_max_lat: Int
    var bbox_max_lon: Int
    var size_bytes: Int64
    var version: Int
}

/// Mapping between DTO and domain model.
/// Keep these pure functions near the model or in a dedicated Mapper file.
enum TripMetaMapper {
    static func toDomain(_ dto: TripMetaDTO) -> TripMeta? {
        guard let domainType = TripType(dbValue: dto.type) else { return nil }
        return TripMeta(
            id: dto.id,
            type: domainType,
            startTs: dto.start_ts,
            endTs: dto.end_ts,
            distanceM: dto.distance_m,
            durationS: dto.duration_s,
            bboxMinLat: dto.bbox_min_lat,
            bboxMinLon: dto.bbox_min_lon,
            bboxMaxLat: dto.bbox_max_lat,
            bboxMaxLon: dto.bbox_max_lon,
            sizeBytes: dto.size_bytes,
            version: dto.version
        )
    }

    static func toDTO(_ model: TripMeta) -> TripMetaDTO {
        TripMetaDTO(
            id: model.id,
            type: model.type.dbValue,
            start_ts: model.startTs,
            end_ts: model.endTs,
            distance_m: model.distanceM,
            duration_s: model.durationS,
            bbox_min_lat: model.bboxMinLat,
            bbox_min_lon: model.bboxMinLon,
            bbox_max_lat: model.bboxMaxLat,
            bbox_max_lon: model.bboxMaxLon,
            size_bytes: model.sizeBytes,
            version: model.version
        )
    }
}
*/

// MARK: - Copy/Paste Template (Reference Model — only if necessary)
/*
import Foundation

/// Use a class only when identity and shared mutable state are required.
/// Consider actor isolation if accessed across threads.
final class MutableTripDraft: @unchecked Sendable {

    // MARK: - Stored Properties
    private(set) var id: String
    private(set) var points: [CLLocationCoordinate2D] = []
    private(set) var note: String?

    // MARK: - Init
    init(id: String) { self.id = id }

    // MARK: - Mutating Methods (constrained)
    func append(point: CLLocationCoordinate2D) {
        points.append(point)
    }

    func update(note: String?) {
        self.note = note
    }
}
*/

// MARK: - Testing & Fixtures
/*
 - Provide static sample instances behind #if DEBUG to aid previews/tests
 - Keep fixture data small and representative
*/
/*
#if DEBUG
extension TripMeta {
    static let sample = TripMeta(
        id: "sample-1",
        type: .business,
        startTs: 1_700_000_000_000,
        endTs: 1_700_000_900_000,
        distanceM: 12_345,
        durationS: 900,
        bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0,
        sizeBytes: 1024, version: 1
    )
}
#endif
*/

// MARK: - Common MARK Tags (for Models)
/*
 // MARK: - Identity
 // MARK: - Stored Properties
 // MARK: - Init
 // MARK: - Computed
 // MARK: - Domain Methods
 // MARK: - Codable
 // MARK: - Mapping
 // MARK: - Fixtures
*/
