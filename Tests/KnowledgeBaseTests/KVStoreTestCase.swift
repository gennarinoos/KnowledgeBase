//
//  KVStoreTestCase.swift
//  
//
//  Created by Gennaro Frazzingaro on 7/11/21.
//

import XCTest
@testable import KnowledgeBase

protocol KBXCTestCase {
    func sharedStore() -> KBKVStore
}

class KVStoreTestCase : XCTestCase, KBXCTestCase {
    
    private let internalStore = KBKVStore.store(.inMemory)!

    func sharedStore() -> KBKVStore {
        internalStore
    }

    internal func cleanup() {
        do {
            let store = self.sharedStore()
            let _ = try store.removeAll()
            let keys = try store.keys()
            XCTAssert(keys.count == 0, "Removed all values")
        } catch {
            XCTFail("\(error)")
        }
    }

    override func setUp() {
        self.cleanup()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        self.cleanup()
    }

    func isEqual(_ a: Any, _ b: Any) -> Bool {
        if var a = a as? Array<Any> {
            guard var b = b as? Array<Any> else { return false }
            guard b.count == a.count else { return false }
            if let aS = a as? Array<String>, let bS = a as? Array<String> {
                a = aS.sorted()
                b = bS.sorted()
            }
            if let aS = a as? Array<Dictionary<String, Any>>, let bS = a as? Array<Dictionary<String, Any>> {
                let sortCriteria = {
                    (x: Dictionary<String, Any>, y: Dictionary<String, Any>) in
                    String(describing: x["@id"]) < String(describing: y["@id"])
                }
                a = aS.sorted(by: sortCriteria)
                b = bS.sorted(by: sortCriteria)
            }
            for (idx, entity) in a.enumerated() {
                if (!self.isEqual(entity, b[idx])) {
                    return false
                }
            }
            return true
        } else if let a = a as? Dictionary<String, Any> {
            guard let b = b as? Dictionary<String, Any> else { return false }
            for (k, v) in a {
                if (!self.isEqual(v, b[k]!)) {
                    return false
                }
            }
            return true
        } else if let a = a as? String {
            guard let b = b as? String else { return false }

            return (a == b)
        } else if let a = a as? Int {
            guard let b = b as? Int else { return false }

            return (a == b)
        } else if let a = a as? Double {
            guard let b = b as? Double else { return false }

            return (a == b)
        }

        print("\(#function): Cannot compare \(a) and \(b)")
        return false
    }
    
