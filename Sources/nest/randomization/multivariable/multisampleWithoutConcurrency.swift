// public func sample<InputType: Randomizable, OutputType: Numeric>(
//     _ nSamples: Int, generateRandomValues: @escaping () async -> [InputType] 
// ) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
//     InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
//     var result = [[InputType]]()
//     for _ in 0..<nSamples { // This loop cannot be rewritten as an array generator because of concurrency
//         result.append(
//             await generateRandomValues()
//         )
//     }
//     return result
// }

public func sample<InputType: Randomizable, OutputType: Numeric, GeneratorType: SeedableRandomNumberGenerator>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: inout GeneratorType
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    var result = [[InputType]]()
    for _ in 0..<nSamples { // This loop cannot be rewritten as an array generator because of concurrency
        result.append(
            await randomize(
                getProbability,
                from: from,
                to: to,
                precision: precision,
                kind: kind,
                generatorKind: generatorKind,
                generator: &generator
            )
        )
    }
    return result
}

public func sample<InputType: Randomizable, OutputType: Numeric>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    seed: Int
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    var generator = DefaultSeedableRandomNumberGenerator(seed)
    return await sample(
        getProbability, nSamples,
        from: from, to: to, precision: precision, kind: kind, generatorKind: generatorKind, generator: &generator
    )
}

public func sample<InputType: Randomizable, OutputType: Numeric>(
    _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int,
    from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil
) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    var result = [[InputType]]()
    for _ in 0..<nSamples { // This loop cannot be rewritten as an array generator because of concurrency
        result.append(
            await randomize(
                getProbability,
                from: from,
                to: to,
                precision: precision,
                kind: kind,
                generatorKind: generatorKind
            )
        )
    }
    return result
}