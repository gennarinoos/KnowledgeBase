//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/25/21.
//

import Foundation

enum KBDataVaultClass : String {
case KBGenericDataVaultClass = "KnowledgeBase"
}

struct KBDataVault {
    static func create(at path: String, withClass `class`: KBDataVaultClass) throws {
        
        // Create directory using KBGenericDataVaultClass
        
    }
}
