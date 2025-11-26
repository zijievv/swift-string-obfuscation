import SwiftSyntax

extension Obfuscation {
    // Bit shuffle -> XOR -> Rotate right 3
    enum F: Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8] {
            text.utf8.map { b in
                var x = shuffleBits(b)
                x ^= key
                return (x &>> 3) | (x &<< 5)
            }
        }

        private static func shuffleBits(_ v: UInt8) -> UInt8 {
            // A small reversible permute of bits:
            let a = (v & 0b11001100) >> 2 | (v & 0b00110011) << 2
            // swap adjacent bits
            let b = (a & 0b10101010) >> 1 | (a & 0b01010101) << 1
            return b
        }

        static func decrypt(_ c: [UInt8], _ k: UInt8) -> String {
            let bs = c.map { _c -> UInt8 in
                var x = (_c &<< 3) | (_c &>> 5)
                x ^= k
                let a = (x & 0b10101010) >> 1 | (x & 0b01010101) << 1
                return (a & 0b11001100) >> 2 | (a & 0b00110011) << 2
            }
            return String(decoding: bs, as: UTF8.self)
        }

        static func decryptFuncDecl(funcName: TokenSyntax) -> DeclSyntax {
            """
            @inline(__always)
            func \(funcName)(_ c: [UInt8], _ k: UInt8) -> String {
                let bs = c.map { _c -> UInt8 in
                    var x = (_c &<< 3) | (_c &>> 5)
                    x ^= k
                    let a = (x & 0b10101010) >> 1 | (x & 0b01010101) << 1
                    return (a & 0b11001100) >> 2 | (a & 0b00110011) << 2
                }
                return String(decoding: bs, as: UTF8.self)
            }
            """
        }
    }
}
