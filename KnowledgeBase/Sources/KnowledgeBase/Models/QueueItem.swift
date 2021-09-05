//
//  QueueItem.swift
//  
//
//  Created by Gennaro Frazzingaro on 9/4/21.
//

import Foundation

@objc(KBQueueItem)
public class KBQueueItem : NSObject {
    let identifier: String
    let value: Any
    let createdAt: Date
    
    init(identifier: String, value: Any, createdAt: Date) {
        self.identifier = identifier
        self.value = value
        self.createdAt = createdAt
    }
    
    convenience init(item: KBKVPairs, createdAt: Date) throws {
        guard item.count == 1 else {
            throw KBError.unexpectedData(item)
        }
        self.init(identifier: item.first!.key,
                  value: item.first!.value,
                  createdAt: createdAt)
    }
}
