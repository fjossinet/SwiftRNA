import XCTest
@testable import SwiftRNA

final class SwiftRNATests: XCTestCase {
    func testExample() {
        let ss = SecondaryStructure(name: "test", sequence: "GGGAAACCC", bracketNotation: "(((...)))")
        XCTAssertEqual(ss.helices.count, 1)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
