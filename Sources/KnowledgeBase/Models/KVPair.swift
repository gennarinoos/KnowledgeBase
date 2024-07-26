//
//  File.swift
//  
//
//  Created by Gennaro on 13/06/24.
//

import Foundation

public typealias KBKVPairs = [String: Any]

public class KBKVObjcPairWithTimestamp: NSObject {
    public let key: String
    public let value: Any
    public let timestamp: Date
    
    init(key: String, value: Any, timestamp: Date) {
        self.key = key
        self.value = value
        self.timestamp = timestamp
    }
}

public struct KBKVPairWithTimestamp {
    public let key: String
    public let value: Any?
    public let timestamp: Date
}
