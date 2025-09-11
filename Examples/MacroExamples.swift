//
//  MacroExamples.swift
//  TCAPrintReducer
//
//  Created by Maxim on 11.09.2025.
//

import ComposableArchitecture
import Foundation
import TCAPrintReducer

@InMemoryContainer
struct TestContainerModel: Sendable {
    // var appsflyerId = ""
    // var someProperty: String?

    init() {
        // self.appsflyerId = appsflyerId
    }
}

@InMemoryContainer
public struct TestPublicContainerModel: Sendable {
    // var appsflyerId = ""
    // var someProperty: String?

    public init() {
        // self.appsflyerId = appsflyerId
    }
}