    func testPartialKeysAndValues() {
        do {
            try self.sharedStore().set(value: "stringVal", for: "string")
            print(try self.sharedStore().dictionaryRepresentation())
            try self.sharedStore().set(value: 1, for: "int")
            try self.sharedStore().set(value: true, for: "bool")
            try self.sharedStore().set(value: false, for: "NOTbool")
            try self.sharedStore().set(value: ["first", "second"], for: "array")
            try self.sharedStore().set(value: ["first": "first", "second": "second"], for: "dictionary")
            
            let stringOrBool = KBGenericCondition(.equal, value: "string").or(KBGenericCondition(.equal, value: "bool"))

            var partialKeysAndValues = try self.sharedStore().dictionaryRepresentation(forKeysMatching: stringOrBool) as Dictionary
            XCTAssertEqual(partialKeysAndValues.keys.count, 2)
            XCTAssertEqual(partialKeysAndValues["string"] as? String, "stringVal")
             XCTAssertEqual(partialKeysAndValues["bool"] as? Bool, true)

            var partialKeys = try self.sharedStore().keys(matching: stringOrBool).sorted { $0.compare($1) == .orderedAscending }
            XCTAssert(partialKeys.count == 2)
            XCTAssertEqual(partialKeys, ["bool", "string"])

            var partialValues = try self.sharedStore().values(for: partialKeys) as [Any?]
            XCTAssert(partialValues.count == 2)

            partialValues = try self.sharedStore().values(forKeysMatching: stringOrBool)
            XCTAssert(partialValues.count == 2)

            let startWithSOrEndsWithOl = KBGenericCondition(.beginsWith, value: "s").or(KBGenericCondition(.endsWith, value: "ol"))
            partialKeysAndValues = try self.sharedStore().dictionaryRepresentation(forKeysMatching: startWithSOrEndsWithOl) as Dictionary
            XCTAssertEqual(partialKeysAndValues.keys.count, 3)
            XCTAssertEqual(partialKeysAndValues["string"] as? String, "stringVal")
            // TODO: rdar://50960552
            // XCTAssertEqual(partialKeysAndValues["bool"] as? Bool, true)
            // XCTAssertEqual(partialKeysAndValues["NOTbool"] as? Bool, false)

            partialKeys = try self.sharedStore().keys(matching: startWithSOrEndsWithOl).sorted { $0.compare($1) == .orderedAscending }
            XCTAssertEqual(partialKeys.count, 3)
            XCTAssertEqual(partialKeys, ["NOTbool", "bool", "string"])

            partialValues = try self.sharedStore().values(for: partialKeys) as [Any?]
            XCTAssertEqual(partialValues.count, 3)

            partialValues = try self.sharedStore().values(forKeysMatching: startWithSOrEndsWithOl)
            XCTAssertEqual(partialValues.count, 3)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testAllKeyValues() throws {
        try self.sharedStore().set(value: "stringVal", for: "string")
        try self.sharedStore().set(value: 1, for: "int")
        try self.sharedStore().set(value: true, for: "bool")
        try self.sharedStore().set(value: false, for: "NOTbool")
        try self.sharedStore().set(value: ["first", "second"], for: "array")
        try self.sharedStore().set(value: ["first": "first", "second": "second"], for: "dictionary")
        
        let kvPairs = try self.sharedStore().dictionaryRepresentation() as Dictionary
        XCTAssertEqual(kvPairs.count, 6)
        XCTAssertEqual(kvPairs["string"] as? String, "stringVal")
        XCTAssertEqual(kvPairs["int"] as? Int, 1)
        XCTAssertEqual(kvPairs["bool"] as? Bool, true)
        XCTAssertEqual(kvPairs["NOTbool"] as? Bool, false)

        let arrayValue = kvPairs["array"] as! [String]
        XCTAssertEqual(arrayValue.count, 2)
        XCTAssertEqual(arrayValue[0], "first")
        XCTAssertEqual(arrayValue[1], "second")

        let dictValue = kvPairs["dictionary"] as! [String:String]
        XCTAssertEqual(dictValue.count, 2)
        XCTAssertEqual(dictValue["first"], "first")
        XCTAssertEqual(dictValue["second"], "second")

        let keys = try self.sharedStore()
            .keys(matching: KBGenericCondition(value: true))
            .sorted { $0.compare($1) == .orderedAscending }

        XCTAssertEqual(keys, ["NOTbool", "array", "bool", "dictionary", "int", "string"])

        let keyedValues = try self.sharedStore().values(for: keys)
        XCTAssertEqual(keyedValues.count, 6)

        let conditionalValues = try self.sharedStore().values(forKeysMatching: KBGenericCondition(value: true))
        XCTAssertEqual(conditionalValues.count, 6)
    }
    
    func testKeyValuesAndTimestampsWithPagination() throws {
        try self.sharedStore().set(value: "stringVal", for: "string")
        try self.sharedStore().set(value: 100, for: "integer")
        
        var kvPairs = try self.sharedStore().keyValuesAndTimestamps(forKeysMatching: KBGenericCondition(value: true))
        XCTAssertEqual(kvPairs.count, 2)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "stringValue")
        )
        XCTAssertEqual(kvPairs.count, 0)
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "stringValue"),
            paginate: KBPaginationOptions(limit: 1, offset: 0),
            sort: .none
        )
        XCTAssertEqual(kvPairs.count, 0)
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "stringValue"),
            sort: .ascending
        )
        XCTAssertEqual(kvPairs.count, 0)
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "stringValue"),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 0)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string")
        )
        XCTAssertEqual(kvPairs.count, 1)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 1, offset: 0)
        )
        XCTAssertEqual(kvPairs.count, 1)
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 10, offset: 0)
        )
        XCTAssertEqual(kvPairs.count, 1)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 1, offset: 0),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 1)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 1, offset: 0),
            sort: .ascending
        )
        XCTAssertEqual(kvPairs.count, 1)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 1, offset: 1)
        )
        XCTAssertEqual(kvPairs.count, 0)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 1, offset: 1),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 0)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 1, offset: 1),
            sort: .ascending
        )
        XCTAssertEqual(kvPairs.count, 0)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 0, offset: 1)
        )
        XCTAssertEqual(kvPairs.count, 1)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.equal, value: "string"),
            paginate: KBPaginationOptions(limit: 10, offset: 0),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 1)
        
        try self.sharedStore().set(value: "stringVal", for: "string-2")
        try self.sharedStore().set(value: "stringVal", for: "string-3")
        try self.sharedStore().set(value: "stringVal", for: "string-4")
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "string"),
            paginate: KBPaginationOptions(limit: 10, offset: 0),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 4)
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "string"),
            paginate: KBPaginationOptions(limit: 2, offset: 1),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 2)
        XCTAssertEqual(kvPairs[0].key, "string-3")
        XCTAssertEqual(kvPairs[1].key, "string-2")
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "string"),
            paginate: KBPaginationOptions(limit: 2, offset: 1),
            sort: .ascending
        )
        XCTAssertEqual(kvPairs.count, 2)
        XCTAssertEqual(kvPairs[0].key, "string-2")
        XCTAssertEqual(kvPairs[1].key, "string-3")
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "string"),
            paginate: KBPaginationOptions(limit: 2, offset: 2),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 2)
        XCTAssertEqual(kvPairs[0].key, "string-2")
        XCTAssertEqual(kvPairs[1].key, "string")
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "string"),
            paginate: KBPaginationOptions(limit: 2, offset: 0),
            sort: .descending
        )
        XCTAssertEqual(kvPairs.count, 2)
        XCTAssertEqual(kvPairs[0].key, "string-4")
        XCTAssertEqual(kvPairs[1].key, "string-3")
        
        kvPairs = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "string"),
            paginate: KBPaginationOptions(limit: 2, offset: 2),
            sort: .ascending
        )
        XCTAssertEqual(kvPairs.count, 2)
        XCTAssertEqual(kvPairs[0].key, "string-3")
        XCTAssertEqual(kvPairs[1].key, "string-4")
    }
    
    func testPaginateSortLargerKVS() throws {
        
        try self.sharedStore().set(value: "", for: "assets-groups::149e537215b18931d53a5b2587228c2a6441187664d766050accded19db13706253c707eb6ea81eabe8cb85fb9953e18092673474a968e0c7926d13e01873ab4::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::7F771C1A-784F-45CE-81B8-F70B5E20BC3B")
        try self.sharedStore().set(value: "", for: "assets-groups::149e537215b18931d53a5b2587228c2a6441187664d766050accded19db13706253c707eb6ea81eabe8cb85fb9953e18092673474a968e0c7926d13e01873ab4::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::95C6C400-D806-487E-8B43-67B406EC2CB8")
        try self.sharedStore().set(value: "", for: "assets-groups::149e537215b18931d53a5b2587228c2a6441187664d766050accded19db13706253c707eb6ea81eabe8cb85fb9953e18092673474a968e0c7926d13e01873ab4::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::A4D77FBF-0EFB-49BD-B30A-AC7E5CBF1542")
        try self.sharedStore().set(value: "", for: "assets-groups::149e537215b18931d53a5b2587228c2a6441187664d766050accded19db13706253c707eb6ea81eabe8cb85fb9953e18092673474a968e0c7926d13e01873ab4::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::A64350B1-367C-427A-82A1-AC563AD3D6ED")
        try self.sharedStore().set(value: "", for: "assets-groups::149e537215b18931d53a5b2587228c2a6441187664d766050accded19db13706253c707eb6ea81eabe8cb85fb9953e18092673474a968e0c7926d13e01873ab4::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::ECEDA9C1-3BAC-44B7-8ABA-796CD9F30781")
        try self.sharedStore().set(value: "", for: "assets-groups::149e537215b18931d53a5b2587228c2a6441187664d766050accded19db13706253c707eb6ea81eabe8cb85fb9953e18092673474a968e0c7926d13e01873ab4::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::F32187ED-5955-4DF4-A427-8FB1271137A7")
        try self.sharedStore().set(value: "", for: "assets-groups::a2576e791d6b4bbd648d27516fd9e4605416688859139e68cdc46d64b7abc6bb785cdd7f79f0611070f200ca179037be92987c675092f2804d880450f9207808::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::4860E4C0-0CA2-4BB7-B3C8-6BC448F73463")
        try self.sharedStore().set(value: "", for: "assets-groups::aff415d6b33fb7d24c237a7f6dda92dd0ebd833f99eabf0b8f3127c9258c447211568460d1d16a4137c6e20a4c0306260435f71e112c78688ea3938ced4ff3cf::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::7C3B495F-B015-478B-A918-5DD199D21A1D")
        try self.sharedStore().set(value: "", for: "assets-groups::d5d802d83a93152fa83d04d7cc895976896bc2d9c54e1a86117915b89eda19f5202516144218180a056d8b2c039e25bca616dccf1c77b111dc24853c09ccc0e0::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::697BEC21-1B57-4CA2-B60C-C205E0FF1573")
        try self.sharedStore().set(value: "", for: "assets-groups::d5d802d83a93152fa83d04d7cc895976896bc2d9c54e1a86117915b89eda19f5202516144218180a056d8b2c039e25bca616dccf1c77b111dc24853c09ccc0e0::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::AA1940ED-8DED-4EBB-B659-7FB5ADE389DA")
        try self.sharedStore().set(value: "", for:  "assets-groups::d5d802d83a93152fa83d04d7cc895976896bc2d9c54e1a86117915b89eda19f5202516144218180a056d8b2c039e25bca616dccf1c77b111dc24853c09ccc0e0::bbb835f3b47aaba9bb0961d725c95d900da329964060e5bad1594ac0a7977a5e572b08fa4f8a5cc5fec99646d1c32069de6d84408cc0fc02eae1ec3f0f156956::::::06157A8C-CEB0-484B-A5D0-DFCC2BF04C7C")
        try self.sharedStore().set(value: "", for:  "assets-groups::d5d802d83a93152fa83d04d7cc895976896bc2d9c54e1a86117915b89eda19f5202516144218180a056d8b2c039e25bca616dccf1c77b111dc24853c09ccc0e0::bbb835f3b47aaba9bb0961d725c95d900da329964060e5bad1594ac0a7977a5e572b08fa4f8a5cc5fec99646d1c32069de6d84408cc0fc02eae1ec3f0f156956::::::C157F18A-966D-4388-8029-05CB4B83DEC9")
        try self.sharedStore().set(value: "", for:  "assets-groups::e6b0f3d6498070257b0dd6de912e8a6cbf595d502713f15751881d7bfc58149d46cb6fc71a736bf5967fdc86126edd29708d060e76a3f5a06ab8d6f8c33a1037::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::060EAB63-AD40-4EB6-A366-8639E6FC1795")
        try self.sharedStore().set(value: "", for:  "assets-groups::e6b0f3d6498070257b0dd6de912e8a6cbf595d502713f15751881d7bfc58149d46cb6fc71a736bf5967fdc86126edd29708d060e76a3f5a06ab8d6f8c33a1037::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::73CF3B95-DB5E-4811-BD47-248D8F7985B3")
        try self.sharedStore().set(value: "", for:  "assets-groups::e6b0f3d6498070257b0dd6de912e8a6cbf595d502713f15751881d7bfc58149d46cb6fc71a736bf5967fdc86126edd29708d060e76a3f5a06ab8d6f8c33a1037::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::7BE59AD4-8A21-45C4-80A3-83A7FC543B1C")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::884CE2BB-0E35-4C43-89C2-3A8E395F9DC4")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::8BFF93B0-7A60-477A-9203-DECB20B792DB")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::B7C604C6-E122-4057-B048-EBB8BC8A22EC")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::EBF77DCE-9667-4FA3-8F31-0B9398A9CE18")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::bbb835f3b47aaba9bb0961d725c95d900da329964060e5bad1594ac0a7977a5e572b08fa4f8a5cc5fec99646d1c32069de6d84408cc0fc02eae1ec3f0f156956::::::0512DC53-9F0A-4058-8C89-EDF69B6D02AC")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::bbb835f3b47aaba9bb0961d725c95d900da329964060e5bad1594ac0a7977a5e572b08fa4f8a5cc5fec99646d1c32069de6d84408cc0fc02eae1ec3f0f156956::::::37F29C0A-C18A-4BBC-BC4E-892AA443782F")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::bbb835f3b47aaba9bb0961d725c95d900da329964060e5bad1594ac0a7977a5e572b08fa4f8a5cc5fec99646d1c32069de6d84408cc0fc02eae1ec3f0f156956::::::65B92AD3-0700-4B2C-80BE-01EC3A989E91")
        try self.sharedStore().set(value: "", for:  "user-threads::06DBDE36-6727-4E03-8E21-F5C92616346A::bbb835f3b47aaba9bb0961d725c95d900da329964060e5bad1594ac0a7977a5e572b08fa4f8a5cc5fec99646d1c32069de6d84408cc0fc02eae1ec3f0f156956::::::E4253DA4-BB34-4BAF-85B5-09535B6A6D66")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::03135C4E-16ED-4D8A-B8BB-A4596F172C2A")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::10E646F7-B7B6-474D-805A-F031E9E6BD87")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::11C3BFFC-9109-46FB-BA65-48DB6ACF84B4")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::1A049926-0AC0-42BC-A3D2-1C1B855E9B24")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::251F027B-4E97-4F68-8E68-CB2B687BE80F")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::34FC59C1-6F62-408C-ADB8-185F130C0AB5")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::368CA3CF-B103-4087-9B97-8EC907A4C0F4")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::3CF54684-F5AC-47E0-8DD2-826915D8ADAA")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::5F513889-73E3-4149-A3B5-C02FB2D4BA0D")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::630F497A-32C9-41AD-9943-71FCC212C1FA")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::65B2ACD7-CDA2-4D43-8A8D-CD518D785E72")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::6A6F7559-52D8-4E31-8BBA-D66ABC8CC1C5")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::6C0BEC23-AEFB-42AE-BA01-88686D07B8F5")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::71218AAA-F33A-4946-86CB-3437E5FBB644")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::72B5AF87-EB22-4090-B933-115A84D623BB")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::7CC34EA9-1683-45BB-91DA-E45A5ACCDFED")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::8106CD98-1336-424D-82C6-28E286D419C9")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::855D8EA7-A319-417F-B892-75B866D4B843")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::877765D6-A0F0-4267-A3D2-D363EDA36D45")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::893DA26D-5CB2-4EE1-8C87-40817DF55403")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::8B38AD54-2BAB-42B3-8321-57630AC9DC70")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::8CBDD0C2-B566-4CFD-A9E4-04C1A9460695")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::8F39071B-482C-4D12-8442-AF2D1DDD7CFD")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::8F9FF0A9-4947-4BA0-95F9-2D38B0E67C3C")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::91E19AFB-0BC3-4FA2-BE0C-582E556EB90F")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::95B2A226-1A8D-4CBE-937A-55C70F7E0B37")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::99C07832-3A4C-4999-A3F1-E74802C810AA")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::A2273C83-880F-4C36-90D9-189F28A1BCC8")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::A53A0F88-39BA-4FF6-96AC-C33C8BF84D0A")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::B275CA05-9073-4C4D-9E2C-411EDE63FB93")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::B37F93AF-140B-475F-B6B1-A0859EFC6789")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::C7AC779A-7AF3-4814-81D8-950E4F65FF4F")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::CE237408-1FAF-4F70-BCC2-0F6A9E258111")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::CE53B0EB-214B-4054-9696-B502FADBCCC9")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::E3B30B9F-404B-48A7-BD36-12E3B4BA9B6A")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::E7030E16-7FFA-41EA-8A4A-1B2EC942E336")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::ED5366BE-6E6A-4285-9D3A-88463FBFD5CD")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::ED77D8BC-CE79-44FB-B6C1-59E7F3E862F1")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::EE8DC210-CCC6-4744-8B2B-33B786AABA94")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::F67EF21F-0B50-44C9-8E92-75BF08938D2E")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::F7F619A4-96D6-4D6D-B8F5-F531CE753AE1")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::22ab6bd75f3649151a9442be3028a69be9e4f09df7c13211e73f52d4bce19bfd40e66101e69a3de895e2919b2206ad6827f5d433e8c33584397d3d822b9a00fe::::::FCDB2958-6DD1-4604-A01A-7AF67DC95523")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::19797B63-FA90-436B-86F6-7805A0D5292F")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::2541EE50-4C1F-404D-96D8-54868C45E6BE")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::2A3E1AFF-9209-43ED-B26F-1F008F601F66")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::33BD1EA3-9241-4FBA-8208-2E3A795C99C3")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::3461C2D1-31D0-4594-B760-ED9AB79A8BC3")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::4C93FD13-694D-44F8-8F81-6D117DB3DBAA")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::530FC9F9-7F35-4E77-B89D-FF510ED263F7")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::5BA82B6C-BF2F-483E-8633-95C9557DFB1F")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::5BC9B3CF-9D1D-4B21-803D-0195653092A6")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::5DABA4D5-341E-4BD2-85B9-84FC1ED9B149")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::6AA66A44-A81A-4FD3-8C2C-2E438FFEFA4A")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::7DC3F858-2F89-4A07-B677-72C6D5F14C06")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::8487519F-76FB-4822-A91C-E6A484E8D1A4")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::87C81636-503B-455B-8E7C-59BA3A65C6E9")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::9CF70F98-8D90-4CCB-A829-E43DC0E2CC67")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::A7F0E3D6-B9DD-4026-8DFC-4C00EB5C6493")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::AA2F5F8C-F11F-42EA-985F-8F9F8ADFA3D0")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::AC8C22C9-7809-4EBC-9D53-7053C52E18C2")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::B6F2F107-9729-4868-ABED-4D645910DE95")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::BD1BCDF3-6424-4B67-A228-3807CB84028E")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::BFE1EC67-239D-40E6-987A-9FD996D8A399")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::D7B88C84-3E33-4E9A-85A4-D3C9DB70C633")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::F6664013-CA5B-49E5-988A-3028D3E04028")
        try self.sharedStore().set(value: "", for:  "user-threads::07552F8E-4100-4063-930C-1B6AB134590E::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::F9CC2A93-06A4-4ED7-94C4-02C0AE249C5C")
        try self.sharedStore().set(value: "", for:  "user-threads::4FFB7DC9-18A0-4AC1-BE5F-37009B2009A0::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::6E944DC3-E6A2-456F-8A02-E42924A45041")
        try self.sharedStore().set(value: "", for:  "user-threads::4FFB7DC9-18A0-4AC1-BE5F-37009B2009A0::534da6b979c47d89bfade29f28fec65851160ff6dfd9602a058f74ec6c373d948ec954e252ff2a55e546c04e61ac0abc264a327f7ec7a15e6a6d1c66c1c30d27::::::A0FD1B90-8B42-44F2-845E-C3E624DF49D3")
        try self.sharedStore().set(value: "", for:  "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::664C4460-EA11-4B4D-A190-49CE3DD06667")
        try self.sharedStore().set(value: "", for:  "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::8A758BC9-7576-40BE-B627-7DC146D6FBDF")
        
        var kvts = try self.sharedStore().keyValuesAndTimestamps(forKeysMatching: KBGenericCondition(.beginsWith, value: "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6"))
        XCTAssertEqual(kvts.count, 2)
        
        kvts = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6"),
            sort: .descending
        )
        XCTAssertEqual(kvts[0].key, "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::8A758BC9-7576-40BE-B627-7DC146D6FBDF")
        XCTAssertEqual(kvts[1].key, "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::664C4460-EA11-4B4D-A190-49CE3DD06667")
        XCTAssertEqual(kvts.count, 2)
        
        kvts = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6"),
            sort: .ascending
        )
        XCTAssertEqual(kvts.count, 2)
        XCTAssertEqual(kvts[0].key, "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::664C4460-EA11-4B4D-A190-49CE3DD06667")
        XCTAssertEqual(kvts[1].key, "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::8A758BC9-7576-40BE-B627-7DC146D6FBDF")
        
        kvts = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6"),
            paginate: KBPaginationOptions(limit: 1, offset: 0),
            sort: .descending
        )
        XCTAssertEqual(kvts.count, 1)
        XCTAssertEqual(kvts.first!.key, "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::8A758BC9-7576-40BE-B627-7DC146D6FBDF")
        
        kvts = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6"),
            paginate: KBPaginationOptions(limit: 1, offset: 0),
            sort: .ascending
        )
        XCTAssertEqual(kvts.count, 1)
        XCTAssertEqual(kvts.first!.key, "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::664C4460-EA11-4B4D-A190-49CE3DD06667")
        
        kvts = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6"),
            paginate: KBPaginationOptions(limit: 1, offset: 1),
            sort: .ascending
        )
        XCTAssertEqual(kvts.count, 1)
        XCTAssertEqual(kvts.first!.key, "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6::5bfa6d1e5729a7d50479da04af83378be8a4c64fac75fffd9cbd10e1a003490b15c1a0f5f181790f5631a6e8a070d14792ba154cbb573c34760b2ca3c9a23ef8::::::8A758BC9-7576-40BE-B627-7DC146D6FBDF")
        
        
        kvts = try self.sharedStore().keyValuesAndTimestamps(
            forKeysMatching: KBGenericCondition(.beginsWith, value: "user-threads::FEA6508C-688E-4CB4-8FDA-0A96C52313F6"),
            paginate: KBPaginationOptions(limit: 1, offset: 2),
            sort: .descending
        )
        XCTAssertEqual(kvts.count, 0)
    }
    
    struct NonNSSecureCodingCompliantStruct {
    }
    
    class NonNSSecureCodingCompliantClass {
    }
    
    func testSetValueForKeyUnsecure() throws {
        let key = "NonNSSecureCodingCompliant"
        let emptyString = ""

        for nonSecureValue in [NonNSSecureCodingCompliantStruct(), NonNSSecureCodingCompliantClass()] as [Any] {
            try self.sharedStore().set(value: emptyString, for: key)
            
            let stringValue = try self.sharedStore().value(for: key)
            XCTAssertNotNil(stringValue as? String)
            XCTAssert((stringValue as? String) == emptyString)
            
            try self.sharedStore().set(value: nonSecureValue, for: key)
            let invalidValue = try self.sharedStore().value(for: key)
            XCTAssertNotNil(invalidValue as? String)
            XCTAssert((invalidValue as? String) == emptyString)
            
            do { try self.sharedStore().removeValue(for: key) } catch { XCTFail() }
            let removedValue = try self.sharedStore().value(for: key)
            XCTAssertNil(removedValue)
            
            try self.sharedStore().set(value: nonSecureValue, for: key)
            let invalidValue2 = try self.sharedStore().value(for: key)
            XCTAssertNil(invalidValue2)
        }
        
        let triple = KBTriple(subject: "Luca", predicate: "is", object: "awesome", weight: 1)
        try self.sharedStore().set(value: triple, for: key)
        let tripleValue = try self.sharedStore().value(for: key)
        XCTAssertNotNil(tripleValue)
        XCTAssert((tripleValue as? KBTriple) == triple)
    }

    func testWriteBatch() throws {
        let writeBatch = self.sharedStore().writeBatch()
        writeBatch.set(value: "stringVal", for: "string")
        writeBatch.set(value: 1, for: "int")
        writeBatch.set(value: true, for: "bool")
        writeBatch.set(value: false, for: "NOTbool")
        writeBatch.set(value: ["first", "second"], for: "array")
        writeBatch.set(value: ["first": "first", "second": "second"], for: "dictionary")
        do {
            try writeBatch.write()
        } catch {
            XCTFail("\(error)")
        }

        let none = try self.sharedStore().value(for: "none")
        XCTAssert(none == nil, "non existing attribute")

        let string = try self.sharedStore().value(for: "string")
        XCTAssert(string != nil, "string exists")
        XCTAssert((string as? String) != nil, "string is a string")
        XCTAssert((string as? String) == "stringVal", "string value matches")

        let int = try self.sharedStore().value(for: "int")
        XCTAssert(int != nil, "int exists")
        XCTAssert((int as? Int) != nil, "int is an int")
        XCTAssert((int as? Int) == 1, "int value matches")

        let bool = try self.sharedStore().value(for: "bool")
        XCTAssert(bool != nil, "bool exists")
        XCTAssert((bool as? Bool) != nil, "bool is a bool")
        XCTAssert((bool as? Bool) == true, "bool value matches")
        let notbool = try self.sharedStore().value(for: "NOTbool")
        XCTAssert((notbool as? Bool) != nil, "NOTbool is a bool")
        XCTAssert((notbool as? Bool) == false, "NOTbool value matches")

        let array = try self.sharedStore().value(for: "array")
        XCTAssert(array != nil, "array exists")
        XCTAssert((array as? Array<String>) != nil, "array is an array")
        if let array = array as? Array<String> {
            XCTAssert(array.count == 2, "array count matches")
            XCTAssert(array == ["first", "second"], "array values match")
        }

        var dict = try self.sharedStore().value(for: "dictionary")
        XCTAssert(dict != nil, "dictionary exists")
        XCTAssert((dict as? Dictionary<String, String>) != nil, "dict is a dictionary")
        if let dict = array as? Dictionary<String, String> {
            XCTAssert(dict.keys.count == 2, "dictionary keys count matches")
            XCTAssert(dict["first"] == "first", "dictionary first value matches")
            XCTAssert(dict["second"] == "second", "dictionary second value matches")
        }
        
        try self.sharedStore().set(value: nil, for: "dictionary")
        dict = try self.sharedStore().value(for: "dictionary")
        XCTAssert(dict == nil, "dictionary has been removed")
        
        writeBatch.set(value: nil, for: "bool")
        writeBatch.set(value: nil, for: "NOTbool")
        do {
            try writeBatch.write()
        } catch {
            XCTFail("\(error)")
        }
        let b = try self.sharedStore().value(for: "bool")
        XCTAssertNil(b)
        let nb = try self.sharedStore().value(for: "NOTbool")
        XCTAssertNil(nb)
    }
}

