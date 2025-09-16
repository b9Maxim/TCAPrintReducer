import OSLog
import TCAPrintReducerTypes

// Re-export types for external visibility
public typealias CacheContainerNoDataFound = TCAPrintReducerTypes.CacheContainerNoDataFound
public typealias CacheContainerProtocol = TCAPrintReducerTypes.CacheContainerProtocol

@attached(
    member,
    names:
    named(ReducerLogger),
    named(reducerLogger)
)
public macro ReducerPrinterLog(
    subsystem: String,
    category: String,
    level: OSLogType = .info
) =
    #externalMacro(
        module: "TCAPrintReducerMacros",
        type: "TCAPrintReducerMacro"
    )

@attached(
    member,
    names:
    named(loadingState),
    named(_loadingState),
    named(errorAlertState),
    named(_errorAlertState)
)
public macro LoadableState() =
    #externalMacro(
        module: "TCAPrintReducerMacros",
        type: "LoadableStateMacro"
    )

@attached(
    member,
    names:
    named(init),
    named(mapping)
)
public macro EasyMappable() =
    #externalMacro(
        module: "TCAPrintReducerMacros",
        type: "EasyMappableMacro"
    )

@attached(
    member,
    names: named(Container)
)
public macro InMemoryContainer() =
    #externalMacro(
        module: "TCAPrintReducerMacros",
        type: "InMemoryContainerMacro"
    )
