import XCTest
@testable import KnowledgeBase

final class KBSPARQLTests: XCTestCase {
    func testSPARQL() async throws {
        let insertExpectation = self.expectation(description: "insert")
        
        let knowledgeStore = KBKnowledgeStore.defaultStore() as! KBKnowledgeStore
        knowledgeStore.importContentsOf(turtleFileAt: "") { result in
            switch result {
            case .failure(let err):
                XCTFail("\(err)")
                fallthrough
            default:
                insertExpectation.fulfill()
            }
        }
        
        let selectExpectation = self.expectation(description: "select")
        
        knowledgeStore.execute(SPARQLQuery: "SELECT") { result in
            switch result {
            case .failure(let err):
                XCTFail("\(err)")
                selectExpectation.fulfill()
            case .success(let results):
                XCTAssert(results.isEmpty)
                selectExpectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10.0) { err in
            if let e = err {
                XCTFail("test timed out: \(e)")
            }
        }
    }
}
