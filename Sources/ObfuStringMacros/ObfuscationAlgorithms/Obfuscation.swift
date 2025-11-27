import Foundation
import SwiftSyntax

enum Obfuscation: CaseIterable {
    case a
    case b
    case c
    case d
    case e
    case f
    case g

    func algo() -> Algorithm.Type {
        switch self {
        case .a: A.self
        case .b: B.self
        case .c: C.self
        case .d: D.self
        case .e: E.self
        case .f: F.self
        case .g: G.self
        }
    }

    static func deriveBytes(from uuid: UUID) -> [UInt8] {
        let u = uuid.uuid
        return [
            u.0, u.1, u.2, u.3,
            u.4, u.5, u.6, u.7,
            u.8, u.9, u.10, u.11,
            u.12, u.13, u.14, u.15,
        ]
    }

    static func deriveKey(from uuidBytes: [UInt8], initialSeed: UInt8) -> UInt8 {
        var h: UInt8 = initialSeed
        for b in uuidBytes {
            h = (h &+ (b &* 31)) ^ 0x5D
        }
        return h
    }

    static func deriveKeyFuncDecl(funcName: TokenSyntax) -> DeclSyntax {
        """
        @inline(__always)
        func \(funcName)(_ u: [UInt8], _ i: UInt8) -> UInt8 {
            var h: UInt8 = i
            for b in u {
                h = (h &+ (b &* 31)) ^ 0x5D
            }
            return h
        }
        """
    }
}

extension Obfuscation {
    protocol Algorithm {
        static func encrypt(_ text: String, key: UInt8) -> [UInt8]

        static func decryptFuncDecl(funcName: TokenSyntax) -> DeclSyntax

        static func decryptClosureExpr(
            deriveKeyFuncName: TokenSyntax,
            decryptFuncName: TokenSyntax,
            keySeed: UInt8,
            keyUUIDArrLiteralRaw: String,
            cipherArrLiteralRaw: String,
        ) -> ExprSyntax
    }
}

extension Obfuscation.Algorithm {
    static func decryptClosureExpr(
        deriveKeyFuncName: TokenSyntax,
        decryptFuncName: TokenSyntax,
        keySeed: UInt8,
        keyUUIDArrLiteralRaw: String,
        cipherArrLiteralRaw: String
    ) -> ExprSyntax {
        """
        { () -> String in
            \(Obfuscation.deriveKeyFuncDecl(funcName: deriveKeyFuncName))

            \(decryptFuncDecl(funcName: decryptFuncName))

            let u: [UInt8] = [\(raw: keyUUIDArrLiteralRaw)]
            let k: UInt8 = \(deriveKeyFuncName)(u, \(raw: String(format: "0x%02X", keySeed)))
            return \(decryptFuncName)([\(raw: cipherArrLiteralRaw)], k)
        }()
        """
    }
}
