import simd

/// The point inside the closed outline `polygon` farthest from every one of its segments, and that
/// distance, found with the polylabel algorithm (Agafonkin, 2016) to within `precision`. Inside
/// means a nonzero winding number. Among points within `precision` of the farthest, returns the
/// one nearest `preferred`, so near-ties (a rectangle's whole middle line) resolve to one stable
/// point. `nil` for degenerate input or when no inside point is found.
func poleOfInaccessibility(
    of polygon: [SIMD2<Float>],
    precision: Float,
    preferring preferred: SIMD2<Float>
) -> (center: SIMD2<Float>, distance: Float)? {
    guard polygon.count >= 3,
          let minX = polygon.map(\.x).min(), let maxX = polygon.map(\.x).max(),
          let minY = polygon.map(\.y).min(), let maxY = polygon.map(\.y).max()
    else { return nil }
    let cellSize = min(maxX - minX, maxY - minY)
    guard cellSize > .ulpOfOne else { return nil }

    func cell(at center: SIMD2<Float>, halfSize: Float) -> Cell {
        Cell(center: center, halfSize: halfSize, distance: signedDistance(from: center, to: polygon))
    }

    func quarters(of parent: Cell) -> [Cell] {
        let half = parent.halfSize / 2
        return [SIMD2<Float>(-half, -half), SIMD2(half, -half), SIMD2(-half, half), SIMD2(half, half)]
            .map { cell(at: parent.center + $0, halfSize: half) }
    }

    var grid: [Cell] = []
    var x = minX
    while x < maxX {
        var y = minY
        while y < maxY {
            grid.append(cell(at: SIMD2(x + cellSize / 2, y + cellSize / 2), halfSize: cellSize / 2))
            y += cellSize
        }
        x += cellSize
    }

    let vertexAverage = cell(at: polygon.reduce(SIMD2<Float>.zero, +) / Float(polygon.count), halfSize: 0)
    let boxCenter = cell(at: SIMD2((minX + maxX) / 2, (minY + maxY) / 2), halfSize: 0)
    var best = boxCenter.distance > vertexAverage.distance ? boxCenter : vertexAverage

    var widestFirst = CellQueue()
    grid.forEach { widestFirst.push($0, priority: $0.potential) }
    while let current = widestFirst.pop() {
        if current.distance > best.distance {
            best = current
        }
        guard current.potential - best.distance > precision else { continue }
        quarters(of: current).forEach { widestFirst.push($0, priority: $0.potential) }
    }
    guard best.distance > 0 else { return nil }

    let enoughRoom = best.distance - precision
    var chosen = best
    var chosenGap = simd_distance(best.center, preferred)
    var nearestFirst = CellQueue()
    grid.forEach { nearestFirst.push($0, priority: -$0.minimumGap(to: preferred)) }
    while let current = nearestFirst.pop() {
        if current.minimumGap(to: preferred) >= chosenGap - precision { break }
        guard current.potential >= enoughRoom else { continue }
        let gap = simd_distance(current.center, preferred)
        if current.distance >= enoughRoom, gap < chosenGap {
            chosen = current
            chosenGap = gap
        }
        guard current.halfSize > precision else { continue }
        quarters(of: current).forEach { nearestFirst.push($0, priority: -$0.minimumGap(to: preferred)) }
    }

    return (chosen.center, chosen.distance)
}

private func signedDistance(from point: SIMD2<Float>, to polygon: [SIMD2<Float>]) -> Float {
    var nearest = Float.greatestFiniteMagnitude
    for i in polygon.indices {
        nearest = min(nearest, distance(from: point, toSegmentFrom: polygon[i], to: polygon[(i + 1) % polygon.count]))
    }
    return windingNumber(of: point, around: polygon) != 0 ? nearest : -nearest
}

private struct Cell {
    let center: SIMD2<Float>
    let halfSize: Float
    let distance: Float

    var potential: Float {
        distance + halfSize * Float(2).squareRoot()
    }

    func minimumGap(to point: SIMD2<Float>) -> Float {
        max(0, simd_distance(center, point) - halfSize * Float(2).squareRoot())
    }
}

private struct CellQueue {
    private var entries: [(cell: Cell, priority: Float)] = []

    mutating func push(_ cell: Cell, priority: Float) {
        entries.append((cell, priority))
        var child = entries.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard entries[child].priority > entries[parent].priority else { break }
            entries.swapAt(child, parent)
            child = parent
        }
    }

    mutating func pop() -> Cell? {
        guard !entries.isEmpty else { return nil }
        entries.swapAt(0, entries.count - 1)
        let top = entries.removeLast().cell
        var parent = 0
        while true {
            let left = 2 * parent + 1
            let right = left + 1
            var largest = parent
            if left < entries.count, entries[left].priority > entries[largest].priority { largest = left }
            if right < entries.count, entries[right].priority > entries[largest].priority { largest = right }
            guard largest != parent else { break }
            entries.swapAt(parent, largest)
            parent = largest
        }
        return top
    }
}
