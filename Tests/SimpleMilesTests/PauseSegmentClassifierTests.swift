import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("PauseSegmentClassifier Tests")
struct PauseSegmentClassifierTests {
    
    @Test("Short duration segment should merge")
    func testShortDuration() {
        var segment = TripSegment(startTimestamp: Date())
        segment.duration = 20 // < 30
        let shouldMerge = PauseSegmentClassifier.shouldMerge(segment, anchorHeading: 0, headingBuffer: [])
        #expect(shouldMerge == true)
    }
    
    @Test("Insufficient heading data should merge")
    func testInsufficientData() {
        var segment = TripSegment(startTimestamp: Date())
        segment.duration = 40
        let shouldMerge = PauseSegmentClassifier.shouldMerge(segment, anchorHeading: 0, headingBuffer: [0, 1, 2, 3]) // < 5
        #expect(shouldMerge == true)
    }
    
    @Test("Headings within 90 degrees should merge")
    func testConsistentHeadings() {
        var segment = TripSegment(startTimestamp: Date())
        segment.duration = 40
        let buffer: [CLLocationDirection] = [10, 20, 30, 20, 10]
        let shouldMerge = PauseSegmentClassifier.shouldMerge(segment, anchorHeading: 0, headingBuffer: buffer)
        #expect(shouldMerge == true)
    }
    
    @Test("Highly variable headings should NOT merge")
    func testVariableHeadings() {
        var segment = TripSegment(startTimestamp: Date())
        segment.duration = 40
        // Headings that go all over the place
        let buffer: [CLLocationDirection] = [0, 90, 180, 270, 0, 180]
        let shouldMerge = PauseSegmentClassifier.shouldMerge(segment, anchorHeading: 0, headingBuffer: buffer)
        #expect(shouldMerge == false)
    }
    
    @Test("Duration threshold edge case")
    func testDurationEdge() {
        var segment = TripSegment(startTimestamp: Date())
        segment.duration = 30 // exactly the threshold
        let shouldMerge = PauseSegmentClassifier.shouldMerge(segment, anchorHeading: 0, headingBuffer: [0, 0, 0, 0, 0])
        #expect(shouldMerge == true)
    }
    
    @Test("Empty buffer should merge")
    func testEmptyBuffer() {
        var segment = TripSegment(startTimestamp: Date())
        segment.duration = 40
        let shouldMerge = PauseSegmentClassifier.shouldMerge(segment, anchorHeading: 0, headingBuffer: [])
        #expect(shouldMerge == true)
    }

    @Test("Normalize headings with empty array")
    func testNormalizeHeadingsEmpty() {
        let result = PauseSegmentClassifier.normalizeHeadings([])
        #expect(result.isEmpty)
    }

    @Test("Scale headings with < 2 elements")
    func testScaleHeadingsShort() {
        let result = PauseSegmentClassifier.scaleHeadingsToUnitVariance([0])
        #expect(result.isEmpty)
    }

    @Test("Scale headings with 0 variance")
    func testScaleHeadingsZeroVariance() {
        let result = PauseSegmentClassifier.scaleHeadingsToUnitVariance([10, 10, 10])
        #expect(result == [0.0, 0.0, 0.0])
    }

    @Test("Heading deltas")
    func testHeadingDeltas() {
        let result = PauseSegmentClassifier.headingDeltas(from: 10, to: [20, 350, 190])
        #expect(result[0] == 10)
        #expect(result[1] == -20)
        #expect(abs(result[2]) == 180)
    }

    @Test("Should merge low variance")
    func testMergeLowVariance() {
        var segment = TripSegment(startTimestamp: Date())
        segment.duration = 40
        let buffer: [CLLocationDirection] = [180, 185, 175, 180, 180, 180]
        let shouldMerge = PauseSegmentClassifier.shouldMerge(segment, anchorHeading: 0, headingBuffer: buffer)
        #expect(shouldMerge == true)
    }
}
