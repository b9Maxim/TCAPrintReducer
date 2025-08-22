//
//  EasyMappableMacro.swift
//  TCAPrintReducer
//
//  Created by Maxim on 22.08.2025.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/*
 Example usage:
 
 @EasyMappable
 struct IntroductionContainerModel: Sendable {
 var screens: [Screen] = []
 var title: String = ""
 var isEnabled: Bool = false
 
 init(screens: [Screen] = [], title: String = "", isEnabled: Bool = false) {
 self.screens = screens
 self.title = title
 self.isEnabled = isEnabled
 }
 
 // The macro automatically generates these methods:
 // init?(map: Map) {
 //     mapProperties(map: map)
 // }
 //
 // mutating func mapping(map: Map) {
 //     mapProperties(map: map)
 // }
 
 // You still need to implement this manually:
 mutating func mapProperties(map: Map) {
 screens <- map["screens"]
 title <- map["title"]
 isEnabled <- map["is_enabled"]
 }
 }
 
 // Usage:
 let json = ["screens": [], "title": "Welcome", "is_enabled": true]
 let model = IntroductionContainerModel(map: Map(json: json))
 */

public struct EasyMappableMacro: MemberMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Check if the declaration is a struct
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError("EasyMappable can only be applied to structs")
        }
        
        // Check if the struct conforms to Mappable
        let inheritanceClause = structDecl.inheritanceClause
        let conformsToMappable =
        inheritanceClause?.inheritedTypes.contains { inheritedType in
            inheritedType.type.as(SimpleTypeIdentifierSyntax.self)?.name.text == "Mappable"
        } ?? false
        
        if !conformsToMappable {
            throw MacroError(
        """
        @EasyMappable struct must conform to Mappable protocol.
        Add 'Mappable' to your struct declaration:
        struct \(structDecl.name): Sendable, Mappable {
        """)
        }
        
        // Check if the struct contains the required mapProperties function
        let hasMapPropertiesFunction = structDecl.memberBlock.members.contains { member in
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                return functionDecl.name.text == "mapProperties"
                && functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.parameterClause.parameters.first?.type.as(
                    SimpleTypeIdentifierSyntax.self)?.name.text == "Map"
            }
            return false
        }
        
        if !hasMapPropertiesFunction {
            throw MacroError(
        """
        @EasyMappable struct should implement 'mutating func mapProperties(map: Map)'.
        Add this function to your struct:
        mutating func mapProperties(map: Map) {
            // your mapping logic here
        }
        """
            )
        }
        
        // Check if the struct is public
        let isPublic = structDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public)
        }
        
        // Generate the init?(map: Map) implementation
        let initMap: DeclSyntax = {
            if isPublic {
                return DeclSyntax(
                        """
                        public init?(map: Map) {
                            mapProperties(map: map)
                        }
                        """
                )
            } else {
                return DeclSyntax(
                        """
                        init?(map: Map) {
                            mapProperties(map: map)
                        }
                        """
                )
            }
        }()
        
        // Generate the mutating func mapping(map: Map) implementation
        let mappingFunc: DeclSyntax = {
            if isPublic {
                return DeclSyntax(
                          """
                          public mutating func mapping(map: Map) {
                              mapProperties(map: map)
                          }
                          """
                )
            } else {
                return DeclSyntax(
                        """
                        mutating func mapping(map: Map) {
                            mapProperties(map: map)
                        }
                        """
                )
            }
        }()
        
        return [initMap, mappingFunc]
    }
}

public enum MacroError: Error, CustomStringConvertible {
    case message(String)
    
    public init(_ message: String) {
        self = .message(message)
    }
    
    public var description: String {
        switch self {
        case let .message(message):
            return message
        }
    }
}
