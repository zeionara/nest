public func randomizeCoordinate<InputType: Randomizable, OutputType: Numeric, GeneratorType: SeedableRandomNumberGenerator>(
    _ getProbability: ([InputType]) -> OutputType,
    from firstValue: [InputType], to lastValue: [InputType], precision nIntervals: Int = 10, kind: IntegralKind = .right, generatorKind: GeneratorKind = .ceil,
    generator: inout GeneratorType
) async -> InputType where InputType: Integrable, InputType.IntervalValueType == InputType, InputType.ResultType == OutputType,
    InputType == InputType.SampledValueType, OutputType == InputType.ProbabilityType {
    if firstValue.count == 1 {
        func getValueFixed(_ x: InputType) -> OutputType {
            return getProbability([x])
        }

        return await InputType.random(
            getValueFixed,
            from: firstValue.first!,
            to: lastValue.first!,
            precision: nIntervals,
            kind: kind,
            generatorKind: generatorKind,
            generator: &generator
        )
    } else {
        func getValueFixed(_ firstDimensionValue: InputType) async -> OutputType {
            func getValueOnShortenedArray(_ lastDimensionValues: [InputType]) -> OutputType {
                return getProbability([firstDimensionValue] + lastDimensionValues)
            }
            
            return await integrate(
                getValueOnShortenedArray,
                from: Array(firstValue.dropFirst()),
                to: Array(lastValue.dropFirst()),
                precision: nIntervals,
                kind: kind
            )
        }
        
        return await InputType.random(
            getValueFixed,
            from: firstValue.first!,
            to: lastValue.first!,
            precision: nIntervals,
            kind: kind,
            generatorKind: generatorKind,
            generator: &generator
        )
    }
}
