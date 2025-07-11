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
        
        let generatedStruct = """
                struct ReducerLogger {
                    private let logger = Logger(subsystem: \(subsystemArg), category: \(categoryArg))
                
                    func log(_ level: OSLogType = .debug, _ message: String) {
                        logger.log(level: level, "\\(message)")
                    }
                    
                    func swiftLog(
                        _ level: OSLogType = \(levelArg)
                    ) -> _ReducerPrinter<State, Action> {
                        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                            return .customDump
                        } else {
                            return _ReducerPrinter { receivedAction, oldState, newState in
                                
                                let logger = Logger(
                                    subsystem: \(subsystemArg),
                                    category: \(categoryArg)
                                )
                                var message = "received action:\\n"
                                CustomDump.customDump(receivedAction, to: &message, indent: 2)
                                message.write("\\n")
                                message.write(diff(oldState, newState).map { "\\($0)\\n" } ?? "  (No state changes)\\n")
                                logger.log(level: level, "\\(message)")
                            }
                        }
                    }
                }
                """
        
        // Generate the `reducerLogger` instance
        let generatedInstance = "let reducerLogger = ReducerLogger()"
        // Return the generated code
        return [
            DeclSyntax(stringLiteral: generatedStruct),
            DeclSyntax(stringLiteral: generatedInstance)
        ]
    }
}

@main
struct TCAPrintReducerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TCAPrintReducerMacro.self,
        LoadingStateMacro.self
    ]
}
