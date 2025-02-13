
import OSLog

@attached(member, names: named(swiftLog))
public macro ReducerPrinterLog(
    subsystem: String,
    category: String,
    level: OSLogType = .default
) = #externalMacro(module: "TCAPrintReducerMacros", type: "TCAPrintReducerMacro")
