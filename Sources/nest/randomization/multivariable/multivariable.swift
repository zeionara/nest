public func randomize<InputType: Randomizable, OutputType: Numeric, GeneratorType: SeedableRandomNumberGenerator>(
    _ getProbability: ([InputType]) -> OutputType,
    from firstValue: [InputType], to lastValue: [InputType], precision nIntervals: Int = 10, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: inout GeneratorType
) async -> [InputType] where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    var currentCoordinates = [InputType]()
    for i in 0..<firstValue.count {
        func getValueFixed(_ args: [InputType]) -> OutputType {
            return getProbability(currentCoordinates + args)
        }

        let normalizationCoefficient = await integrate(
            getValueFixed,
            from: Array(firstValue[i..<firstValue.count]),
            to: Array(lastValue[i..<firstValue.count]),
            precision: nIntervals,
            kind: kind
        )

        let newCoordinate = await randomizeCoordinate(
            { args in 
                return InputType.normalizeProbability(
                    getValueFixed(args),
                    normalizationCoefficient
                )
            },
            from: Array(firstValue[i..<firstValue.count]),
            to: Array(lastValue[i..<firstValue.count]),
            precision: nIntervals,
            kind: kind,
            generatorKind: generatorKind,
            generator: &generator
        )

        currentCoordinates.append(newCoordinate)
    }

    return currentCoordinates
}
