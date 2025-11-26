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
}
