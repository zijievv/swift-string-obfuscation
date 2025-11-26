import SwiftSyntax

extension Obfuscation {
    // XOR -> Rotate left 3 -> Nibble swap
    enum A: Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8] {
            let bytes = Array(text.utf8)
            var secret: [UInt8] = []
            secret.reserveCapacity(bytes.count)
            for b in bytes {
                var x = b ^ key  // XOR
                x = (x &<< 3) | (x &>> 5)  // Rotate left by 3
                x = (x & 0xF0) >> 4 | (x & 0x0F) << 4  // Swap nibbles
                secret.append(x)
            }
            return secret
        }

        static func decrypt(_ c: [UInt8], _ k: UInt8) -> String {
            var b: [UInt8] = []
            b.reserveCapacity(c.count)
            for _c in c {
                var x = (_c & 0xF0) >> 4 | (_c & 0x0F) << 4
                x = (x &>> 3) | (x &<< 5)
                x = x ^ k
                b.append(x)
            }
            return String(decoding: b, as: UTF8.self)
        }

        static func decryptFuncDecl(funcName: TokenSyntax) -> DeclSyntax {
            """
            @inline(__always)
            func \(funcName)(_ c: [UInt8], _ k: UInt8) -> String {
                var b: [UInt8] = []
                b.reserveCapacity(c.count)
                for _c in c {
                    var x = (_c & 0xF0) >> 4 | (_c & 0x0F) << 4
                    x = (x &>> 3) | (x &<< 5)
                    x = x ^ k
                    b.append(x)
                }
                return String(decoding: b, as: UTF8.self)
            }
            """
        }
    }
}
