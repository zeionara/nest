public func integrate<InputType: Numeric, OutputType: Numeric>(_ getValue: (InputType) -> OutputType, from firstValue: InputType, to lastValue: InputType) -> OutputType {
    return getValue(firstValue) + getValue(lastValue)
}
