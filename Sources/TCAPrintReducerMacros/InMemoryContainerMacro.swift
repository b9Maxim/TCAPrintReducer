//
//  InMemoryContainerMacro.swift
//  TCAPrintReducer
//
//  Created by Maxim on 11.09.2025.
//

/*
 Example usage:

 // Internal struct - generates internal Container
 @InMemoryContainerMacro
 struct UserModel {
     var id: String
     var name: String
     var email: String
 }

 // The macro automatically:
 // 1. Validates that the struct conforms to Sendable (required)
 // 2. Generates a Container struct that conforms to CacheContainerProtocol
 // 3. If struct is public, Container and its properties are also public
 */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import TCAPrintReducerTypes

public struct InMemoryContainerMacro: MemberMacro {
    // MemberMacro implementation
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract the struct name
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.message("@InMemoryContainerMacro can only be applied to structs")
        }

        let structName = structDecl.name.text

        // Check if the struct conforms to Sendable
        let inheritanceClause = structDecl.inheritanceClause
        let conformsToSendable = inheritanceClause?.inheritedTypes.contains { inheritedType in
            inheritedType.type.as(IdentifierTypeSyntax.self)?.name.text == "Sendable"
        } ?? false

        if !conformsToSendable {
            throw MacroError.message(
                """
                @InMemoryContainerMacro struct must conform to Sendable protocol.
                Add 'Sendable' to your struct declaration:
                struct \(structDecl.name): Sendable {
                """
            )
        }

        // Check if the struct is public
        let isPublic = structDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public)
        }

        // Generate the Container struct with appropriate visibility
        let publicText = isPublic ? "public " : ""

        let codeBlock = """
        \(publicText)struct Container: CacheContainerProtocol {
            \(publicText)var get: @Sendable () throws -> \(structName) = {
                return \(structName)()
            }

            \(publicText)var save: @Sendable (\(structName)) throws -> Void = { _ in
            }

            \(publicText)var delete: @Sendable () throws -> Void = {
            }

            \(publicText)init(
              get: @escaping @Sendable () throws -> \(structName) = { return \(structName)() },
              save: @escaping @Sendable (\(structName)) throws -> Void = { _ in },
              delete: @escaping @Sendable () throws -> Void = { }
            ) {
                self.get = get
                self.save = save
                self.delete = delete
            }

            \(publicText)static var liveValue: Self {
                let data = LockIsolated<\(structName)?>(nil)
                return Self(
                    get: {
                        guard let data = data.value else {
                            throw CacheContainerNoDataFound()
                        }
                        return data
                    },
                    save: { data.setValue($0) },
                    delete: { data.setValue(nil) }
                )
            }
        }
        """

        return [DeclSyntax(stringLiteral: codeBlock)]
    }
}
