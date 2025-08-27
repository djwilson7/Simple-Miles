import Foundation
import os

final class AppLogger {
    static let shared = AppLogger()
    private let logger: Logger

    private init() {
        logger = Logger(subsystem: "com.yourapp.SimpleMiles", category: "General")
    }

    func log(_ message: String,
             file: String = #file,
             function: String = #function,
             line: Int = #line,
             level: OSLogType = .default) {
        let fileName = (file as NSString).lastPathComponent
        logger.log(level: level, "[\(fileName):\(line)] \(function) -> \(message)")
    }
}

func Log(_ message: String,
         file: String = #file,
         function: String = #function,
         line: Int = #line,
         level: OSLogType = .default) {
    AppLogger.shared.log(message, file: file, function: function, line: line, level: level)
}
