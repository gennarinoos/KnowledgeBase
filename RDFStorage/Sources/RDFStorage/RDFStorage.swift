//
//  File.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/9/21.
//

#if SWIFT_PACKAGE
import CRDFStorage
#endif
import Foundation

public class RDFStorage {
    
    let world: Any
    
    init() {
        world = librdf_new_world()
    }
}
