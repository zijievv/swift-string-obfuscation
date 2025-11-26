import SwiftSyntax

extension Obfuscation {
    // Nibble swap -> XOR -> Rotate right 4 -> XOR
    enum C: Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8] {
            let bytes = text.utf8
            return bytes.map { b in
                var x = (b & 0xF0) >> 4 | (b & 0x0F) << 4
                x ^= key
                x = (x &>> 4) | (x &<< 4)  // rotate right 4
                return x ^ 0xA5
            }
        }

        static func decrypt(_ c: [UInt8], _ k: UInt8) -> String {
            let bytes = c.map { _c -> UInt8 in
                var x = _c ^ 0xA5
                x = (x &<< 4) | (x &>> 4)  // rotate left 4
                x ^= k
                return (x & 0xF0) >> 4 | (x & 0x0F) << 4
            }
            return String(decoding: bytes, as: UTF8.self)
        }

        static func decryptFuncDecl(funcName: TokenSyntax) -> DeclSyntax {
            """
            @inline(__always)
            func \(funcName)(_ c: [UInt8], _ k: UInt8) -> String {
                let bytes = c.map { _c -> UInt8 in
                    var x = _c ^ 0xA5
                    x = (x &<< 4) | (x &>> 4)
                    x ^= k
                    return (x & 0xF0) >> 4 | (x & 0x0F) << 4
                }
                return String(decoding: bytes, as: UTF8.self)
            }
            """
        }
    }
}
