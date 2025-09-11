//
//  InMemoryContainerMacro.swift
//  TCAPrintReducer
//
//  Created by Maxim on 11.09.2025.
//

/*
 Example usage:

 @InMemoryContainerMacro
 struct UserModel {
     var id: String
     var name: String
     var email: String
 }

 // The macro automatically:
 // 1. Makes the struct conform to Sendable via extension
 // 2. Generates a Container struct that conforms to CacheContainerProtocol
 */

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import TCAPrintReducerTypes

public struct InMemoryContainerMacro: MemberMacro, ExtensionMacro {
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

    // Generate the Container struct using string interpolation for simplicity
    let containerCode = """
      struct Container: CacheContainerProtocol {
          var get: @Sendable () throws -> \(structName) = {
              return \(structName)()
          }

          var save: @Sendable (\(structName)) throws -> Void = { _ in
          }

          var delete: @Sendable () throws -> Void = {
          }

          static var liveValue: Self {
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

    return [DeclSyntax(stringLiteral: containerCode)]
  }

  // ExtensionMacro implementation
  public static func expansion(
    of _: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in _: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // Check if the declaration is a struct
    guard declaration.as(StructDeclSyntax.self) != nil else {
      throw MacroError.message("@InMemoryContainerMacro can only be applied to structs")
    }

    // Check if Sendable is already in the conforming protocols
    let alreadyConformsToSendable = protocols.contains { protocolType in
      protocolType.as(IdentifierTypeSyntax.self)?.name.text == "Sendable"
    }

    // If already conforms to Sendable, no need to add it
    if alreadyConformsToSendable {
      return []
    }

    // Generate Sendable conformance extension
    let extensionDecl = try ExtensionDeclSyntax(
      "extension \(type.trimmed): Sendable {}"
    )

    return [extensionDecl]
  }
}
