[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)]()
[![SPM](https://img.shields.io/badge/SPM-compatible-green.svg)]()
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)]()

# Swift String Obfuscation

Compile‑time obfuscation for Swift string literals powered by a freestanding macro.  
`#obfuscate("secret-token")` keeps the original bytes out of your binary and reconstructs the value at runtime with a lightweight decoder.

## Highlights
- 🔒 Compile-time obfuscation: plaintext never hits the final binary
- 🎲 Randomized per-literal algorithms
- 🧩 No runtime dependencies
- 🪶 Lightweight generated decoder
- 🧵 Supports string interpolation: only the literal segments are obfuscated while interpolated expressions stay untouched.

## Requirements
- Swift 6.2 or newer
- Any Apple platform that SwiftPM supports in this package manifest (macOS 10.15, iOS/tvOS 13, watchOS 6, macCatalyst 13 or newer)

## Installation

### Swift Package Manager
Add the dependency to your `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    // ...
    dependencies: [
        .package(url: "https://github.com/zijievv/swift-string-obfuscation.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: [
                .product(name: "ObfuString", package: "swift-string-obfuscation")
            ]
        ),
    ]
)
```

### Xcode
1. Open your project settings and select the project file in the navigator.
2. Go to the “Package Dependencies” tab and click the `+` button.
3. Enter `https://github.com/zijievv/swift-string-obfuscation.git` and select the version rule you prefer (e.g., Up to Next Major).
4. Add the `ObfuString` product to the targets that need the macro.

Then import the library wherever you need to hide literals:

```swift
import ObfuString
```

## Usage
```swift
import ObfuString

let apiToken = #obfuscate("sk_live_51MGZaWdExampleToken123")

let message = #obfuscate("Hello \(username), your OTP is \(otp).")
```

- Each invocation expands into a closure that derives a key from random UUID bytes and a seed, decrypts the obfuscated byte array, and returns the original `String`.
- Interpolated expressions are evaluated normally; only the literal pieces are transformed.
- Empty literals short‑circuit to the original `""` for zero overhead.

## How It Works
1. The macro validates that the argument is a string literal (interpolation allowed).
2. At compile time it picks one of seven algorithms (`A` … `G`). Each applies different mixes of XOR, rotations, byte shuffles, etc.
3. A UUID and seed are generated (or injected, see below) to derive a single‑byte key.
4. The literal bytes are encrypted and emitted as hex constants.
5. During execution the generated helper functions reproduce the key, decrypt the bytes, and build the `String`.

Because these helpers are inlined, there is no shared decoder logic to signature-match, and different invocations produce different helpers.

This is a simplified excerpt. Actual generated symbols differ per call site and per build.

```swift
#obfuscate("Hello, world!")
```

Expands to (simplified):

```swift
{ () -> String in
    @inline(__always)
    func $_deriveKey(_ u: [UInt8], _ i: UInt8) -> UInt8 {
        var h: UInt8 = i
        for b in u {
            h = (h &+ (b &* 31)) ^ 0x5D
        }
        return h
    }

    @inline(__always)
    func $_decrypt(_ c: [UInt8], _ k: UInt8) -> String {
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

    let u: [UInt8] = [
        0x79, 0xEF, 0x45, 0xE7, 0x00, 0xDF, 0x4A, 0x39,
        0x88, 0xEE, 0xFB, 0xF2, 0x0B, 0x94, 0x0C, 0xA3
    ]
    let k: UInt8 = $_deriveKey(u, 0xCE)
    return $_decrypt([0xE6, 0x70, 0xF4, 0xF4, 0x75, 0xD4, 0xD2, 0x79, 0x75, 0xFB, 0xF4, 0xF0, 0x52], k)
}()
```

### Deterministic Output for Tests
Inside the package (or in `@testable import` contexts) a `package`-scoped overload exists:

```swift
package let token = #obfuscate(
    "secret",
    algorithmOffset: 3,
    uuidString: "6422E459-8B3E-76DB-8C89-3613CFA19844",
    seed: 0xBA,
    deriveKeyFuncName: "_deriv",
    decryptFuncName: "_dec"
)
```

You normally never need this. It exists so the test suite can inject predictable entropy and assert on stable output.

## Running the Tests
```bash
swift test
```

The suite (`Tests/ObfuStringTests/ObfuStringTests.swift`) verifies that a variety of literals and interpolations round‑trip through the macro.

## Notes & Limitations
> [!WARNING]
> This library is still evolving and has not undergone extensive testing or any form of security audit. It provides compile-time obfuscation, not cryptographic protection, and should not be relied on to secure secrets against attackers with memory access or instrumentation tools.

- Only compile‑time string literals are supported. Passing a non‑literal `String` will emit a diagnostic.
- Obfuscation increases extraction cost but does **not** provide cryptographic secrecy. Attackers with full memory access, dynamic instrumentation, or debugger tooling can still recover values at runtime.
- Each build produces different ciphertext and helper functions due to randomized entropy. Only the test‑specific overload produces deterministic output.
- For interpolated strings, **only** the literal segments are obfuscated. The dynamic parts (interpolated expressions) remain visible in the compiled binary as usual.
- Each invocation generates a tiny inline decoder. This avoids a universal signature but means many invocations may slightly increase code size.
- Runtime cost is minimal but not zero: the decoder runs once per call site to reconstruct the `String`.

## Feedback
If you encounter an issue or have a feature request, please open an issue on GitHub. 

Pull requests are welcome, especially improvements to macro expansion, test coverage, or documentation.

## License
Released under the [Apache License 2.0](LICENSE).
