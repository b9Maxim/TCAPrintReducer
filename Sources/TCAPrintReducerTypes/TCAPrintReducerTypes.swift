//
//  TCAPrintReducerTypes.swift
//  TCAPrintReducer
//
//  Created by Maxim on 11.09.2025.
//

import Foundation

public struct CacheContainerNoDataFound: Error, Equatable {
    public init() {}
}

public protocol CacheContainerProtocol: Sendable {
    associatedtype Model
    var get: @Sendable () throws -> Model { get }
    var save: @Sendable (Model) throws -> Void { get }
    var delete: @Sendable () throws -> Void { get }
}
