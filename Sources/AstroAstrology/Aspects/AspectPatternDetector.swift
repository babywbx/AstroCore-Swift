import AstroCore

/// Recognises aspect patterns on a grid by matching motifs over its edges. Purely combinatorial —
/// it reads only the grid (no ephemeris). Edges are flattened into an index-keyed adjacency table so
/// the 3/4-body enumeration is pure array indexing; allocation happens only when a pattern is found.
enum AspectPatternDetector {
    static func patterns(in grid: AspectGrid) -> [AspectPattern] {
        let table = Table(grid)
        var patterns: [AspectPattern] = []
        patterns += stelliums(table)
        patterns += triplePatterns(table)
        patterns += quadPatterns(table)
        return deduplicated(patterns)
    }

    // MARK: - Adjacency table (index-keyed, no hashing in the hot loop)

    private struct Table {
        let bodies: [CelestialBody]
        let count: Int
        private let kinds: [AspectKind?]
        private let edges: [Aspect?]

        init(_ grid: AspectGrid) {
            bodies = grid.bodies
            count = grid.bodies.count
            var indexOf: [CelestialBody: Int] = [:]
            for (position, body) in grid.bodies.enumerated() {
                indexOf[body] = position
            }
            var kinds = [AspectKind?](repeating: nil, count: count * count)
            var edges = [Aspect?](repeating: nil, count: count * count)
            for aspect in grid.aspects {
                guard let i = indexOf[aspect.bodyA], let j = indexOf[aspect.bodyB] else { continue }
                kinds[i * count + j] = aspect.kind
                kinds[j * count + i] = aspect.kind
                edges[i * count + j] = aspect
                edges[j * count + i] = aspect
            }
            self.kinds = kinds
            self.edges = edges
        }

        func has(_ i: Int, _ j: Int, _ kind: AspectKind) -> Bool {
            kinds[i * count + j] == kind
        }

        func kind(_ i: Int, _ j: Int) -> AspectKind? {
            kinds[i * count + j]
        }

        func body(_ i: Int) -> CelestialBody {
            bodies[i]
        }

        func aspect(_ i: Int, _ j: Int) -> Aspect? {
            edges[i * count + j]
        }
    }

    private static let caseIndex: [CelestialBody: Int] = {
        var index: [CelestialBody: Int] = [:]
        for (position, body) in CelestialBody.allCases.enumerated() {
            index[body] = position
        }
        return index
    }()

    private static func makePattern(
        _ table: Table, kind: AspectPatternKind, indices: [Int], edges: [(Int, Int)], apex: Int?
    ) -> AspectPattern {
        let bodies = indices.map { table.body($0) }.sorted { (caseIndex[$0] ?? .max) < (caseIndex[$1] ?? .max) }
        return AspectPattern(
            kind: kind,
            bodies: bodies,
            aspects: edges.compactMap { table.aspect($0.0, $0.1) },
            apex: apex.map { table.body($0) }
        )
    }

    private static func deduplicated(_ patterns: [AspectPattern]) -> [AspectPattern] {
        var seen = Set<String>()
        var result: [AspectPattern] = []
        for pattern in patterns {
            let key = "\(pattern.kind.rawValue):" + pattern.bodies.map(\.rawValue).joined(separator: ",")
            if seen.insert(key).inserted { result.append(pattern) }
        }
        return result
    }

    // MARK: - Stellium (maximal conjunction cliques, size ≥ 3)

    private static func stelliums(_ table: Table) -> [AspectPattern] {
        var cliques: [[Int]] = []
        bronKerbosch(reported: [], candidates: Array(0..<table.count), excluded: [], table: table) { clique in
            if clique.count >= 3 { cliques.append(clique) }
        }
        return cliques.map { clique in
            var edges: [(Int, Int)] = []
            for x in 0..<clique.count {
                for y in (x + 1)..<clique.count {
                    edges.append((clique[x], clique[y]))
                }
            }
            return makePattern(table, kind: .stellium, indices: clique, edges: edges, apex: nil)
        }
    }

