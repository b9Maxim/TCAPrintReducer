import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension VariableDeclSyntax {
  var identifierPattern: IdentifierPatternSyntax? {
    bindings.first?.pattern.as(IdentifierPatternSyntax.self)
  }

  var isInstance: Bool {
    for modifier in modifiers {
      for token in modifier.tokens(viewMode: .all) {
        if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
          return false
        }
      }
    }
    return true
  }

  var identifier: TokenSyntax? {
    identifierPattern?.identifier
  }

  var type: TypeSyntax? {
    bindings.first?.typeAnnotation?.type
  }

  func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
    let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
      switch patternBinding.accessorBlock?.accessors {
      case let .accessors(accessors):
        return accessors
      default:
        return nil
      }
    }.flatMap { $0 }
    return accessors.compactMap { predicate($0.accessorSpecifier.tokenKind) ? $0 : nil }
  }

  var willSetAccessors: [AccessorDeclSyntax] {
    accessorsMatching { $0 == .keyword(.willSet) }
  }
  var didSetAccessors: [AccessorDeclSyntax] {
    accessorsMatching { $0 == .keyword(.didSet) }
  }

  var isComputed: Bool {
    if accessorsMatching({ $0 == .keyword(.get) }).count > 0 {
      return true
    } else {
      return bindings.contains { binding in
        if case .getter = binding.accessorBlock?.accessors {
          return true
        } else {
          return false
        }
      }
    }
  }

  var isImmutable: Bool {
    return bindingSpecifier.tokenKind == .keyword(.let)
  }

  func isEquivalent(to other: VariableDeclSyntax) -> Bool {
    if isInstance != other.isInstance {
      return false
    }
    return identifier?.text == other.identifier?.text
  }

  var initializer: InitializerClauseSyntax? {
    bindings.first?.initializer
  }

  func hasMacroApplication(_ name: String) -> Bool {
    for attribute in attributes {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return true
        }
      default:
        break
      }
    }
    return false
  }

  func firstAttribute(for name: String) -> AttributeSyntax? {
    for attribute in attributes {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return attr
        }
      default:
        break
      }
    }
    return nil
  }
}

extension VariableDeclSyntax {
  func privatePrefixed(_ prefix: String, addingAttribute attribute: AttributeSyntax)
    -> VariableDeclSyntax
  {
    let newAttributes = attributes + [.attribute(attribute)]
    return VariableDeclSyntax(
      leadingTrivia: leadingTrivia,
      attributes: newAttributes,
      modifiers: modifiers.privatePrefixed(prefix),
      bindingSpecifier: TokenSyntax(
        bindingSpecifier.tokenKind, leadingTrivia: .space, trailingTrivia: .space,
        presence: .present),
      bindings: bindings.privatePrefixed(prefix),
      trailingTrivia: trailingTrivia
    )
  }

  var isValidForObservation: Bool {
    !isComputed && isInstance && !isImmutable && identifier != nil
  }
}
extension DeclModifierListSyntax {
  func privatePrefixed(_ prefix: String) -> DeclModifierListSyntax {
    let modifier: DeclModifierSyntax = DeclModifierSyntax(name: "private", trailingTrivia: .space)
    return [modifier]
      + filter {
        switch $0.name.tokenKind {
        case .keyword(let keyword):
          switch keyword {
          case .fileprivate, .private, .internal, .public, .package:
            return false
          default:
            return true
          }
        default:
          return true
        }
      }
  }

  init(keyword: Keyword) {
    self.init([DeclModifierSyntax(name: .keyword(keyword))])
  }
}

extension PatternBindingListSyntax {
  func privatePrefixed(_ prefix: String) -> PatternBindingListSyntax {
    var bindings = self.map { $0 }
    for index in 0..<bindings.count {
      let binding = bindings[index]
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        bindings[index] = PatternBindingSyntax(
          leadingTrivia: binding.leadingTrivia,
          pattern: IdentifierPatternSyntax(
            leadingTrivia: identifier.leadingTrivia,
            identifier: identifier.identifier.privatePrefixed(prefix),
            trailingTrivia: identifier.trailingTrivia
          ),
          typeAnnotation: binding.typeAnnotation,
          initializer: binding.initializer,
          accessorBlock: binding.accessorBlock,
          trailingComma: binding.trailingComma,
          trailingTrivia: binding.trailingTrivia)

      }
    }

    return PatternBindingListSyntax(bindings)
  }
}

extension TokenSyntax {
  func privatePrefixed(_ prefix: String) -> TokenSyntax {
    switch tokenKind {
    case .identifier(let identifier):
      return TokenSyntax(
        .identifier(prefix + identifier), leadingTrivia: leadingTrivia,
        trailingTrivia: trailingTrivia, presence: presence)
    default:
      return self
    }
  }
}

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

public struct LoadingStateMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let newProperty = try VariableDeclSyntax("""
@LoadingState2Macro 
var loadingState: LoadingOverlayState = .none
"""
        )
        return [DeclSyntax(newProperty)]
    }
}

public struct LoadingState2Macro: AccessorMacro {
    static let registrarVariableName = "_$observationRegistrar"
    static let ignoredMacroName = "ObservationStateIgnored"
    static var ignoredAttribute: AttributeSyntax {
      AttributeSyntax(
        leadingTrivia: .space,
        atSign: .atSignToken(),
        attributeName: IdentifierTypeSyntax(name: .identifier(ignoredMacroName)),
        trailingTrivia: .space
      )
    }
    
    public static func expansion<
        Context: MacroExpansionContext,
        Declaration: DeclSyntaxProtocol
    >(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: Declaration,
        in context: Context
    ) throws -> [AccessorDeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isValidForObservation,
              let identifier = property.identifier?.trimmed
        else {
            return []
        }
        
        
        let initAccessor: AccessorDeclSyntax =
      """
      @storageRestrictions(initializes: _\(identifier))
      init(initialValue) {
      _\(identifier) = initialValue
      }
      """
        
        let getAccessor: AccessorDeclSyntax =
      """
      get {
      \(raw: LoadingState2Macro.registrarVariableName).access(self, keyPath: \\.\(identifier))
      return _\(identifier)
      }
      """
        
        let setAccessor: AccessorDeclSyntax =
      """
      set {
      \(raw: LoadingState2Macro.registrarVariableName).mutate(self, keyPath: \\.\(identifier), &_\(identifier), newValue, _$isIdentityEqual)
      }
      """
        let modifyAccessor: AccessorDeclSyntax = """
      _modify {
        let oldValue = _$observationRegistrar.willModify(self, keyPath: \\.\(identifier), &_\(identifier))
        defer {
          _$observationRegistrar.didModify(self, keyPath: \\.\(identifier), &_\(identifier), oldValue, _$isIdentityEqual)
        }
        yield &_\(identifier)
      }
      """
        
        return [initAccessor, getAccessor, setAccessor, modifyAccessor]
    }
}

extension LoadingState2Macro: PeerMacro {
    public static func expansion<
        Context: MacroExpansionContext,
        Declaration: DeclSyntaxProtocol
    >(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let property = declaration.as(VariableDeclSyntax.self),
              property.isValidForObservation
        else {
            return []
        }
        
        let storage = DeclSyntax(
            property.privatePrefixed("_", addingAttribute: LoadingState2Macro.ignoredAttribute))
        return [storage]
    }
}

@main
struct TCAPrintReducerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TCAPrintReducerMacro.self,
        LoadingStateMacro.self,
        LoadingState2Macro.self
    ]
}
