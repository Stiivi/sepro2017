import XCTest
@testable import Sepro

class SelectorTests: XCTestCase {
    func testEmpty() {
        // Empty selector should match everything
        let selector = ContextSelector()
        var context = ObjectContext()

        XCTAssertTrue(selector.matches(context:context))

        context = ObjectContext(direct: ObjectState(tags:["test"]))
        XCTAssertTrue(selector.matches(context:context))

    }

    func testDirectPresent() {
        let context = ObjectContext(
            direct: ObjectState(
                tags:["test"]
            )
        )

        let badContext = ObjectContext(
            direct: ObjectState(
                tags:["bad"]
            )
        )

        let selector = ContextSelector(
            direct: ObjectSelector(present: ["test"])
        )

        XCTAssertTrue(selector.matches(context:context))
        XCTAssertFalse(selector.matches(context:badContext))

    }

    func testDirectAbsent() {
        let context = ObjectContext(direct: ObjectState(tags:["test"]))
        let badContext = ObjectContext(direct: ObjectState(tags:["bad"]))

        let selector = ContextSelector(
            direct: ObjectSelector(absent: ["bad"])
        )

        XCTAssertTrue(selector.matches(context:context))
        XCTAssertFalse(selector.matches(context:badContext))

    }
    func testDirectPresentAndAbsent() {
        let good = ObjectContext(
            direct: ObjectState(tags:["good", "node"])
        )

        let bad = ObjectContext(
            direct: ObjectState(tags:["bad", "node"])
        )

        let selector = ContextSelector(
            direct: ObjectSelector(
                present: ["node"],
                absent: ["bad"]
            )
        )

        XCTAssertTrue(selector.matches(context:good))
        XCTAssertFalse(selector.matches(context:bad))
    }
    func testIndirect() {
        let context = ObjectContext(
            direct: ObjectState(tags:["head"]),
            indirect: [
                "next": ObjectState(tags:["node"]),
                "other": ObjectState(tags:["bogus"])
            ]
            
        )

        var selector = ContextSelector(
            indirect: [
                "next": ObjectSelector(
                            present: ["node"]
                        )
                ]
        )

        XCTAssertTrue(selector.matches(context:context))

        selector = ContextSelector(
            indirect: [
                "next": ObjectSelector(
                            present: ["bogus"]
                        )
                ]
        )

        XCTAssertFalse(selector.matches(context:context))

        selector = ContextSelector(
            indirect: [
                "next": ObjectSelector(
                            present: ["node"],
                            absent: ["bogus"]
                        )
                ]
        )

        XCTAssertTrue(selector.matches(context:context))

        // present in non existing

        selector = ContextSelector(
            indirect: [
                "unknown": ObjectSelector(
                            present: ["node"]
                        )
                ]
        )

        XCTAssertFalse(selector.matches(context:context))
        
        // absent in non-existing

        selector = ContextSelector(
            indirect: [
                "unknown": ObjectSelector(
                            absent: ["node"]
                        )
                ]
        )

        XCTAssertFalse(selector.matches(context:context))
    }


}
