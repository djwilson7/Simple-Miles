# Simple Miles (v1.0.0)

Simple Miles is an intelligent, high-performance mileage tracking application engineered specifically for gig delivery drivers. Built from the ground up with a zero-third-party dependency philosophy, it offers automated, seamless trip detection and local, low-latency data persistence. 

The core mission of Simple Miles is privacy-first utility: **all tracking and location processing occurs strictly on-device, ensuring user data never leaves the hardware.**

---

## Product in Action

### 1. Set It and Forget It (Active Trip Session)

All you have to do is drive. Simple Miles works entirely in the background, utilizing advanced spatial state machines to monitor speed and coordinate deltas. It infers transitions between `Idle` and `Traveling` states, intelligently stitching raw GPS streams into continuous, cohesive trips without requiring manual user intervention.

**[INSERT: GIF of landing page and active trip in session]**

### 2. Streamlined Organization (Sorting Trips)

Once a trip is complete, coordinates are instantly written to disk. Drivers can rapidly jump into their trip history, review the accurately captured route paths, and efficiently sort individual trips into distinct, customizable category bins (e.g., DoorDash, UberEats, Personal) to keep tax-deductible miles cleanly segregated.

**[INSERT: GIF of opening and sorting existing trips]**

### 3. Granular Performance Visibility (Trip Analytics)

Simple Miles pre-aggregates trip data locally to build a robust performance dashboard. Drivers can instantly inspect high-level mileage summaries, historical trends, and cost-benefit breakdowns for each driving category, providing clear, real-time financial visibility into their driving efficiency.

**[INSERT: GIF of opening and inspecting analytics for trips]**

### 4. Tailored to Your Habits (Algorithmic Tuning & Themes)

Every driver has different patterns. Simple Miles allows users to adjust custom metrics that tune the underlying segment detection algorithm based on personal driving styles and desired trip sensitivities. This prevents minor stops (like traffic lights or drive-thrus) from fragmenting single routes. Additionally, the entire glassmorphic interface seamlessly adapts to system dark, light, and custom themes.

**[INSERT: GIF of changing the theme and tuning settings]**

---

## Technical Implementation Breakdown

Simple Miles separates real-time hardware telemetry processing from declarative UI rendering using a strict subsystem boundary. Below is the engineering breakdown of how data travels from the device's GPS hardware down into compressed cold storage.

```text
┌────────────────────────────────────────────────────────┐
│                  CoreLocation Stream                   │
└───────────────────────────┬────────────────────────────┘
                            │ (1Hz Raw Coordinates)
┌───────────────────────────▼────────────────────────────┐
│                    RecordingManager                    │
│       [TravelState Evaluation: Idle vs Traveling]      │
└───────────────────────────┬────────────────────────────┘
                            │ (Buffered Memory Segments)
┌───────────────────────────▼────────────────────────────┐
│                      SegmentStore                      │
│       [Applies LZFSE/LZ4 Compression Codecs]           │
└───────────────────────────┬────────────────────────────┘
                            │ (Synchronous Serial DB Queue)
┌───────────────────────────▼────────────────────────────┐
│               SQLite3 C API Persistence                │
│       [WAL Mode Enabled / File Encryption]             │
└────────────────────────────────────────────────────────┘
```

### 1. Telemetry Ingestion & State Machine
The lifecycle of a trip is managed implicitly through spatial delta matrices:
* **CoreLocation Interception:** `LocationManager` consumes raw coordinate feeds. Rather than writing raw data directly to disk—which degrades battery life and storage space—the stream is handed over to the domain layer.
* **TravelState Evaluation:** The `RecordingManager` runs an internal state machine evaluating real-time velocity thresholds and distance deltas. If a driver stops at a prolonged traffic light, the system enters a smart pause state. If the vehicle surpasses the custom trip sensitivity metrics configured by the user, the system transparently stitches the segments into a unified `TripSegment` buffer in memory.

