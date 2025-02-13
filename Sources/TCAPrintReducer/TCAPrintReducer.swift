
import OSLog

@attached(member)
public macro ReducerPrinterLog(
    subsystem: String,
    category: String,
    level: OSLogType = .default
) = #externalMacro(module: "TCAPrintReducerMacros", type: "TCAPrintReducerMacro")
