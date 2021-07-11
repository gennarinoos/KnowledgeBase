import XCTest
@testable import KnowledgeBase

final class KnowledgeBaseTests: XCTestCase {
    func testSPARQL() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let knowledgeStore = KBKnowledgeStore.defaultKnowledgeStore()
        try await knowledgeStore.importContentsOfTurtle(fromFileAt: "")
        let results = try await knowledgeStore.execute(SPARQLQuery: "SELECT")
        assert(results.isEmpty)
    }
}