    private static func bronKerbosch(
        reported: [Int], candidates: [Int], excluded: [Int],
        table: Table, report: ([Int]) -> Void
    ) {
        if candidates.isEmpty, excluded.isEmpty {
            report(reported)
            return
        }
        var candidates = candidates
        var excluded = excluded
        for vertex in candidates {
            let neighbors: (Int) -> Bool = { table.has($0, vertex, .conjunction) }
            bronKerbosch(
                reported: reported + [vertex],
                candidates: candidates.filter(neighbors),
                excluded: excluded.filter(neighbors),
                table: table,
                report: report
            )
            candidates.removeAll { $0 == vertex }
            excluded.append(vertex)
        }
    }

    // MARK: - Three-body patterns

    private static func triplePatterns(_ table: Table) -> [AspectPattern] {
        var patterns: [AspectPattern] = []
        for i in 0..<table.count {
            for j in (i + 1)..<table.count {
                for k in (j + 1)..<table.count {
                    if let pattern = grandTrine(table, i, j, k) { patterns.append(pattern) }
                    if let pattern = focalTriangle(
                        table, i, j, k, baseKind: .opposition, legKind: .square, patternKind: .tSquare
                    ) { patterns.append(pattern) }
                    if let pattern = focalTriangle(
                        table, i, j, k, baseKind: .sextile, legKind: .quincunx, patternKind: .yod
                    ) { patterns.append(pattern) }
                }
            }
        }
        return patterns
    }

    private static func grandTrine(_ table: Table, _ a: Int, _ b: Int, _ c: Int) -> AspectPattern? {
        guard table.has(a, b, .trine), table.has(b, c, .trine), table.has(a, c, .trine) else { return nil }
        return makePattern(table, kind: .grandTrine, indices: [a, b, c], edges: [(a, b), (b, c), (a, c)], apex: nil)
    }

    /// T-Square / Yod share a shape: a `baseKind` pair both joined to a focus by `legKind`.
    private static func focalTriangle(
        _ table: Table, _ a: Int, _ b: Int, _ c: Int,
        baseKind: AspectKind, legKind: AspectKind, patternKind: AspectPatternKind
    ) -> AspectPattern? {
        focalMatch(table, a, b, apex: c, baseKind: baseKind, legKind: legKind, patternKind: patternKind)
            ?? focalMatch(table, a, c, apex: b, baseKind: baseKind, legKind: legKind, patternKind: patternKind)
            ?? focalMatch(table, b, c, apex: a, baseKind: baseKind, legKind: legKind, patternKind: patternKind)
    }

    private static func focalMatch(
        _ table: Table, _ baseA: Int, _ baseB: Int, apex: Int,
        baseKind: AspectKind, legKind: AspectKind, patternKind: AspectPatternKind
    ) -> AspectPattern? {
        guard table.has(baseA, baseB, baseKind),
              table.has(baseA, apex, legKind), table.has(baseB, apex, legKind) else { return nil }
        return makePattern(
            table, kind: patternKind, indices: [baseA, baseB, apex],
            edges: [(baseA, baseB), (baseA, apex), (baseB, apex)], apex: apex
        )
    }

    // MARK: - Four-body patterns

    private static func quadPatterns(_ table: Table) -> [AspectPattern] {
        var patterns: [AspectPattern] = []
        for i in 0..<table.count {
            for j in (i + 1)..<table.count {
                for k in (j + 1)..<table.count {
                    for l in (k + 1)..<table.count {
                        if let pattern = grandCross(table, i, j, k, l) { patterns.append(pattern) }
                        if let pattern = mysticRectangle(table, i, j, k, l) { patterns.append(pattern) }
                        if let pattern = kite(table, i, j, k, l) { patterns.append(pattern) }
                    }
                }
            }
        }
        return patterns
    }

