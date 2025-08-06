
import OSLog

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
) = #externalMacro(module: "TCAPrintReducerMacros", type: "TCAPrintReducerMacro")

@attached(
    member,
    names:
        named(loadingState),
        named(_loadingState)
)
public macro LoadingState(
    
) = #externalMacro(module: "TCAPrintReducerMacros", type: "LoadingStateMacro")

@attached(
    member,
    names:
        named(loadingState),
        named(_loadingState),
        named(errorAlert),
        named(_errorAlert),
        named($errorAlert)
    
)
public macro LoadableState(
    
) = #externalMacro(module: "TCAPrintReducerMacros", type: "LoadableStateMacro")

