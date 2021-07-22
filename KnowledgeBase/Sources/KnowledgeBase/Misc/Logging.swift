//
//  Logging.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

import Foundation
import os

let kKBLoggingSubsystem = "com.gf.KnowledgeBase"
let kCKLogContextFramework = "Framework"
let kCKLogContextDaemon = "Daemon"


class KBLogger {

    static func framework() -> KBLogger {
        return KBLogger(OSLog(
            subsystem: kKBLoggingSubsystem,
            category: kCKLogContextFramework))
    }

    let osLog: OSLog

    init(_ osLog: OSLog) {
        self.osLog = osLog
    }
    
    func debug(_ message: StaticString, _ args: CVarArg...) {
        log(type: .debug, message, args)
    }
    
    func info(_ message: StaticString, _ args: CVarArg...) {
        log(type: .info, message, args)
    }
    
    func error(_ message: StaticString, _ args: CVarArg...) {
        log(type: .error, message, args)
    }
    
    func fault(_ message: StaticString, _ args: CVarArg...) {
        log(type: .fault, message, args)
    }

    /// Swift does not support splatting (https://bugs.swift.org/browse/SR-128)
    /// so we have to emulate VarArg splatting via a switch statement.
    private func log(type: OSLogType, _ message: StaticString, _ args: CVarArg...) {
        os_log(message, log: osLog, type: type, args)
//        switch args.count {
//        case 0: os_log(message, log: osLog, type: type)
//        case 1: os_log(message, log: osLog, type: type, args[0])
//        case 2: os_log(message, log: osLog, type: type, args[0], args[1])
//        case 3: os_log(message, log: osLog, type: type, args[0], args[1], args[2])
//        case 4: os_log(message, log: osLog, type: type, args[0], args[1], args[2], args[3])
//        case 5: os_log(message, log: osLog, type: type, args[0], args[1], args[2], args[3], args[4])
//        default: os_log("logging with variadic args > 5 is not implemented", log: osLog, type: .fault)
//        }
    }
}

let log = KBLogger.framework()
