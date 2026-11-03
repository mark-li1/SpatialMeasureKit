import Testing
import Foundation
import SpatialMeasureKit

@Suite("OneEuroFilter")
struct OneEuroFilterTests {
    private func makeFilter(beta: Float = 4) -> OneEuroFilter {
        OneEuroFilter(minCutoff: 1, beta: beta)
    }

    private func point(_ x: Float) -> SIMD3<Float> {
        SIMD3(x, 0, 0)
    }

    private func frame(_ index: Int) -> TimeInterval {
        TimeInterval(index) / 60
    }

    private func lagAfterOneSecond(beta: Float) -> Float {
        var filter = makeFilter(beta: beta)
        var output: Float = 0
        for index in 0...60 {
            output = filter.filter(point(Float(index) / 60), at: frame(index)).x
        }
        return 1 - output
    }

    // MARK: - Smoothing

    @Test("Passes the first value through unchanged")
    func firstValuePassesThrough() {
        var filter = makeFilter()

        #expect(filter.filter(SIMD3(1, 2, 3), at: frame(0)) == SIMD3(1, 2, 3))
    }

    @Test("A still input stays exactly still")
    func stillInputStaysStill() {
        var filter = makeFilter()
        let still = SIMD3<Float>(0.5, -1, 2)
        var firstMovedFrame: Int?

        for index in 0..<60 {
            let output = filter.filter(still, at: frame(index))
            if output != still, firstMovedFrame == nil {
                firstMovedFrame = index
            }
        }

        #expect(firstMovedFrame == nil)
    }

    @Test("A jump moves only part of the way at first, then arrives within half a second")
    func jumpIsSmoothedThenReached() {
        var filter = makeFilter()
        _ = filter.filter(point(0), at: frame(0))

        let first = filter.filter(point(1), at: frame(1)).x
        var latest = first
        for index in 2...30 {
            latest = filter.filter(point(1), at: frame(index)).x
        }

        #expect(first > 0 && first < 1)
        #expect(abs(latest - 1) < 0.001)
    }

    @Test("Smooths a shaking hand: ±1 mm of jitter comes out under 0.2 mm")
    func jitterIsSuppressed() {
        var filter = makeFilter()
        var worst: Float = 0

        for index in 0..<240 {
            let jitter: Float = index.isMultiple(of: 2) ? 0.001 : -0.001
            let output = filter.filter(point(jitter), at: frame(index)).x
            if index >= 60 {
                worst = max(worst, abs(output))
            }
        }

        #expect(worst < 0.0002)
    }

    @Test("A higher beta lags less behind a steady movement")
    func higherBetaLagsLess() {
        let slow = lagAfterOneSecond(beta: 0)
        let fast = lagAfterOneSecond(beta: 4)

        #expect(fast < slow)
    }

    // MARK: - Reset and time

    @Test("reset() forgets the history: the next value passes through")
    func resetForgetsHistory() {
        var filter = makeFilter()
        _ = filter.filter(point(0), at: frame(0))
        _ = filter.filter(point(0), at: frame(1))

        filter.reset()

        #expect(filter.filter(point(1), at: frame(2)) == point(1))
    }

    @Test("reset(to:at:) continues smoothing from the given value")
    func resetToValueContinuesFromIt() {
        var filter = makeFilter()
        filter.reset(to: point(0), at: frame(0))

        let output = filter.filter(point(1), at: frame(1)).x

        #expect(output > 0 && output < 1)
    }

    @Test("A time that doesn't move forward restarts the filter")
    func nonIncreasingTimeRestarts() {
        var filter = makeFilter()
        _ = filter.filter(point(0), at: frame(5))

        #expect(filter.filter(point(1), at: frame(5)) == point(1))
        #expect(filter.filter(point(2), at: frame(4)) == point(2))
    }

    // MARK: - Non-finite input

    @Test("Skips a NaN sample and returns the last output instead")
    func skipsNaNSample() {
        var filter = makeFilter()
        _ = filter.filter(point(0), at: frame(0))
        let last = filter.filter(point(0.01), at: frame(1))

        #expect(filter.filter(point(.nan), at: frame(2)) == last)
    }

    @Test("Skips infinite samples and non-finite times")
    func skipsInfiniteSamplesAndTimes() {
        var filter = makeFilter()
        let last = filter.filter(point(1), at: frame(0))

        #expect(filter.filter(SIMD3(1, .infinity, 1), at: frame(1)) == last)
        #expect(filter.filter(point(2), at: .nan) == last)
        #expect(filter.filter(point(2), at: .infinity) == last)
    }

    @Test("Skipped samples leave no trace: the outputs match a filter that never saw them")
    func skippedSamplesLeaveNoTrace() {
        var clean = makeFilter()
        var disturbed = makeFilter()
        var firstDifferentFrame: Int?

        for index in 0..<120 {
            let input = point(sin(Float(index) / 10))
            if index.isMultiple(of: 10) {
                _ = disturbed.filter(point(.nan), at: frame(index))
                _ = disturbed.filter(SIMD3(0, .infinity, 0), at: frame(index))
                _ = disturbed.filter(input, at: .nan)
            }

            let expected = clean.filter(input, at: frame(index))
            let actual = disturbed.filter(input, at: frame(index))
            if actual != expected, firstDifferentFrame == nil {
                firstDifferentFrame = index
            }
        }

        #expect(firstDifferentFrame == nil)
    }

    @Test("A NaN first sample is handed back and doesn't poison the filter")
    func nanFirstSampleDoesNotPoison() {
        var filter = makeFilter()

        let first = filter.filter(point(.nan), at: frame(0))

        #expect(first.x.isNaN)
        #expect(filter.filter(point(1), at: frame(1)) == point(1))
    }

    @Test("reset(to:) with a NaN value starts over instead of poisoning the filter")
    func resetToNaNStartsOver() {
        var filter = makeFilter()
        filter.reset(to: point(.nan), at: frame(0))

        #expect(filter.filter(point(1), at: frame(1)) == point(1))
    }

    #if compiler(>=6.2) && os(macOS)
    @Test("Stops on a cutoff that isn't positive and finite, or a negative or infinite beta")
    func invalidParametersStop() async {
        await #expect(processExitsWith: .failure) { _ = OneEuroFilter(minCutoff: 0, beta: 4) }
        await #expect(processExitsWith: .failure) { _ = OneEuroFilter(minCutoff: .nan, beta: 4) }
        await #expect(processExitsWith: .failure) { _ = OneEuroFilter(minCutoff: 1, beta: -1) }
        await #expect(processExitsWith: .failure) { _ = OneEuroFilter(minCutoff: 1, beta: .infinity) }
        await #expect(processExitsWith: .failure) { _ = OneEuroFilter(minCutoff: 1, beta: 4, velocityCutoff: 0) }
    }
    #endif
}
