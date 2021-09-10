private func sample<InputType: Randomizable, OutputType: Numeric>(
    _ nSamples: Int, nParts: Int, generateSamples: @escaping  ((Int, Int)) async -> [[InputType]]
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    assert(nParts > 1)

    let nSamplesPerPart = nSamples / nParts
    let inputs = Array(repeating: nSamplesPerPart, count: nParts - 1) + [nSamples - nSamplesPerPart * nParts]

    return Array.chain(
        await concurrentMap(Array(inputs.enumerated()), handler: generateSamples)
    )
}


public func sample<InputType: Randomizable, OutputType: Numeric, GeneratorType: SeedableRandomNumberGenerator>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int, nParts: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    seed: Int, initGenerator: @escaping (Int) -> GeneratorType
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    await sample(nSamples, nParts: nParts){ (i: Int, nSamples: Int) in
        var generator = initGenerator(seed + i)
        return await sample(
            getProbability,
            nSamples,
            from: from,
            to: to,
            precision: precision,
            generator: &generator
        )
    }
}

public func sample<InputType: Randomizable, OutputType: Numeric>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int, nParts: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    seed: Int
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    return await sample(
        getProbability, nSamples, nParts: nParts,
        from: from, to: to, precision: precision, kind: kind, generatorKind: generatorKind, seed: seed
    ) {
        return DefaultSeedableRandomNumberGenerator($0)
    }
}

public func sample<InputType: Randomizable, OutputType: Numeric>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int, nParts: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    await sample(nSamples, nParts: nParts) { (i: Int, nSamples: Int) in
        await sample(
            getProbability,
            nSamples,
            from: from,
            to: to,
            precision: precision
        )
    }
}