    private static func grandCross(_ table: Table, _ a: Int, _ b: Int, _ c: Int, _ d: Int) -> AspectPattern? {
        grandCrossMatch(table, a, b, c, d)
            ?? grandCrossMatch(table, a, c, b, d)
            ?? grandCrossMatch(table, a, d, b, c)
    }

    /// (o1a-o1b) and (o2a-o2b) are the diagonals (oppositions); the four cross edges are squares.
    private static func grandCrossMatch(
        _ table: Table, _ o1a: Int, _ o1b: Int, _ o2a: Int, _ o2b: Int
    ) -> AspectPattern? {
        guard table.has(o1a, o1b, .opposition), table.has(o2a, o2b, .opposition),
              table.has(o1a, o2a, .square), table.has(o1a, o2b, .square),
              table.has(o1b, o2a, .square), table.has(o1b, o2b, .square) else { return nil }
        return makePattern(
            table, kind: .grandCross, indices: [o1a, o1b, o2a, o2b],
            edges: [(o1a, o1b), (o2a, o2b), (o1a, o2a), (o1a, o2b), (o1b, o2a), (o1b, o2b)], apex: nil
        )
    }

    private static func mysticRectangle(_ table: Table, _ a: Int, _ b: Int, _ c: Int, _ d: Int) -> AspectPattern? {
        mysticRectangleMatch(table, a, b, c, d)
            ?? mysticRectangleMatch(table, a, c, b, d)
            ?? mysticRectangleMatch(table, a, d, b, c)
    }

    /// Diagonals (d1a-d1b) and (d2a-d2b) are oppositions; the four sides are two trines + two sextiles.
    private static func mysticRectangleMatch(
        _ table: Table, _ d1a: Int, _ d1b: Int, _ d2a: Int, _ d2b: Int
    ) -> AspectPattern? {
        guard table.has(d1a, d1b, .opposition), table.has(d2a, d2b, .opposition) else { return nil }
        let sideAB = table.kind(d1a, d2a)
        let sideBC = table.kind(d2a, d1b)
        let sideCD = table.kind(d1b, d2b)
        let sideDA = table.kind(d2b, d1a)
        guard let sideAB, let sideBC, sideAB == sideCD, sideBC == sideDA,
              Set([sideAB, sideBC]) == [.trine, .sextile] else { return nil }
        return makePattern(
            table, kind: .mysticRectangle, indices: [d1a, d1b, d2a, d2b],
            edges: [(d1a, d1b), (d2a, d2b), (d1a, d2a), (d2a, d1b), (d1b, d2b), (d2b, d1a)], apex: nil
        )
    }

    private static func kite(_ table: Table, _ a: Int, _ b: Int, _ c: Int, _ d: Int) -> AspectPattern? {
        kiteMatch(table, tail: a, b, c, d)
            ?? kiteMatch(table, tail: b, a, c, d)
            ?? kiteMatch(table, tail: c, a, b, d)
            ?? kiteMatch(table, tail: d, a, b, c)
    }

    /// Grand trine (x, y, z) with `tail` opposed to one vertex and sextile the other two.
    private static func kiteMatch(_ table: Table, tail: Int, _ x: Int, _ y: Int, _ z: Int) -> AspectPattern? {
        guard table.has(x, y, .trine), table.has(y, z, .trine), table.has(x, z, .trine) else { return nil }
        var oppositions = 0
        var sextiles = 0
        for vertex in [x, y, z] {
            if table.has(tail, vertex, .opposition) {
                oppositions += 1
            } else if table.has(tail, vertex, .sextile) {
                sextiles += 1
            }
        }
        guard oppositions == 1, sextiles == 2 else { return nil }
        return makePattern(
            table, kind: .kite, indices: [tail, x, y, z],
            edges: [(x, y), (y, z), (x, z), (tail, x), (tail, y), (tail, z)], apex: nil
        )
    }
}