class KnowledgeStoreTestCase : KVStoreTestCase {
    
    private let internalStore = KBKnowledgeStore.store(.inMemory)!
    
    override func sharedStore() -> KBKVStore {
        internalStore
    }
    
    func sharedKnowledgeStore() -> KBKnowledgeStore {
        self.sharedStore() as! KBKnowledgeStore
    }
    
    override func cleanup() {
        super.cleanup()
        
        do {
            let store = self.sharedKnowledgeStore()
            let _ = try store.removeAll()
            let keys = try store.triples(matching: KBTripleCondition(value: true))
            XCTAssert(keys.count == 0, "Removed all triple values")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    // Test times out. It tests unused, unmaintained code.
    func testLinkUnlink() {
        do {
            let subject = sharedKnowledgeStore().entity(withIdentifier: "subject")
            let predicate = "predicate"
            let object = sharedKnowledgeStore().entity(withIdentifier: "object")

            try subject.link(to: object, withPredicate: predicate)

            var hexaCount = try sharedKnowledgeStore().keys().count
            XCTAssert(hexaCount == 6, "1 hexatuple. \(hexaCount) tuples")

            let condition = KBTripleCondition(subject: subject.identifier,
                                              predicate: predicate,
                                              object: object.identifier)
            var triples = try sharedKnowledgeStore().triples(matching: condition)
            XCTAssert(triples.count == 1, "one triple. \(triples.count)")
            XCTAssert(triples[0].weight == 1, "weight is 1. \(triples[0].weight)")

            try subject.unlink(to: object, withPredicate: predicate)

            hexaCount = try sharedKnowledgeStore().keys().count
            XCTAssertEqual(hexaCount, 0, "Tuples removed")

            triples = try sharedKnowledgeStore().triples(matching: condition)
            XCTAssert(triples.count == 0, "no triples. \(triples.count)")

            try subject.link(to: object, withPredicate: predicate)
            try subject.link(to: object, withPredicate: predicate)

            hexaCount = try sharedKnowledgeStore().keys().count
            XCTAssert(hexaCount == 6, "1 hexatuple. \(hexaCount) tuples")

            triples = try sharedKnowledgeStore().triples(matching: condition)
            XCTAssert(triples.count == 1, "no triples. \(triples.count)")
            XCTAssert(triples[0].weight == 2, "weight is 2. \(triples[0].weight)")

            try subject.unlink(to: object, withPredicate: predicate)

            hexaCount = try sharedKnowledgeStore().keys().count
            XCTAssert(hexaCount == 6, "1 hexatuple. \(hexaCount) tuples")

            triples = try sharedKnowledgeStore().triples(matching: condition)
            XCTAssert(triples.count == 1, "no triples. \(triples.count)")
            XCTAssert(triples[0].weight == 1, "weight is 1. \(triples[0].weight)")
            
            try sharedKnowledgeStore().backingStore.setWeight(forLinkWithLabel: predicate,
                                                              between: subject.identifier,
                                                              and: object.identifier,
                                                              toValue: 4)
            triples = try sharedKnowledgeStore().triples(matching: condition)
            XCTAssert(triples.count == 1, "no triples. \(triples.count)")
            XCTAssert(triples[0].weight == 4, "weight is 4. \(triples[0].weight)")

        } catch {
            XCTFail("\(error)")
        }
    }

    // Test fails. It test unused, unmaintained code.
    func testDuplicateLinkingWithCompletionHandler() {
        do {
            var triples: [KBTriple]
            let subject = sharedKnowledgeStore().entity(withIdentifier: "subject")
            let predicate = "predicate"
            let object = sharedKnowledgeStore().entity(withIdentifier: "object")

            try subject.link(to: object, withPredicate: predicate)
            try subject.link(to: object, withPredicate: predicate)
            try subject.link(to: object, withPredicate: predicate)
            try subject.link(to: object, withPredicate: predicate)

            let condition = KBTripleCondition(subject: subject.identifier,
                                              predicate: predicate,
                                              object: object.identifier)
            triples = try sharedKnowledgeStore().triples(matching: condition)

            var hexaCount = try sharedKnowledgeStore().keys().count
            XCTAssert(hexaCount == 6, "Insert first triple once results in 1 hexatuple. \(hexaCount)")
            XCTAssert(triples.count == 1, "one triple. \(triples.count)")
            XCTAssert(triples[0].weight == 4, "weight is 4. \(triples[0].weight)")

            print(triples[0].weight)

            try subject.unlink(to: object, withPredicate: predicate)
            triples = try sharedKnowledgeStore().triples(matching: condition)
            print(triples)

            hexaCount = try sharedKnowledgeStore().keys().count
            XCTAssert(hexaCount == 6, "still 1 hexatuple. \(hexaCount)")
            XCTAssert(triples.count == 1, "one triple. \(triples.count)")
            XCTAssert(triples[0].weight == 3, "weight is 3. \(triples[0].weight)")
            print(triples[0].weight)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testSingleLinking() {
        do {
            var sp_pairs: [(subject: KBEntity, predicate: Label)]
            var po_pairs: [(predicate: Label, object: KBEntity)]
            var links: [Label]

            let subject = sharedKnowledgeStore().entity(withIdentifier: "subject")
            let object = sharedKnowledgeStore().entity(withIdentifier: "object")
            let predicate = "predicate"

            try subject.link(to: object, withPredicate: predicate)

            let entities = try sharedKnowledgeStore().entities()
            XCTAssert(entities.count == 2, "All entities are 2 (subject and object). \(entities.count)")
            XCTAssert(entities.contains(subject), "Retrieved subject")
            XCTAssert(entities.contains(object), "Retrieved object")

            let triples = try sharedKnowledgeStore().triples(matching: nil)
            XCTAssert(triples.count == 1, "Insert first triple once results in 1 triple. \(triples.count)")
            XCTAssert(triples[0].subject == subject.identifier, "Insert first triple once results in 1 triple: subject")
            XCTAssert(triples[0].predicate == predicate, "Insert first triple once results in 1 triple: predicate")
            XCTAssert(triples[0].object == object.identifier, "Insert first triple once results in 1 triple: object")
            XCTAssert(triples[0].weight == 1, "weight is 1. \(triples[0].weight)")

            let tripleCondition = KBTripleCondition(subject: subject.identifier,
                                                    predicate: predicate,
                                                    object: object.identifier)
            let strictTriples = try sharedKnowledgeStore().triples(matching: tripleCondition)
            XCTAssert(triples.count == strictTriples.count, "String or nil condition return same result with one triple. \(triples.count), \(strictTriples.count)")
            XCTAssert(triples[0] == strictTriples[0], "String or nil condition return same result with one triple")
            XCTAssert(triples[0].weight == strictTriples[0].weight, "weight is 1. \(triples[0].weight)")

            try links = subject.links(to: object)
            XCTAssert(links.count == 1, "predicateLabelsTo: created link")
            XCTAssert(links[0] == predicate, "predicateLabelsTo: created link name")

            po_pairs = try subject.linkedEntities()
            XCTAssert(po_pairs.count == 1, "linkedEntities: created link")
            XCTAssert(po_pairs[0].0 == predicate, "linkedEntities: created link name")
            XCTAssert(po_pairs[0].1 == object, "linkedEntities: linked entity")

            po_pairs = try subject.linkedEntities(withPredicate: predicate)
            XCTAssert(po_pairs.count == 1, "linkedEntities (with label): 1 found")
            XCTAssert(po_pairs[0].1 == object, "linkedEntities: retrieve linked entity")

            po_pairs = try subject.linkedEntities(withPredicate: predicate, complement: true)
            XCTAssert(po_pairs.count == 0, "linkedEntities (with negated label): 0 found")

            po_pairs = try subject.linkedEntities(withPredicate: "NONMATCHING-\(predicate)")
            XCTAssert(po_pairs.count == 0, "linkedEntities (with other label): 0 found")

            po_pairs = try subject.linkedEntities(withPredicate: "NONMATCHING-\(predicate)", complement: true)
            XCTAssert(po_pairs.count == 1, "linkedEntities (with negated other label): some found")
            XCTAssert(po_pairs[0].1 == object, "linkedEntities: linked entity")

            sp_pairs = try subject.linkingEntities()
            XCTAssert(sp_pairs.count == 0, "linkingEntities to subject: 0 found")

            sp_pairs = try subject.linkingEntities(withPredicate: "ANYLABEL")
            XCTAssert(sp_pairs.count == 0, "linkingEntities to subject: 0 found")

            sp_pairs = try subject.linkingEntities(withPredicate: "ANYLABEL", complement: true)
            XCTAssert(sp_pairs.count == 0, "linkingEntities to subject (negated): 0 found")

            sp_pairs = try object.linkingEntities()
            XCTAssert(sp_pairs.count == 1, "linkingEntities to object: 1 found")
            XCTAssert(sp_pairs[0].0 == subject, "linkingEntities to object: linking entity")
            XCTAssert(sp_pairs[0].1 == predicate, "linkingEntities to object: created link name")

            sp_pairs = try object.linkingEntities(withPredicate: predicate)
            XCTAssert(sp_pairs.count == 1, "linkingEntities to object with predicate: 1 found")
            XCTAssert(sp_pairs[0].subject == subject, "linkingEntities to object with predicate: retrieved subject")

            sp_pairs = try object.linkingEntities(withPredicate: predicate, complement: true)
            XCTAssert(sp_pairs.count == 0, "linkingEntities to object with label (negated): 0 found")
            
            sp_pairs = try object.linkingEntities(withPredicate: "predicate", matchType: .beginsWith)
            XCTAssert(sp_pairs.count == 1, "linkingEntities to object with BEGINS label: 1 found")
            sp_pairs = try object.linkingEntities(withPredicate: "pred", matchType: .beginsWith)
            XCTAssert(sp_pairs.count == 1, "linkingEntities to object with BEGINS label: 1 found")
            sp_pairs = try object.linkingEntities(withPredicate: "invalidPred", matchType: .beginsWith)
            XCTAssert(sp_pairs.count == 0, "linkingEntities to object with BEGINS label: 0 found")
            sp_pairs = try object.linkingEntities(withPredicate: "predicate", matchType: .equal)
            XCTAssert(sp_pairs.count == 1, "linkingEntities to object with EQUAL label: 1 found")
            
            do {
                sp_pairs = try object.linkingEntities(withPredicate: "predicate", matchType: .contains)
                XCTFail("contains is not currently supported")
            }
            catch {
            }
            
            do {
                sp_pairs = try object.linkingEntities(withPredicate: "predicate", matchType: .endsWith)
                XCTFail("ends with is not currently supported")
            }
            catch {
            }

            sp_pairs = try object.linkingEntities(withPredicate: "ANYLABEL")
            XCTAssert(sp_pairs.count == 0, "linkingEntities to object: 0 found")

            links = try subject.links(to: object)
            XCTAssert(links.count == 1, "links subject-object: 1 found")
            XCTAssert(links[0] == predicate, "links: predicate label matches")

            links = try subject.links(to: subject)
            XCTAssert(links.count == 0, "selflinks to subject: 0 found")

            links = try object.links(to: object)
            XCTAssert(links.count == 0, "selflinks to object: 0 found")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testMultipleLinking() {
        do {
            var sp_pairs: [(subject: KBEntity, predicate: Label)]
            var po_pairs: [(predicate: Label, object: KBEntity)]
            var links: [Label]

            let subject = sharedKnowledgeStore().entity(withIdentifier: "subject")
            let predicate = "predicate"
            let secondPredicate = "newPredicate"
            let object = sharedKnowledgeStore().entity(withIdentifier: "object")
            let secondObject = sharedKnowledgeStore().entity(withIdentifier: "secondObject")

            try subject.link(to: object, withPredicate: predicate)
            try subject.link(to: object, withPredicate: secondPredicate)
            try subject.link(to: secondObject, withPredicate: predicate)

            links = try subject.links(to: object)
            XCTAssert(links.count == 2, "\(links.count)")
            XCTAssert(links.contains(predicate), "created second link name")
            XCTAssert(links.contains(secondPredicate), "created link name")

            links = try subject.links(to: secondObject)
            XCTAssert(links.count == 1, "predicateLabelsTo: created second link")
            XCTAssert(links[0] == predicate, "predicateLabelsTo: created link name to second entity")

            po_pairs = try subject.linkedEntities()
            XCTAssert(po_pairs.count == 3, "linkedEntities: created link")
            XCTAssert(po_pairs.map({ $0.predicate }).contains(predicate), "linkedEntities: created link name")
            XCTAssert(po_pairs.map({ $0.object }).contains(object), "linkedEntities: linked entity")
            XCTAssert(po_pairs.map({ $0.predicate }).contains(secondPredicate), "linkedEntities: created second link name")
            XCTAssert(po_pairs.map({ $0.object }).contains(object), "linkedEntities: linked entity")
            XCTAssert(po_pairs.map({ $0.predicate }).contains(predicate), "linkedEntities: created link name to second entity")
            XCTAssert(po_pairs.map({ $0.object }).contains(secondObject), "linkedEntities: linked second entity")

            po_pairs = try subject.linkedEntities(withPredicate: predicate)
            XCTAssert(po_pairs.count == 2, "linkedEntities (with label): 1 found")
            XCTAssert(po_pairs.map({ $0.object }).contains(object), "linkedEntities: retrieve linked entity")
            XCTAssert(po_pairs.map({ $0.object }).contains(secondObject), "linkedEntities: retrieve second linked entity")

            po_pairs = try subject.linkedEntities(withPredicate: secondPredicate)
            XCTAssert(po_pairs.count == 1, "linkedEntities (with label): 1 found")
            XCTAssert(po_pairs[0].object == object, "linkedEntities: retrieve linked entity")

            po_pairs = try subject.linkedEntities(withPredicate: predicate, complement: true)
            XCTAssert(po_pairs.count == 1, "linkedEntities (with negated label): 1 expected \(po_pairs.count) found")
            XCTAssert(po_pairs[0].object == object, "linkedEntities (with negated label): second entity")

            po_pairs = try subject.linkedEntities(withPredicate: secondPredicate, complement: true)
            XCTAssert(po_pairs.count == 2, "linkedEntities (with negated label): 2 expected \(po_pairs.count) found")
            XCTAssert(po_pairs.map({ $0.object }).contains(object), "linkedEntities (with negated label): first entity")
            XCTAssert(po_pairs.map({ $0.object }).contains(secondObject), "linkedEntities (with negated label): second entity")

            links = try subject.links(to: object)
            XCTAssert(links.count == 2, "predicateLabelsTo: created link")
            XCTAssert(links.contains(predicate), "predicateLabelsTo: created link name")
            XCTAssert(links.contains(secondPredicate), "predicateLabelsTo: created second link name")

            links = try subject.links(to: secondObject)
            XCTAssert(links.count == 1, "predicateLabelsTo: created second link")
            XCTAssert(links[0] == predicate, "predicateLabelsTo: created link name to second entity")

            sp_pairs = try object.linkingEntities()
            XCTAssert(sp_pairs.count == 2, "linkingEntities from object: 2 found")
            XCTAssert(sp_pairs.map({ $0.subject }).contains(subject), "linkingEntities from object: subject-predicate")
            XCTAssert(sp_pairs.map({ $0.predicate }).contains(predicate), "linkingEntities from object: predicate")
            XCTAssert(sp_pairs.map({ $0.subject }).contains(subject), "linkingEntities from object: subject-secondPredicate")
            XCTAssert(sp_pairs.map({ $0.predicate }).contains(secondPredicate), "linkingEntities from object: secondPredicate")

            sp_pairs = try secondObject.linkingEntities()
            XCTAssert(sp_pairs.count == 1, "linkingEntities from secondObject: 1 found")
            XCTAssert(sp_pairs[0].0 == subject, "linkingEntities from secondObject: subject-predicate")
            XCTAssert(sp_pairs[0].1 == predicate, "linkingEntities from secondObject: predicate")

            sp_pairs = try object.linkingEntities(withPredicate: predicate)
            XCTAssert(sp_pairs.count == 1, "linkingEntities (with label): 1 found")
            XCTAssert(sp_pairs[0].subject == subject, "linkingEntities: retrieve linked entity")

            sp_pairs = try object.linkingEntities(withPredicate: secondPredicate)
            XCTAssert(sp_pairs.count == 1, "linkingEntities (with label): 1 found")
            XCTAssert(sp_pairs[0].subject == subject, "linkingEntities: retrieve linked entity")

            sp_pairs = try secondObject.linkingEntities(withPredicate: predicate)
            XCTAssert(sp_pairs.count == 1, "linkingEntities (with label): 1 found")
            XCTAssert(sp_pairs[0].subject == subject, "linkingEntities: retrieve linked entity")

            po_pairs = try subject.linkedEntities(withPredicate: secondPredicate)
            XCTAssert(po_pairs.count == 1, "linkedEntities (with label): 1 found")
            XCTAssert(po_pairs[0].object == object, "linkedEntities: retrieve linked entity")

            po_pairs = try subject.linkedEntities(withPredicate: predicate, complement: true)
            XCTAssert(po_pairs.count == 1, "linkedEntities (with negated label): 1 expected \(po_pairs.count) found")
            XCTAssert(po_pairs[0].object == object, "linkedEntities (with negated label): second entity")

            po_pairs = try subject.linkedEntities(withPredicate: secondPredicate, complement: true)
            XCTAssert(po_pairs.count == 2, "linkedEntities (with negated label): 2 expected \(po_pairs.count) found")
            XCTAssert(po_pairs.map({ $0.object }).contains(object), "linkedEntities (with negated label): first entity")
            XCTAssert(po_pairs.map({ $0.object }).contains(secondObject), "linkedEntities (with negated label): second entity")

            po_pairs = try subject.linkedEntities(withPredicate: "NONMATCHING-\(predicate)")
            XCTAssert(po_pairs.count == 0, "linkedEntities (with other label): 0 found")

            po_pairs = try subject.linkedEntities(withPredicate: "NONMATCHING-\(predicate)", complement: true)
            XCTAssert(po_pairs.count == 3, "linkedEntities (with negated other label): some found")

            links = try subject.links(to: object)
            XCTAssert(links.count == 2, "links: 2 found")
            XCTAssert(links.contains(predicate), "links: predicate label matches")
            XCTAssert(links.contains(secondPredicate), "links: second predicate label matches")

            links = try subject.links(to: secondObject)
            XCTAssert(links.count == 1, "secondObjectlinks: 1 found")
            XCTAssert(links[0] == predicate, "secondObjectlinks: predicate label matches")

            links = try subject.links(to: subject)
            XCTAssert(links.count == 0, "selflinks to subject: 0 found")

            links = try object.links(to: secondObject)
            XCTAssert(links.count == 0, "selflinks to object: 0 found")

            links = try object.links(to: object)
            XCTAssert(links.count == 0, "selflinks to object: 0 found")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testJSONLDSerialization() {
        let expectation = XCTestExpectation(description: #function)

        do {
            let subject = sharedKnowledgeStore().entity(withIdentifier: "subject")
            let predicate = "predicate"
            let secondPredicate = "newPredicate"
            let object = sharedKnowledgeStore().entity(withIdentifier: "object")
            let secondObject = sharedKnowledgeStore().entity(withIdentifier: "secondObject")

            let graph = KBJSONLDGraph(withEntities: [subject, object, secondObject])

            try subject.link(to: object, withPredicate: predicate)
            try subject.link(to: object, withPredicate: secondPredicate)
            try subject.link(to: secondObject, withPredicate: predicate)

            graph.linkedData() { result in
                switch result {
                case .failure(let err):
                    XCTFail("\(err)")
                case .success(let entities):
                    let expectedEntities: [KBKVPairs] = [["@id": "subject",
                                                             "predicate": ["object",
                                                                           "secondObject"],
                                                             "newPredicate": "object"],
                                                            ["@id": "object"],
                                                            ["@id": "secondObject"]]
                    XCTAssert(self.isEqual(entities, expectedEntities))

                    expectation.fulfill()
                }
            }
        } catch {
            XCTFail("Linking failed: \(error)")
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func _testJSONLDDeserialization() {
        let expectation = XCTestExpectation(description: #function)

        let bundle = Bundle(for: type(of: self).self)
        guard let path = bundle.path(forResource: "testJSONLDDeserialization", ofType: "json") else {
            XCTFail("Missing JSON file")
            expectation.fulfill()
            return
        }

        sharedKnowledgeStore().importContentsOf(JSONLDFileAt: path) { result in
            switch result {
            case .failure(let err):
                XCTFail("\(String(describing: err))")
                expectation.fulfill()
            case .success():
                do {
                    let entities = try sharedKnowledgeStore().entities()
                    let expectedCount: Int = 14
                    XCTAssert(entities.count == expectedCount, "There are \(expectedCount) entities in the store")

                    let timCook = sharedKnowledgeStore().entity(withIdentifier: "http://www.timcook.com")
                    let jp = sharedKnowledgeStore().entity(withIdentifier: "_:jp")
                    let gennaro = sharedKnowledgeStore().entity(withIdentifier: "_:gennaro")

                    XCTAssert(entities.contains(timCook), "One of the entities is Tim Cook")
                    XCTAssert(entities.contains(jp), "One of the entities is Joao Pedro")
                    XCTAssert(entities.contains(gennaro), "One of the entities is Gennaro")

                    let tc_knows = try timCook.linkedEntities(withPredicate: "knows")
                    XCTAssert(tc_knows.count == 3, "Tim Cook knows 3 people")
                    XCTAssert(tc_knows.map({ $0.object }).contains(gennaro), "Tim Cook knows Gennaro")
                    XCTAssert(tc_knows.map({ $0.object }).contains(jp), "Tim Cook knows Joao Pedro")

                    let gennaro_knows = try gennaro.linkedEntities(withPredicate: "knows")
                    XCTAssert(gennaro_knows.count == 1, "Gennaro knows 1 person")
                    XCTAssert(gennaro_knows.map({ $0.object }).contains(jp), "Gennaro knows Joao Pedro")
                }  catch {
                    XCTFail("\(error)")
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testSimpleTripleQuery() {
        do {
            var triples: [KBTriple], condition: KBTripleCondition

            let first = sharedKnowledgeStore().entity(withIdentifier: "first")
            let second = sharedKnowledgeStore().entity(withIdentifier: "second")
            let third = sharedKnowledgeStore().entity(withIdentifier: "third")
            try first.link(to: second, withPredicate: "one")
            try second.link(to: third, withPredicate: "two")

            condition = KBTripleCondition(subject: nil, predicate: nil, object: second.identifier)
            triples = try sharedKnowledgeStore().triples(matching: condition)

            XCTAssert(triples.count == 1, "One triple matching (?,?,\(second)). \(triples.count)")
            XCTAssert(triples[0].subject == first.identifier, "Subject of triple matching (?,?,\(second))")
            XCTAssert(triples[0].object == second.identifier, "Object of triple matching (?,?,\(second))")
            XCTAssert(triples[0].predicate == "one", "Predicate of triple matching (?,?,\(second))")
            XCTAssert(triples[0].weight == 1, "weight of triple matching (?,?,\(second))")

            let firstPrime = sharedKnowledgeStore().entity(withIdentifier: "first-prime")
            try firstPrime.link(to: second, withPredicate: "one-prime")

            condition = KBTripleCondition(subject: nil, predicate: nil, object: second.identifier)
            triples = try sharedKnowledgeStore().triples(matching: condition)

            XCTAssert(triples.count == 2, "Two triples matching (?,?,\(second))")
            XCTAssert(triples[0].subject == firstPrime.identifier || triples[1].subject == firstPrime.identifier, "Subject of triple matching (?,?,\(second))")
            XCTAssert(triples[0].weight == 1, "weight of triple matching (?,?,\(second)). \(triples[0].weight)")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testComplexTripleQuery() {
        do {
            var triples = [KBTriple]()

            let first = sharedKnowledgeStore().entity(withIdentifier: "first")
            let second = sharedKnowledgeStore().entity(withIdentifier: "second")
            let third = sharedKnowledgeStore().entity(withIdentifier: "third")
            let fourth = sharedKnowledgeStore().entity(withIdentifier: "fourth")
            let fifth = sharedKnowledgeStore().entity(withIdentifier: "fifth")
            try first.link(to: second, withPredicate: "positive")
            try first.link(to: second, withPredicate: "negative")
            try second.link(to: third, withPredicate: "_OTHER_")
            try second.link(to: third, withPredicate: "positive")
            try third.link(to: fourth, withPredicate: "negative")
            try fourth.link(to: fifth, withPredicate: "_OTHER_")

            let positiveCondition = KBTripleCondition(subject: nil, predicate: "positive", object: nil)
            let negativeCondition = KBTripleCondition(subject: nil, predicate: "negative", object: nil)

            // DISJUNCTION (or)

            triples = try sharedKnowledgeStore().triples(matching: positiveCondition.or(negativeCondition))

            XCTAssert(triples.count == 4, "4 triples matching the condition. Found \(triples.count)")
            XCTAssert(triples.filter({ $0.predicate == "positive" || $0.predicate == "negative" }).count == 4, "All triples have the constrained predicate")

            let firstLinkedTo = triples.filter({ $0.subject == "first" }).map({ $0.object })
            XCTAssert(firstLinkedTo.count == 2, "First is linked twice to second (positive and negative)")
            XCTAssert(firstLinkedTo.contains(second.identifier), "First is linked to second")

            let secondLinkedTo = triples.filter({ $0.subject == "second" })
            XCTAssert(secondLinkedTo.count == 1, "Second is linked once to third")
            XCTAssert(secondLinkedTo[0] == KBTriple(subject: "second",
                                                    predicate: "positive",
                                                    object: "third",
                                                    weight: 0),
                      "Second is linked to third")

            let thirdLinkedTo = triples.filter({ $0.subject == "third" })
            XCTAssert(thirdLinkedTo.count == 1, "Third is linked once to fourth")
            XCTAssert(thirdLinkedTo[0] == KBTriple(subject: "third",
                                                   predicate: "negative",
                                                   object: "fourth",
                                                   weight: 0),
                      "Third is linked to fourth")

            // CONJUNCTION (and)

            /* TODO(gennaro)
             * Replace current "and" semantics with join-like semantics
             */

            print("No triples with condition \(positiveCondition.and(negativeCondition))")

            triples = try sharedKnowledgeStore().triples(matching: positiveCondition.and(negativeCondition))

            XCTAssert(triples.count == 0, "No triples with condition \(positiveCondition.and(negativeCondition))")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testSimplePerformanceExample() {
        // This is an example of a performance test case.
        measure {
            do {
                let subject = sharedKnowledgeStore().entity(withIdentifier: "subject")
                let object = sharedKnowledgeStore().entity(withIdentifier: "object")
                let predicate = "predicate"

                try subject.link(to: object, withPredicate: predicate)

                let linked = try subject.linkedEntities()
                XCTAssert(linked.count == 1, "[sync perfs] linking was successful")

                let linkedCouplesCondition = try KBTripleCondition.havingPredicate(predicate)
                let so_couples = try sharedKnowledgeStore().triples(matching: linkedCouplesCondition)
                XCTAssert(so_couples.count == 1, "[sync perfs] couples retrieved")
                XCTAssert(so_couples[0].subject == subject.identifier, "[sync perfs] subject matches")
                XCTAssert(so_couples[0].object == object.identifier, "[sync perfs] object matches")
            } catch {
                XCTFail("\(error)")
            }
        }
    }

     func testSimpleLinkingPerformances() {
         measure {
             do {
                 // Simple Graph
                 let yummlyApp = sharedKnowledgeStore().entity(withIdentifier: "_:com.yummly")
                 let yummlyActivity = sharedKnowledgeStore().entity(withIdentifier: "_:com.yummly.activity.recipe.92205")
                 try yummlyActivity.link(to: yummlyApp, withPredicate: "application")
             } catch {
                 XCTFail("\(error)")
             }
         }
     }

    func testSimpleLinking() {
        let yummlyApp = sharedKnowledgeStore().entity(withIdentifier: "_:com.yummly")
        let yummlyActivity = sharedKnowledgeStore().entity(withIdentifier: "_:com.yummly.activity.recipe.92205")

        do {
            try yummlyActivity.link(to: yummlyApp, withPredicate: "application")

            let entities = try sharedKnowledgeStore().entities()
            let expectedCount: Int = 2
            XCTAssert(entities.count == expectedCount, "There are \(expectedCount) entities in the store, found \(entities.count)")

            let links = try yummlyActivity.links(to: yummlyApp)
            XCTAssert(links.count == 1, "The activity is linked to the app: count. Found \(links.count) links")
            XCTAssert(links.first == "application", "The activity is linked to the app")
        } catch {
            XCTFail("\(error)")
        }
    }

     func _testJSONLDImportPerformances() {
         measure {
             self.importJSONLD(named: "bigGraph")
         }
     }

    func _testJSONLDImport() {
        self.importJSONLD(named: "bigGraph")
        let yummlyApp = sharedKnowledgeStore().entity(withIdentifier: "_:com.yummly")
        let yummlyActivity = sharedKnowledgeStore().entity(withIdentifier: "_:com.yummly.activity.recipe.92205")
        do {
            let entities = try sharedKnowledgeStore().entities()
            let expectedCount: Int = 84
            XCTAssert(entities.count == expectedCount, "There should be \(expectedCount) entities in // the store. Found \(entities.count)")
            let links = try yummlyActivity.links(to: yummlyApp)
            XCTAssert(links.count == 1, "The activity is linked to the app: 1 link. Found // \(links.count)")
            XCTAssert(links.first == "application", "The activity is linked to the app")
        } catch {
            XCTFail("\(error)")
        }
    }

//     func testSimpleKBLogic() {
//         let expectation = XCTestExpectation(description: #function)
//
//         let cat = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "cat")
//         let mammal = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "mammal")
//         let predicate = "is"
//
//         let tiger = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "tiger")
//
//         do {
//             let logic = KBLogic.ifExistsLink(predicate, to: cat)
//             try KnowledgeStoreTestCase.sharedKnowledgeStore.inferLink(to: mammal, withPredicate: predicate, when: logic)
//         } catch {
//             print("Could not install inference link `if \(predicate) to \(mammal)`: \(error)")
//             XCTFail("\(error)")
//         }
//
//         do {
//             try cat.link(to: mammal, withPredicate: predicate)
//             try tiger.link(to: cat, withPredicate: predicate)
//
//             let tigerLinks = try tiger.linkedEntities()
//             XCTAssert(tigerLinks.count > 1, "2 links from \(tiger). Found \(tigerLinks.count)")
//             XCTAssert(tigerLinks.map({ $0.1 }).contains(cat), "Previous was kept \(cat)")
//             XCTAssert(tigerLinks.map({ $0.1 }).contains(mammal), "New one is inferred \(mammal)")
//         } catch {
//             XCTFail("\(error)")
//         }
//
//         expectation.fulfill()
//
//         wait(for: [expectation], timeout: 10.0)
//     }
//
//    func testDiscoverabilityKBLogic() {
//        let expectation = XCTestExpectation(description: #function)
//
//        do {
//            let intent = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "multiShotSmsIntent");
//            let verb = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "smsVerb")
//            let recipient = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "smsRecipient")
//            let body = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "smsBody")
//
//            let intentToDiscover = KnowledgeStoreTestCase.sharedKnowledgeStore.entity(withIdentifier: "oneShotSmsIntent")
//
//            let hasVerb = KBLogic.ifExistsLink("has", to: verb)
//            let noBody = KBLogic.ifNotExistsLink("has", to: body)
//            let noRecipient = KBLogic.ifNotExistsLink("has", to: recipient)
//
//            try KnowledgeStoreTestCase.sharedKnowledgeStore.inferLink(to: intentToDiscover, withPredicate: "discoverability", when: hasVerb.and(noBody))
//            try KnowledgeStoreTestCase.sharedKnowledgeStore.inferLink(to: intentToDiscover, withPredicate: "discoverability", when: hasVerb.and(noRecipient))
//
//            try intent.link(to: verb, withPredicate: "has")
//            try intent.link(to: recipient, withPredicate: "has")
//
//            let linked = KBTripleCondition(subject: nil, predicate: nil, object: intentToDiscover.identifier)
//            let linking = KBTripleCondition(subject: intentToDiscover.identifier, predicate: nil, object: nil)
//
//            let triples = try KnowledgeStoreTestCase.sharedKnowledgeStore.triples(matching: linked.or(linking))
//                .filter { $0.predicate == "discoverability" && !$0.subject.beginsWith(RULE_PREFIX) }
//            XCTAssert(triples.count == 1, "<oneShotSmsIntent> has been inferred. \(triples.count)")
//            if (triples.count > 0) {
//                XCTAssert(triples[0].subject == intent.identifier, "<oneShotSmsIntent> has been inferred (subject)")
//                XCTAssert(triples[0].object == intentToDiscover.identifier, "<oneShotSmsIntent> has been inferred (object)")
//            } else {
//                XCTFail()
//            }
//        } catch {
//            XCTFail("\(error)")
//        }
//
//        expectation.fulfill()
//
//        wait(for: [expectation], timeout: 10.0)
//    }

    private func importJSONLD(named name: String) {
        let bundle = Bundle(for: type(of: self).self)
        if let path = bundle.path(forResource: name, ofType: "json") {
            let dispatch = KBTimedDispatch(timeout: .distantFuture)

            sharedKnowledgeStore().importContentsOf(JSONLDFileAt: path) { result in
                switch result {
                case .failure(let err):
                    dispatch.interrupt(err)
                case .success():
                    dispatch.semaphore.signal()
                }
            }

            do {
                try dispatch.wait()
            } catch KnowledgeBase.KBError.timeout {
                XCTFail("Timeout importing JSON file")
            } catch {
                XCTFail("Failure importing JSON file: \(error)")
            }
        } else {
            XCTFail("Missing JSON file")
        }
    }
}
