import PcgRandom

public protocol SeedableRandomNumberGenerator: RandomNumberGenerator {
    static func fromSeed(_ seed: Int) -> Self
}

extension Pcg64Random: SeedableRandomNumberGenerator {
    public static func fromSeed(_ seed: Int) -> Self {
        return Pcg64Random(seed: UInt64(seed)) as! Self
    }
}

// public func makeDefaultSeedableRandomNumberGenerator(_ seed: Int) -> SeedableRandomNumberGenerator {
//     return Pcg64Random(seed)
// }
