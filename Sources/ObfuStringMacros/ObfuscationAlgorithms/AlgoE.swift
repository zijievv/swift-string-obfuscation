import SwiftSyntax

extension Obfuscation {
    // XOR table -> Rotate left 1 -> XOR key
    enum E: Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8] {
            let table: [UInt8] = [
                0x13, 0x7A, 0xC1, 0x5F, 0x92, 0x0E, 0xB4, 0x68,
                0x2F, 0xD9, 0x87, 0x3B, 0x4C, 0xA3, 0x1D, 0xFE,
            ]
            return text.utf8.enumerated().map { i, b in
                var x = b ^ table[i & 0x0F]
                x = (x &<< 1) | (x &>> 7)
                return x ^ key
            }
        }

        static func decrypt(_ c: [UInt8], _ k: UInt8) -> String {
            let t: [UInt8] = [
                0x13, 0x7A, 0xC1, 0x5F, 0x92, 0x0E, 0xB4, 0x68,
                0x2F, 0xD9, 0x87, 0x3B, 0x4C, 0xA3, 0x1D, 0xFE,
            ]
            let bs = c.enumerated().map { i, _c in
                var x = _c ^ k
                x = (x &>> 1) | (x &<< 7)
                return x ^ t[i & 0x0F]
            }
            return String(decoding: bs, as: UTF8.self)
        }

        static func decryptFuncDecl(funcName: TokenSyntax) -> DeclSyntax {
            """
            @inline(__always)
            func \(funcName)(_ c: [UInt8], _ k: UInt8) -> String {
                let t: [UInt8] = [
                    0x13, 0x7A, 0xC1, 0x5F, 0x92, 0x0E, 0xB4, 0x68,
                    0x2F, 0xD9, 0x87, 0x3B, 0x4C, 0xA3, 0x1D, 0xFE
                ]
                let bs = c.enumerated().map { i, _c in
                    var x = _c ^ k
                    x = (x &>> 1) | (x &<< 7)
                    return x ^ t[i & 0x0F]
                }
                return String(decoding: bs, as: UTF8.self)
            }
            """
        }
    }
}
