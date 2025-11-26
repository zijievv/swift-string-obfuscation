import SwiftSyntax

extension Obfuscation {
    // Bit reverse -> XOR -> Add constant
    enum D: Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8] {
            text.utf8.map { b in
                var x = bitReverse(b)
                x ^= key
                x &+= 0x6B
                return x
            }
        }

        private static func bitReverse(_ v: UInt8) -> UInt8 {
            var x = v
            x = ((x & 0xF0) >> 4) | ((x & 0x0F) << 4)
            x = ((x & 0xCC) >> 2) | ((x & 0x33) << 2)
            x = ((x & 0xAA) >> 1) | ((x & 0x55) << 1)
            return x
        }

        static func decrypt(_ c: [UInt8], _ k: UInt8) -> String {
            @inline(__always)
            func br(_ v: UInt8) -> UInt8 {
                var x = v
                x = ((x & 0xF0) >> 4) | ((x & 0x0F) << 4)
                x = ((x & 0xCC) >> 2) | ((x & 0x33) << 2)
                x = ((x & 0xAA) >> 1) | ((x & 0x55) << 1)
                return x
            }
            let bytes = c.map { _c -> UInt8 in
                var x = _c &- 0x6B
                x ^= k
                return br(x)
            }
            return String(decoding: bytes, as: UTF8.self)
        }

        static func decryptFuncDecl(funcName: TokenSyntax) -> DeclSyntax {
            """
            @inline(__always)
            func \(funcName)(_ c: [UInt8], _ k: UInt8) -> String {
                @inline(__always)
                func br(_ v: UInt8) -> UInt8 {
                    var x = v
                    x = ((x & 0xF0) >> 4) | ((x & 0x0F) << 4)
                    x = ((x & 0xCC) >> 2) | ((x & 0x33) << 2)
                    x = ((x & 0xAA) >> 1) | ((x & 0x55) << 1)
                    return x
                }
                let bytes = c.map { _c -> UInt8 in
                    var x = _c &- 0x6B
                    x ^= k
                    return br(x)
                }
                return String(decoding: bytes, as: UTF8.self)
            }
            """
        }
    }
}
