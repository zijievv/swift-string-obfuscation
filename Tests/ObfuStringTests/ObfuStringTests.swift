import Testing

@testable import ObfuString

@Suite
struct ObfuStringTests {
    @Test
    func testDecoding() async throws {
        let decoded = [
            #obfuscate("Nulla ipsum eiusmod culpa. 😎"),
            #obfuscate("Quis ad enim nulla cupidatat pariatur minim consectetur amet commodo laboris cupidatat."),
            #obfuscate("Exercitation pariatur id culpa velit Lorem incididunt nulla mollit commodo anim."),
            #obfuscate("Consectetur cillum \(true) ipsum laborum esse veniam in."),
            #obfuscate("Cupidatat minim aliqua eiusmod adipisicing nulla labore velit."),
            #obfuscate("Proident minim ad amet commodo do commodo dolor eu et laboris tempor."),
            #obfuscate("Est voluptate fugiat ad consectetur exercitation tempor aute cillum duis."),
            #obfuscate("\(1) + \(1) = \(2)"),
        ]
        let expected = [
            "Nulla ipsum eiusmod culpa. 😎",
            "Quis ad enim nulla cupidatat pariatur minim consectetur amet commodo laboris cupidatat.",
            "Exercitation pariatur id culpa velit Lorem incididunt nulla mollit commodo anim.",
            "Consectetur cillum \(true) ipsum laborum esse veniam in.",
            "Cupidatat minim aliqua eiusmod adipisicing nulla labore velit.",
            "Proident minim ad amet commodo do commodo dolor eu et laboris tempor.",
            "Est voluptate fugiat ad consectetur exercitation tempor aute cillum duis.",
            "\(1) + \(1) = \(2)",
        ]
        for (d, e) in zip(decoded, expected) {
            #expect(d == e)
        }
    }

    @Test
    func testEmptyLiteral() async throws {
        let empty = #obfuscate("")
        #expect(empty.isEmpty)
    }

    @Test
    func testEscapedCharacters() async throws {
        let obfuscated = #obfuscate("Line1\nLine2\t\"quote\"\\backslash\u{0000}")
        #expect(obfuscated == "Line1\nLine2\t\"quote\"\\backslash\u{0000}")
    }

    @Test
    func testEscapedCharactersInRawStringLiteral() async throws {
        let obfuscated = #obfuscate(#"Line1\#nLine2"#)
        #expect(obfuscated == #"Line1\#nLine2"#)
    }

    @Test
    func testRawMultilineLiteral() async throws {
        let raw = #obfuscate(
            """
            multi-line
            ""quotes""
            tab\there
            """)
        #expect(
            raw == """
                multi-line
                ""quotes""
                tab\there
                """)
    }

    @Test
    func testEscapedCharacterInRawMultilineLiteral() async throws {
        let obfuscated = #obfuscate(
            #"""
            line1\#n
            line3
            """#)
        let expected = #"""
            line1\#n
            line3
            """#
        #expect(obfuscated == expected)
    }

    @Test
    func testInterpolationOnlyLiteralSegments() async throws {
        let value = 42
        let obfuscated = #obfuscate("\(value)")
        #expect(obfuscated == "\(value)")
    }

    @Test
    func testDeterministicEntropyInjection() async throws {
        let deterministic = #obfuscate(
            "deterministic",
            algorithmOffset: 2,
            uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
            seed: 0x1A,
            deriveKeyFuncName: "deriveKey",
            decryptFuncName: "decrypt"
        )
        #expect(deterministic == "deterministic")
    }
}
