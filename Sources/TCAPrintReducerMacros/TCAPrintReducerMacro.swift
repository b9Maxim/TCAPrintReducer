import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TCAPrintReducerMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let arguments = node.arguments?.as(LabeledExprListSyntax.self)
        let subsystemArg = arguments?.first(where: { $0.label?.text == "subsystem" })?.expression.description ?? "\"default.subsystem\""
        let categoryArg = arguments?.first(where: { $0.label?.text == "category" })?.expression.description ?? "\"default.category\""
        let levelArg = arguments?.first(where: { $0.label?.text == "level" })?.expression.description ?? ".default"

        // Generate the `swiftLog` function
        let generatedFunction = """
        private static func swiftLog(
            _ level: OSLogType = \(levelArg)
        ) -> _ReducerPrinter<State, Action> {
            let logger = Logger(
                subsystem: \(subsystemArg),
                category: \(categoryArg)
            )
            return _ReducerPrinter { receivedAction, oldState, newState in
                var message = "received action:\\n"
                CustomDump.customDump(receivedAction, to: &message, indent: 2)
                message.write("\\n")
                message.write(diff(oldState, newState).map { "\\($0)\\n" } ?? "  (No state changes)\\n")
                logger.log(level: level, "\\(message)")
            }
        }
        """
        // Return the generated code
        return [
            DeclSyntax(stringLiteral: generatedFunction)
        ]
    }
}

@main
struct TCAPrintReducerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TCAPrintReducerMacro.self,
    ]
}
