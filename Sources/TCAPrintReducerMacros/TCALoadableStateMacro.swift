//
//  TCALoadableStateMacro.swift
//  TCAPrintReducer
//
//  Created by Maxim on 11.07.2025.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LoadableStateMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [
            """
            var loadingState: LoadingState = .none
            {
                @storageRestrictions(initializes: _loadingState)
                init(initialValue) {
                    _loadingState = initialValue
                }
                get {
                    _$observationRegistrar.access(self, keyPath: \\.loadingState)
                    return _loadingState
                }
                set {
                    _$observationRegistrar.mutate(self, keyPath: \\.loadingState, &_loadingState, newValue, _$isIdentityEqual)
                }
                _modify {
                  let oldValue = _$observationRegistrar.willModify(self, keyPath: \\.loadingState, &_loadingState)
                  defer {
                    _$observationRegistrar.didModify(self, keyPath: \\.loadingState, &_loadingState, oldValue, _$isIdentityEqual)
                  }
                  yield &_loadingState
                }
            }
            private var _loadingState: LoadingState = .none
            
            var errorAlertState: TCAAlertViewFeature.State = .init()
            {
                @storageRestrictions(initializes: _errorAlertState)
                init(initialValue) {
                    _errorAlertState = initialValue
                }
                get {
                    _$observationRegistrar.access(self, keyPath: \\.errorAlertState)
                    return _errorAlertState
                }
                set {
                    _$observationRegistrar.mutate(self, keyPath: \\.errorAlertState, &_errorAlertState, newValue, _$isIdentityEqual)
                }
                _modify {
                  let oldValue = _$observationRegistrar.willModify(self, keyPath: \\.errorAlertState, &_errorAlertState)
                  defer {
                    _$observationRegistrar.didModify(self, keyPath: \\.errorAlertState, &_errorAlertState, oldValue, _$isIdentityEqual)
                  }
                  yield &_errorAlertState
                }
            }
            @ObservationStateIgnored private  var _errorAlertState: TCAAlertViewFeature.State = .init()
            """
        ]
    }
}
