import SwiftSyntax

extension Obfuscation {
    // XOR -> Add constant -> Rotate right 2
    enum B: Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8] {
            let bytes = text.utf8
            return bytes.map { b in
                var x = b ^ key
                x &+= 0x3D
                return (x &>> 2) | (x &<< 6)  // rotate right 2
            }
        }

        static func decrypt(_ c: [UInt8], _ k: UInt8) -> String {
            let bytes = c.map { _c -> UInt8 in
                var x = (_c &<< 2) | (_c &>> 6)  // rotate left 2
                x &-= 0x3D
                return x ^ k
            }
            return String(decoding: bytes, as: UTF8.self)
        }

        static func decryptFuncDecl(funcName: TokenSyntax) -> DeclSyntax {
            """
            @inline(__always)
            func \(funcName)(_ c: [UInt8], _ k: UInt8) -> String {
                let bytes = c.map { _c -> UInt8 in
                    var x = (_c &<< 2) | (_c &>> 6)
                    x &-= 0x3D
                    return x ^ k
                }
                return String(decoding: bytes, as: UTF8.self)
            }
            """
        }
    }
}
