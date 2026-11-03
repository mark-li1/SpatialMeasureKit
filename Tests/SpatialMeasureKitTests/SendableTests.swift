import Testing
import Foundation
import SpatialMeasureKit

private enum SharedTools {
    static let distance = DistanceCalculator()
    static let area = AreaCalculator()
    static let angle = AngleCalculator()
    static let height = HeightCalculator()
    static let level = LevelCalculator()
    static let snapper = PointSnapper()
    static let triangulator = PolygonTriangulator()
    static let formatter = ValueFormatter(locale: Locale(identifier: "en_US"))
    static let filter = OneEuroFilter(minCutoff: 1, beta: 4)
}

@Suite("Sendable")
struct SendableTests {
    private func requireSendable<T: Sendable>(_: T.Type) {}

    @Test("Every public tool can live in a static let, which Swift 6 allows only for Sendable types")
    func toolsWorkAsStaticLets() {
        #expect(SharedTools.distance.distance(from: .zero, to: SIMD3(1, 0, 0)) == 1)
        #expect(SharedTools.formatter.formatAngle(degrees: 90)?.text == "90°")
    }

    @Test("Every public value type can cross between threads")
    func valueTypesAreSendable() {
        requireSendable(InscribedCircle.self)
        requireSendable(Tilt.self)
        requireSendable(Roll.self)
        requireSendable(PolygonTriangulator.Triangulation.self)
        requireSendable(PolygonTriangulator.Triangle.self)
        requireSendable(UnitSystem.self)
        requireSendable(FormattedLength.self)
        requireSendable(FormattedArea.self)
        requireSendable(FormattedAngle.self)
    }
}
