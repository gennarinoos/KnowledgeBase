//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 6/25/21.
//

import Foundation

extension Data {
    static func fromDatatypeValue(_ dataValue: Blob) -> Data {
        return Data(dataValue.bytes)
    }
    
    func datatypeValue() -> Blob {
        return withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Blob in
            return Blob(bytes: pointer.baseAddress!, length: count)
        }
    }
}
