//
//  CRDFStorageGenericTest.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/9/21.
//

import XCTest
@testable import RDFStorage

class CRDFStorageGenericTest : XCTestCase {

    func testInitializeWorld() {
        guard let world = librdf_new_world() else {
            XCTFail("Failed to initialize librdf_world")
        }
    }
}

