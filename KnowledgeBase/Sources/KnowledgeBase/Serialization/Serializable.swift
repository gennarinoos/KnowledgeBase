//
//  Serializable.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/22/21.
//

/// Protocol used for any serializable object
protocol Serializable {
    var encoded: String { get }
    static func decode(_ encoded: String) throws -> Self
}
