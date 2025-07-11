
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

@attached(member, names: named(loadingState))
public macro LoadingState(
    
) = #externalMacro(module: "TCAPrintReducerMacros", type: "LoadingStateMacro")


@attached(member, names: named(loadingState))
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(_))
public macro LoadingState2(
    
) = #externalMacro(module: "TCAPrintReducerMacros", type: "LoadingState2Macro")

