# SpatialMeasureKit

The math behind an AR tape measure, in a small Swift package. Measure distances, areas,
angles and heights from 3D points, snap to points you already placed, smooth a shaky aim,
and show the results in metric or imperial.

It grew out of an AR measuring app for iPhone. It's plain Swift and `simd` with no ARKit
inside, so you can use it outside AR too, and test it on a Mac without an iPhone.

## What's inside

- `DistanceCalculator`: straight lines, path lengths and perimeters
- `AreaCalculator`: area, center and a good spot for a label, even when the outline crosses itself
- `AngleCalculator`: the angle between two lines
- `HeightCalculator`: the height above a floor point, from where the camera aims
- `LevelCalculator`: a spirit level, lying flat or held upright
- `PointSnapper`: locks the aim onto nearby points
- `OneEuroFilter`: smooths a shaky aim without making it lag
- `PolygonTriangulator`: cuts an outline into triangles to draw it filled
- `ValueFormatter`: `12.00 m²`, `45' 11⅛"` or `37°`, in the user's language

## Installation

In Xcode, choose File › Add Package Dependencies… and enter the URL below, or add it to
`Package.swift`:

```swift
.package(url: "https://github.com/mark-li1/SpatialMeasureKit.git", from: "0.1.0")
```

## Example

```swift
import SpatialMeasureKit

let room: [SIMD3<Float>] = [[0, 0, 0], [4, 0, 0], [4, 0, 3], [0, 0, 3]]

let area = AreaCalculator().area(of: room)               // 12.0
let perimeter = DistanceCalculator().perimeter(of: room) // 14.0

let formatter = ValueFormatter()
formatter.formatArea(squareMeters: area, system: .metric)?.text     // 12.00 m²
formatter.formatLength(meters: perimeter, system: .imperial)?.text  // 45' 11⅛"
```

All positions are in meters.

## Requirements

iOS 15, macOS 12, tvOS 15, watchOS 8 or visionOS 1, with Swift 6.0 (Xcode 16) or later.

## Author

mark-li1

## License

MIT, see [LICENSE](LICENSE). Finding a spot for a label uses code adapted from Mapbox's
[polylabel](https://github.com/mapbox/polylabel) (ISC, see [NOTICE](NOTICE)). Smoothing uses
the 1€ filter by Casiez, Roussel and Vogel (CHI 2012).