### 2. Real-Time Graphics Interpolation
To bridge the gap between low-frequency hardware updates and premium visual performance, the app completely decouples the rendering loop from GPS delivery:
* **Dead Reckoning & Splines:** `LocationPredictionManager` and `LocationAnimationManager` intercept the 1Hz telemetry updates. By analyzing historical velocity vectors, it applies spline mathematics to extrapolate smooth, intermediate coordinate paths.
* **60fps Map Performance:** This mathematical extrapolation updates the map puck's coordinates at a native 60fps, completely eliminating the visual "stutter" typical of standard GPS utilities. Simultaneously, `CameraAnimationManager` runs fluid, time-factored interpolations over viewport pitch and heading adjustments.

### 3. Binary Compression & Persistence Layer
When a trip completes, the in-memory buffer must be committed to cold storage with minimal footprint:
* **LZFSE/LZ4 Codecs:** The raw coordinate array is serialized into a binary stream and compressed using Apple's high-efficiency compression primitives via the `SQLiteDB` module.
* **Storage Schema:** Metadata and compressed payloads are split across two core tables via targeted Data Access Objects (`TripsDAO` and `TripBlobsDAO`):

```text
  trips (Metadata)                  trip_blobs (Payload)
┌─────────────────┐               ┌─────────────────────────────┐
│ id (PK)         │◄─────────────-┤ trip_id (FK, Composite PK)  │
│ type (Category) │               │ kind ('raw' / 'display')    │
│ start_ts        │               │ codec ('lz4' / 'lzfse')     │
│ end_ts          │               │ bytes (BLOB)                │
│ distance_m      │               └─────────────────────────────┘
│ bbox Extents    │
└─────────────────┘
```
* **Thread-Safe SQL Pipeline:** To maintain non-blocking UI behavior while ensuring total data integrity, all SQLite statements are executed synchronously on a dedicated background Grand Central Dispatch serial queue (`com.simplemiles.db`). Write-Ahead Logging (WAL) is enabled to allow concurrent reads even during active database flushes.

---

## Technical Stack & Architecture Summary

### Architectural Profile
* **Frontend:** MVVM (Model-View-ViewModel) utilizing SwiftUI. Strict UI-thread safety is enforced across all presentation models using `@MainActor`.
* **Backend Domain:** Asynchronous, manager-driven architecture. State propagation and decoupling are managed via **Apple Combine** publishers (`CurrentValueSubject`, `PassthroughSubject`).
* **Dependencies:** Zero third-party packages. Built purely on native system frameworks (`CoreLocation`, `MapKit`, `SwiftUI`, `Combine`, and raw `sqlite3`).

### Target Specifications
* **Platforms:** iOS 17.0+, macOS 14.0+
* **Language Compatibility:** Swift 5.10 / Swift 6.0
* **Data Security:** Hardware-enforced file protection via `completeUntilFirstUserAuthentication`.

---

## Testing & Verification

The codebase implements a strict testing architecture utilizing the native **Swift Testing framework** to validate mathematical utilities, state machine boundaries, and database locks. 

The backend module maintains an elite **96% unit test coverage** mark across more than 180 verified test cases, ensuring extreme stability for the core telemetry and persistence layers.

```swift
import Testing
@testable import SimpleMilesBackEnd

@Suite("Database Transaction Stability", .serialized)
struct DatabaseTests {
    // Sequentially enforced test cases verifying constraint safety
}
```

* **96% Backend Coverage:** Deep assertions cover every structural logic gate within the geometry primitives, state machine velocity calculations, and raw database serialization loops.
* **Serialized Execution:** All suites modifying or inspecting the persistent SQLite database singleton are explicitly flagged with the `.serialized` trait, forcing sequential evaluation to block thread contention or foreign-key race conditions during concurrent test runs.
* **Mock Isolation:** Dependency injection is used across all managers, ensuring testing routines use isolated, ephemeral `UserDefaults` suites to completely decouple test assertions from host-device environment variables.


## Author

Made with ❤️ by Dontai Wilson
