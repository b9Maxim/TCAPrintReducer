
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
