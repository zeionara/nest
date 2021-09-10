public func sample<InputType: Randomizable, OutputType: Numeric, GeneratorType: SeedableRandomNumberGenerator>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int, nParts: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    seed: Int, initGenerator: @escaping (Int) -> GeneratorType
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    assert(nParts > 1)

    let nSamplesPerPart = nSamples / nParts
    let inputs = Array(repeating: nSamplesPerPart, count: nParts - 1) + [nSamples - nSamplesPerPart * nParts]

    return Array.chain(
        await concurrentMap(
            Array(inputs.enumerated())
        ) { (i: Int, nSamples: Int) in
            var generator = initGenerator(seed + i) // Pcg64Random(seed: UInt64(seed + i))
            return await sample(
                getProbability,
                nSamples,
                from: from,
                to: to,
                precision: precision,
                generator: &generator
            )
        }
    )
}
