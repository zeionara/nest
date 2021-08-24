public protocol Addable {
    static func +(lhs: Self, rhs: Self) -> Self
}

public struct nest {
    public private(set) var text = "Hello, World!"

    public init() {
    }

    public func integrate<InputType: Addable, OutputType: Addable>(getValue: (InputType) -> OutputType, from firstValue: InputType, to lastValue: InputType) -> OutputType {
        return getValue(firstValue) + getValue(lastValue)
    }
}
