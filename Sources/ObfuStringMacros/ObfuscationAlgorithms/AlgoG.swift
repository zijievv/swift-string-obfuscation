import SwiftSyntax

extension Obfuscation {
    // Add constant -> Bit reverse -> XOR(high mask) -> Rotate left 1 -> XOR(low mask)
    enum G: Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8] {
            let highMask: UInt8 = (key & 0xF0)  // high 4 bits
            let lowMask: UInt8 = (key & 0x0F) &* 0x11  // low 4 bits expanded into a repeated 4-bit pattern
            return text.utf8.map { b in
                var x = b
                // Step 1: add constant (reversible by subtracting the same constant)
                x &+= 0x3D
                // Step 2: bit reverse (reversible by reversing again)
                x = bitReverse(x)
                // Step 3: XOR with high-bit mask (reversible by XOR again)
                x ^= highMask
                // Step 4: rotate left 1 bit (reversible by rotating right 1 bit)
                x = (x &<< 1) | (x &>> 7)
                // Step 5: XOR with low-bit mask (reversible by XOR again)
                x ^= lowMask
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
            let highMask: UInt8 = (k & 0xF0)
            let lowMask: UInt8 = (k & 0x0F) &* 0x11
            let bytes = c.map { _c -> UInt8 in
                var x = _c
                // Reverse Step 5: XOR with the same lowMask
                x ^= lowMask
                // Reverse Step 4: rotate right 1 bit
                x = (x &>> 1) | (x &<< 7)
                // Reverse Step 3: XOR with the same highMask
                x ^= highMask
                // Reverse Step 2: bit reverse again
                x = br(x)
                // Reverse Step 1: subtract constant
                x &-= 0x3D
                return x
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
                let highMask: UInt8 = (k & 0xF0)
                let lowMask: UInt8  = (k & 0x0F) &* 0x11
                let bytes = c.map { _c -> UInt8 in
                    var x = _c
                    x ^= lowMask
                    x = (x &>> 1) | (x &<< 7)
                    x ^= highMask
                    x = br(x)
                    x &-= 0x3D
                    return x
                }
                return String(decoding: bytes, as: UTF8.self)
            }
            """
        }
    }
}
