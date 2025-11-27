import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ObfuStringMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let strLiteralExpr = node.arguments.first?.expression.as(StringLiteralExprSyntax.self) else {
            throw DiagnosticsError(node: Syntax(node), "expected a string literal argument")
        }
        let entropy = try parseObfuscationEntropyInjection(from: node)
        let strExprs: [ExprSyntax] = try strLiteralExpr.segments.reduce(into: [ExprSyntax]()) { acc, segment in
            switch segment {
            case .stringSegment:
                let rawTextStrLiteralExpr = StringLiteralExprSyntax(
                    openingPounds: strLiteralExpr.openingPounds,
                    openingQuote: strLiteralExpr.openingQuote,
                    segments: .init([segment]),
                    closingQuote: strLiteralExpr.closingQuote,
                    closingPounds: strLiteralExpr.closingPounds
                )
                guard let rawText = rawTextStrLiteralExpr.representedLiteralValue else {
                    throw DiagnosticsError(node: Syntax(segment), "invalid or unsupported string literal segment")
                }
                guard !rawText.isEmpty else {
                    return
                }
                acc.append(strBuilderClosureExpr(rawText: rawText, in: context, entropy: entropy))
            case .expressionSegment(let seg):
                acc.append(#""\(\#(raw: seg.expressions.trimmed.description))""#)
            }
        }
        guard !strExprs.isEmpty else {
            return ExprSyntax(strLiteralExpr)
        }
        let expr = strExprs.dropFirst().reduce(strExprs[0]) { acc, next in
            ExprSyntax(
                InfixOperatorExprSyntax(
                    leftOperand: acc,
                    operator: BinaryOperatorExprSyntax(operator: .binaryOperator("+")),
                    rightOperand: next
                )
            )
        }
        return expr
    }

    private static func strBuilderClosureExpr(
        rawText: String,
        in context: some MacroExpansionContext,
        entropy: ObfuscationEntropy?
    ) -> ExprSyntax {
        // random
        let uuid = Obfuscation.deriveBytes(from: entropy?.uuid ?? UUID())
        let seed = entropy?.seed ?? UInt8.random(in: 0...255)
        let deriveKeyFuncName = entropy?.deriveKeyFuncName ?? context.makeUniqueName("_k")
        let decryptFuncName = entropy?.decryptFuncName ?? context.makeUniqueName("_d")
        let obfuscation = entropy?.algorithm ?? Obfuscation.allCases.randomElement() ?? .g
        let algo = obfuscation.algo()

        let key = Obfuscation.deriveKey(from: uuid, initialSeed: seed)
        let cipher = algo.encrypt(rawText, key: key)

        let cipherArrLiteral = cipher.map { String(format: "0x%02X", $0) }.joined(separator: ",")
        let uuidArrLiteral = uuid.map { String(format: "0x%02X", $0) }.joined(separator: ",")

        let expr = algo.decryptClosureExpr(
            deriveKeyFuncName: deriveKeyFuncName,
            decryptFuncName: decryptFuncName,
            keySeed: seed,
            keyUUIDArrLiteralRaw: uuidArrLiteral,
            cipherArrLiteralRaw: cipherArrLiteral
        )
        return expr
    }
}

// MARK: - Testing injection

private struct ObfuscationEntropy {
    let algorithm: Obfuscation
    let uuid: UUID
    let seed: UInt8
    let deriveKeyFuncName: TokenSyntax
    let decryptFuncName: TokenSyntax
}

extension ObfuStringMacro {
    private static func parseObfuscationEntropyInjection(
        from node: some FreestandingMacroExpansionSyntax
    ) throws -> ObfuscationEntropy? {
        let args = node.arguments.dropFirst().map { $0 }
        guard !args.isEmpty else {
            return nil
        }
        return try ObfuscationEntropy(
            algorithm: parseObfuscationAlgo(from: args[0]),
            uuid: parseUUIDArg(from: args[1]),
            seed: parseInteger(from: args[2]),
            deriveKeyFuncName: parseFuncName(from: args[3]),
            decryptFuncName: parseFuncName(from: args[4])
        )
    }

    private static func parseStringLiteralArg(from arg: LabeledExprSyntax) throws -> String {
        guard let strLiteralExpr = arg.expression.as(StringLiteralExprSyntax.self) else {
            throw DiagnosticsError(node: Syntax(arg), "expected a string literal argument")
        }
        return try strLiteralExpr.segments.map { seg in
            switch seg {
            case .stringSegment(let seg):
                seg.content.text
            case .expressionSegment:
                throw DiagnosticsError(node: Syntax(arg), "expected a string literal argument")
            }
        }
        .joined()
    }

    private static func parseUUIDArg(from arg: LabeledExprSyntax) throws -> UUID {
        let raw = try parseStringLiteralArg(from: arg)
        guard let uuid = UUID(uuidString: raw) else {
            throw DiagnosticsError(node: Syntax(arg), "invalid UUID string")
        }
        return uuid
    }

    private static func parseFuncName(from arg: LabeledExprSyntax) throws -> TokenSyntax {
        let raw = try parseStringLiteralArg(from: arg)
        return "\(raw: raw)"
    }

    private static func parseInteger<I: BinaryInteger>(
        _ type: I.Type = I.self,
        from arg: LabeledExprSyntax
    ) throws -> I {
        guard let raw = arg.expression.as(IntegerLiteralExprSyntax.self)?.representedLiteralValue.map(I.init(_:)) else {
            throw DiagnosticsError(node: Syntax(arg), "invalid integer literal")
        }
        return raw
    }

    private static func parseObfuscationAlgo(from arg: LabeledExprSyntax) throws -> Obfuscation {
        let offset: Int = try parseInteger(from: arg)
        return Obfuscation.allCases[abs(offset) % Obfuscation.allCases.count]
    }
}

@main
struct ObfuStringPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObfuStringMacro.self
    ]
}

extension DiagnosticsError {
    init(node: Syntax, _ message: String) {
        self.init(diagnostics: [.init(node: node, message: Diagnostic(message: message))])
    }
}

struct Diagnostic: DiagnosticMessage {
    let message: String

    var severity: DiagnosticSeverity {
        .error
    }

    var diagnosticID: MessageID {
        .init(domain: "ObfuString", id: message)
    }
}
