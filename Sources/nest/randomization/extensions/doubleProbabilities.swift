extension Double: Randomizable {
    public static func random(
        _ getValue: (Double) async -> Double,
        from firstValue: Double,
        to lastValue: Double,
        precision nIntervals: Int = 10,
        kind: IntegralKind = .right,
        generatorKind: GeneratorKind = .ceil
    ) async -> Double {
        let step = abs(lastValue - firstValue) / Double(nIntervals)
        
        let result = await _random(
            getValue, from: firstValue, to: lastValue, step: step, zero: 0.0,
            base: generatorKind == .ceil ? Double.random(in: 0...1) : Double.random(in: 0..<1),
            generatorKind: generatorKind, computeSquare: makeIntegratingClosure(step: step, kind: kind)
        ) { (leftBound: Double, rightBound: Double) in
            return (leftBound + rightBound) / 2.0
        }

        return result
    }
}