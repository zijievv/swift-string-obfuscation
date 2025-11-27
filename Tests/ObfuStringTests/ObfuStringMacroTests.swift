import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ObfuStringMacros)
@testable import ObfuStringMacros

let testMacros: [String: Macro.Type] = [
    "obfuscate": ObfuStringMacro.self
]
#endif  // canImport(ObfuStringMacros)

final class ObfuStringMacroAlgoTests: XCTestCase {
    func testAlgoA() throws {
        #if canImport(ObfuStringMacros)
        assertMacroExpansion(
            """
            #obfuscate("Hello, world",
                algorithmOffset: 0, 
                uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
                seed: 0x67,
                deriveKeyFuncName: "deriveKeyFn",
                decryptFuncName: "decryptFn"
            )
            """,
            expandedSource: """
                { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
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

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0x31, 0xA7, 0x23, 0x23, 0xA2, 0x03, 0x05, 0xAE, 0xA2, 0x2C, 0x23, 0x27], k)
                }()
                """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAlgoB() throws {
        #if canImport(ObfuStringMacros)
        assertMacroExpansion(
            #"""
            #obfuscate("Hello, \(name)",
                algorithmOffset: 1, 
                uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
                seed: 0x67,
                deriveKeyFuncName: "deriveKeyFn",
                decryptFuncName: "decryptFn"
            )
            """#,
            expandedSource: #"""
                { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
                        let bytes = c.map { _c -> UInt8 in
                            var x = (_c &<< 2) | (_c &>> 6)
                            x &-= 0x3D
                            return x ^ k
                        }
                        return String(decoding: bytes, as: UTF8.self)
                    }

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0xE7, 0x23, 0xE0, 0xE0, 0xA0, 0xD0, 0xD1], k)
                }() + "\(name)"
                """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAlgoC() throws {
        #if canImport(ObfuStringMacros)
        assertMacroExpansion(
            """
            #obfuscate("你好，世界！",
                algorithmOffset: 2, 
                uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
                seed: 0x67,
                deriveKeyFuncName: "deriveKeyFn",
                decryptFuncName: "decryptFn"
            )
            """,
            expandedSource: """
                { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
                        let bytes = c.map { _c -> UInt8 in
                            var x = _c ^ 0xA5
                            x = (x &<< 4) | (x &>> 4)
                            x ^= k
                            return (x & 0xF0) >> 4 | (x & 0x0F) << 4
                        }
                        return String(decoding: bytes, as: UTF8.self)
                    }

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0xE3, 0xBA, 0xA7, 0xE2, 0xA2, 0xBA, 0xE8, 0xBB, 0x8B, 0xE3, 0xBF, 0x91, 0xE0, 0x92, 0x8B, 0xE8, 0xBB, 0x86], k)
                }()
                """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAlgoD() throws {
        #if canImport(ObfuStringMacros)
        assertMacroExpansion(
            #"""
            #obfuscate("🧮: 1 ➕ 2 🟰 3",
                algorithmOffset: 3, 
                uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
                seed: 0x67,
                deriveKeyFuncName: "deriveKeyFn",
                decryptFuncName: "decryptFn"
            )
            """#,
            expandedSource: """
                { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
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

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0x90, 0x3E, 0x3A, 0xCA, 0xE1, 0x99, 0x11, 0x99, 0xD8, 0xBE, 0xEE, 0x99, 0xD1, 0x99, 0x90, 0x3E, 0x3E, 0x92, 0x99, 0x51], k)
                }()
                """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAlgoE() throws {
        #if canImport(ObfuStringMacros)
        assertMacroExpansion(
            #"""
            #obfuscate("\(true) and \(false) are Boolean values.",
                algorithmOffset: 4, 
                uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
                seed: 0x67,
                deriveKeyFuncName: "deriveKeyFn",
                decryptFuncName: "decryptFn"
            )
            """#,
            expandedSource: #"""
                "\(true)" + { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
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

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0x4C, 0x1C, 0x75, 0x5C, 0x4F], k)
                }() + "\(false)" + { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
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

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0x4C, 0x1C, 0x4D, 0x5E, 0x4F, 0xB2, 0x9D, 0x24, 0xAC, 0x53, 0xE7, 0x80, 0xF2, 0x81, 0xD2, 0x0F, 0xE6, 0x14, 0x4F, 0xC8], k)
                }()
                """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAlgoF() throws {
        #if canImport(ObfuStringMacros)
        assertMacroExpansion(
            """
            #obfuscate("Eiusmod adipisicing id amet do magna cillum quis id sit id fugiat qui exercitation.",
                algorithmOffset: 5, 
                uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
                seed: 0x67,
                deriveKeyFuncName: "deriveKeyFn",
                decryptFuncName: "decryptFn"
            )
            """,
            expandedSource: """
                { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
                        let bs = c.map { _c -> UInt8 in
                            var x = (_c &<< 3) | (_c &>> 5)
                            x ^= k
                            let a = (x & 0b10101010) >> 1 | (x & 0b01010101) << 1
                            return (a & 0b11001100) >> 2 | (a & 0b00110011) << 2
                        }
                        return String(decoding: bs, as: UTF8.self)
                    }

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0x00, 0x68, 0x18, 0xD8, 0x28, 0xA8, 0x09, 0x4D, 0x48, 0x09, 0x68, 0x59, 0x68, 0xD8, 0x68, 0xC8, 0x68, 0xA9, 0x88, 0x4D, 0x68, 0x09, 0x4D, 0x48, 0x28, 0x08, 0x19, 0x4D, 0x09, 0xA8, 0x4D, 0x28, 0x48, 0x88, 0xA9, 0x48, 0x4D, 0xC8, 0x68, 0x29, 0x29, 0x18, 0x28, 0x4D, 0x58, 0x18, 0x68, 0xD8, 0x4D, 0x68, 0x09, 0x4D, 0xD8, 0x68, 0x19, 0x4D, 0x68, 0x09, 0x4D, 0x89, 0x18, 0x88, 0x68, 0x48, 0x19, 0x4D, 0x58, 0x18, 0x68, 0x4D, 0x08, 0x79, 0x08, 0xD9, 0xC8, 0x68, 0x19, 0x48, 0x19, 0x68, 0xA8, 0xA9, 0xAD], k)
                }()
                """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAlgoG() throws {
        #if canImport(ObfuStringMacros)
        assertMacroExpansion(
            """
            #obfuscate("Dolore ut est eiusmod fugiat culpa laboris ipsum enim voluptate deserunt. Proident officia anim commodo commodo dolore in nostrud velit cillum officia ut anim ipsum exercitation. Nisi labore culpa ex excepteur occaecat irure dolor sunt labore. Incididunt excepteur Lorem ea aliquip et id. Cillum exercitation cillum tempor tempor consequat elit ut. Ad deserunt labore sit deserunt minim anim veniam est irure elit commodo do sint exercitation. Nostrud laborum commodo laboris nisi mollit culpa cupidatat. Veniam irure officia sit enim deserunt nostrud pariatur.",
                algorithmOffset: 6, 
                uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
                seed: 0x67,
                deriveKeyFuncName: "deriveKeyFn",
                decryptFuncName: "decryptFn"
            )
            """,
            expandedSource: """
                { () -> String in
                    @inline(__always)
                    func deriveKeyFn(_ u: [UInt8], _ i: UInt8) -> UInt8 {
                        var h: UInt8 = i
                        let r = Int.random(in: 0 ... 16)
                        let s = r > 15 ? r : 16
                        for b in u[0 ..< s] {
                            h = (h &+ (b &* 31)) ^ 0x5D
                        }
                        return h
                    }

                    @inline(__always)
                    func decryptFn(_ c: [UInt8], _ k: UInt8) -> String {
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

                    let u: [UInt8] = [0x64, 0x22, 0xE4, 0x59, 0x8B, 0x3E, 0x76, 0xDB, 0x8C, 0x89, 0x36, 0x13, 0xCF, 0xA1, 0x98, 0x44]
                    let k: UInt8 = deriveKeyFn(u, 0x67)
                    return decryptFn([0xE9, 0x80, 0xC1, 0x80, 0x01, 0x60, 0x9F, 0x70, 0xF1, 0x9F, 0x60, 0xF0, 0xF1, 0x9F, 0x60, 0x20, 0x70, 0xF0, 0x40, 0x80, 0xE1, 0x9F, 0x61, 0x70, 0xA0, 0x20, 0x18, 0xF1, 0x9F, 0xE0, 0x70, 0xC1, 0x81, 0x18, 0x9F, 0xC1, 0x18, 0x19, 0x80, 0x01, 0x20, 0xF0, 0x9F, 0x20, 0x81, 0xF0, 0x70, 0x40, 0x9F, 0x60, 0x41, 0x20, 0x40, 0x9F, 0x71, 0x80, 0xC1, 0x70, 0x81, 0xF1, 0x18, 0xF1, 0x60, 0x9F, 0xE1, 0x60, 0xF0, 0x60, 0x01, 0x70, 0x41, 0xF1, 0x47, 0x9F, 0x89, 0x01, 0x80, 0x20, 0xE1, 0x60, 0x41, 0xF1, 0x9F, 0x80, 0x61, 0x61, 0x20, 0xE0, 0x20, 0x18, 0x9F, 0x18, 0x41, 0x20, 0x40, 0x9F, 0xE0, 0x80, 0x40, 0x40, 0x80, 0xE1, 0x80, 0x9F, 0xE0, 0x80, 0x40, 0x40, 0x80, 0xE1, 0x80, 0x9F, 0xE1, 0x80, 0xC1, 0x80, 0x01, 0x60, 0x9F, 0x20, 0x41, 0x9F, 0x41, 0x80, 0xF0, 0xF1, 0x01, 0x70, 0xE1, 0x9F, 0x71, 0x60, 0xC1, 0x20, 0xF1, 0x9F, 0xE0, 0x20, 0xC1, 0xC1, 0x70, 0x40, 0x9F, 0x80, 0x61, 0x61, 0x20, 0xE0, 0x20, 0x18, 0x9F, 0x70, 0xF1, 0x9F, 0x18, 0x41, 0x20, 0x40, 0x9F, 0x20, 0x81, 0xF0, 0x70, 0x40, 0x9F, 0x60, 0xB1, 0x60, 0x01, 0xE0, 0x20, 0xF1, 0x18, 0xF1, 0x20, 0x80, 0x41, 0x47, 0x9F, 0x49, 0x20, 0xF0, 0x20, 0x9F, 0xC1, 0x18, 0x19, 0x80, 0x01, 0x60, 0x9F, 0xE0, 0x70, 0xC1, 0x81, 0x18, 0x9F, 0x60, 0xB1, 0x9F, 0x60, 0xB1, 0xE0, 0x60, 0x81, 0xF1, 0x60, 0x70, 0x01, 0x9F, 0x80, 0xE0, 0xE0, 0x18, 0x60, 0xE0, 0x18, 0xF1, 0x9F, 0x20, 0x01, 0x70, 0x01, 0x60, 0x9F, 0xE1, 0x80, 0xC1, 0x80, 0x01, 0x9F, 0xF0, 0x70, 0x41, 0xF1, 0x9F, 0xC1, 0x18, 0x19, 0x80, 0x01, 0x60, 0x47, 0x9F, 0x28, 0x41, 0xE0, 0x20, 0xE1, 0x20, 0xE1, 0x70, 0x41, 0xF1, 0x9F, 0x60, 0xB1, 0xE0, 0x60, 0x81, 0xF1, 0x60, 0x70, 0x01, 0x9F, 0xC9, 0x80, 0x01, 0x60, 0x40, 0x9F, 0x60, 0x18, 0x9F, 0x18, 0xC1, 0x20, 0x00, 0x70, 0x20, 0x81, 0x9F, 0x60, 0xF1, 0x9F, 0x20, 0xE1, 0x47, 0x9F, 0xE8, 0x20, 0xC1, 0xC1, 0x70, 0x40, 0x9F, 0x60, 0xB1, 0x60, 0x01, 0xE0, 0x20, 0xF1, 0x18, 0xF1, 0x20, 0x80, 0x41, 0x9F, 0xE0, 0x20, 0xC1, 0xC1, 0x70, 0x40, 0x9F, 0xF1, 0x60, 0x40, 0x81, 0x80, 0x01, 0x9F, 0xF1, 0x60, 0x40, 0x81, 0x80, 0x01, 0x9F, 0xE0, 0x80, 0x41, 0xF0, 0x60, 0x00, 0x70, 0x18, 0xF1, 0x9F, 0x60, 0xC1, 0x20, 0xF1, 0x9F, 0x70, 0xF1, 0x47, 0x9F, 0x16, 0xE1, 0x9F, 0xE1, 0x60, 0xF0, 0x60, 0x01, 0x70, 0x41, 0xF1, 0x9F, 0xC1, 0x18, 0x19, 0x80, 0x01, 0x60, 0x9F, 0xF0, 0x20, 0xF1, 0x9F, 0xE1, 0x60, 0xF0, 0x60, 0x01, 0x70, 0x41, 0xF1, 0x9F, 0x40, 0x20, 0x41, 0x20, 0x40, 0x9F, 0x18, 0x41, 0x20, 0x40, 0x9F, 0x71, 0x60, 0x41, 0x20, 0x18, 0x40, 0x9F, 0x60, 0xF0, 0xF1, 0x9F, 0x20, 0x01, 0x70, 0x01, 0x60, 0x9F, 0x60, 0xC1, 0x20, 0xF1, 0x9F, 0xE0, 0x80, 0x40, 0x40, 0x80, 0xE1, 0x80, 0x9F, 0xE1, 0x80, 0x9F, 0xF0, 0x20, 0x41, 0xF1, 0x9F, 0x60, 0xB1, 0x60, 0x01, 0xE0, 0x20, 0xF1, 0x18, 0xF1, 0x20, 0x80, 0x41, 0x47, 0x9F, 0x49, 0x80, 0xF0, 0xF1, 0x01, 0x70, 0xE1, 0x9F, 0xC1, 0x18, 0x19, 0x80, 0x01, 0x70, 0x40, 0x9F, 0xE0, 0x80, 0x40, 0x40, 0x80, 0xE1, 0x80, 0x9F, 0xC1, 0x18, 0x19, 0x80, 0x01, 0x20, 0xF0, 0x9F, 0x41, 0x20, 0xF0, 0x20, 0x9F, 0x40, 0x80, 0xC1, 0xC1, 0x20, 0xF1, 0x9F, 0xE0, 0x70, 0xC1, 0x81, 0x18, 0x9F, 0xE0, 0x70, 0x81, 0x20, 0xE1, 0x18, 0xF1, 0x18, 0xF1, 0x47, 0x9F, 0x79, 0x60, 0x41, 0x20, 0x18, 0x40, 0x9F, 0x20, 0x01, 0x70, 0x01, 0x60, 0x9F, 0x80, 0x61, 0x61, 0x20, 0xE0, 0x20, 0x18, 0x9F, 0xF0, 0x20, 0xF1, 0x9F, 0x60, 0x41, 0x20, 0x40, 0x9F, 0xE1, 0x60, 0xF0, 0x60, 0x01, 0x70, 0x41, 0xF1, 0x9F, 0x41, 0x80, 0xF0, 0xF1, 0x01, 0x70, 0xE1, 0x9F, 0x81, 0x18, 0x01, 0x20, 0x18, 0xF1, 0x70, 0x01, 0x47], k)
                }()
                """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
