public protocol Addable { // TODO: Eliminate SIGSGV error
    static func +(lhs: Self, rhs: Self) -> Self
}

extension Double: Addable {
    static public func +(lhs: Double, rhs: Double) -> Double {
        return lhs + rhs
    }
}
