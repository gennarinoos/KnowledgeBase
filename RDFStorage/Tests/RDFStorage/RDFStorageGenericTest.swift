//
//  RDFStorageGenericTest.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/9/21.
//

import XCTest
@testable import RDFStorage

class CRDFStorageGenericTest : XCTestCase {

    func testInitializeWorld() {
        let storage = BaseRDFStore()
        do {
            try storage.execute(SPARQLQuery: "SELECT")
        } catch {
            XCTFail()
        }
    }
}

