import PcgRandom

public protocol SeedableRandomNumberGenerator: RandomNumberGenerator {
    init (_ seed: Int)
}

// extension Pcg64Random: SeedableRandomNumberGenerator {
//     public static func fromSeed(_ seed: Int) -> SeedableRandomNumberGenerator {
//         return Pcg64Random(seed: UInt64(seed))
//     }
// }

// public func makeDefaultSeedableRandomNumberGenerator<GeneratorType: SeedableRandomNumberGenerator>(_ seed: Int) -> GeneratorType {
//     return DefaultSeedableRandomNumberGenerator(seed)
// }

public class DefaultSeedableRandomNumberGenerator: SeedableRandomNumberGenerator {
    private var generator: Pcg64Random
    
    public required init(_ seed: Int) {
        generator = Pcg64Random(seed: UInt64(seed))
    }

    public func next() -> UInt64 {
        return generator.next()
    }
}
