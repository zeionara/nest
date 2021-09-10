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

// public func sample<InputType: Randomizable, OutputType: Numeric>(
//     _ getProbability: @escaping ([InputType]) -> OutputType, _ nSamples: Int,
//     from: [InputType], to: [InputType], precision: Int = 10000, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
//     seed: Int
// ) async -> [[InputType]] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType {
//     var generator = makeDefaultSeedableRandomNumberGenerator(seed)
//     return sample(getProbability, nSamples: nSamples, from: from, to: to, precision: precision, kind: kind, generatorKind: generatorKind, generator: &generator)
// }