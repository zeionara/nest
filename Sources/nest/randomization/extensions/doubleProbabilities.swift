import PcgRandom

extension Double: Randomizable {
    // public typealias SampledValueType = Double

    // public static func random_(
    //     _ getValue: (Double) async -> Double,
    //     from firstValue: Double,
    //     to lastValue: Double,
    //     precision nIntervals: Int = 10,
    //     kind: IntegralKind = .right,
    //     generatorKind: GeneratorKind = .ceil
    // ) async -> Double {
    //     let step = abs(lastValue - firstValue) / Double(nIntervals)
        
    //     let result = await _random(
    //         getValue, from: firstValue, to: lastValue, step: step, zero: 0.0,
    //         base: generatorKind == .ceil ? Double.random(in: 0...1) : Double.random(in: 0..<1),
    //         generatorKind: generatorKind, computeSquare: makeIntegratingClosure(step: step, kind: kind)
    //     ) { (leftBound: Double, rightBound: Double) in
    //         return (leftBound + rightBound) / 2.0
    //     }

    //     return result
    // }

    public static func normalizeProbability(_ probability: Self, _ normalizationCoefficient: Self) -> Self {
        return probability / normalizationCoefficient
    }
}

extension Double {
    public static func random(
        _ getValue: (Double) async -> Double,
        from firstValue: Double,
        to lastValue: Double,
        precision nIntervals: Int = 10,
        kind: IntegralKind = .right,
        generatorKind: GeneratorKind = .ceil,
        generator: inout Pcg64Random
    ) async -> Double {
        let step = abs(lastValue - firstValue) / Double(nIntervals)
        
        // if var unwrappedGenerator = generator {
        let result = await _random(
            getValue, from: firstValue, to: lastValue, step: step, zero: 0.0,
            base: generatorKind == .ceil ? Double.random(in: 0...1, using: &generator) : Double.random(in: 0..<1, using: &generator), 
            generatorKind: generatorKind, computeSquare: makeIntegratingClosure(step: step, kind: kind)
        ) { (leftBound: Double, rightBound: Double) in
            return (leftBound + rightBound) / 2.0
        }
        return result
        // }
        // if let unwrappedSeed = seed {
        //     print("Passing seed without a generator. Using Pcg64Random as a default generator")
        //     let defaultGenerator = Pcg64Random(seed: UInt64(unwrappedSeed))
        //     return await random(getValue, from: firstValue, to: lastValue, precision: nIntervals, kind: kind, generatorKind: generatorKind, generator: defaultGenerator)
        // }
        // return await random_(getValue, from: firstValue, to: lastValue, precision: nIntervals, kind: kind, generatorKind: generatorKind)
    }
}
