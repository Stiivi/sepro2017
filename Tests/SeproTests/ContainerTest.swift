import XCTest
@testable import Sepro

class SimpleContainerTests: XCTestCase {
    func testCreate() {
        let container = SimpleContainer()
        let oid: OID
        var obj: ObjectState

        oid = container.create()
        XCTAssertEqual(container.count, 1)

        obj = container.state(oid)
        XCTAssertEqual(obj.tags, Set())
        XCTAssertEqual(obj.slots, Set())

        container.create()
        container.create()
        XCTAssertEqual(container.count, 3)
    }
    func testUpdate() {
        let container = SimpleContainer()
        let oid: OID
        var obj: ObjectState

        oid = container.create()
        container.update(oid, tags: ["a"])

        obj = container.state(oid)
        XCTAssertEqual(obj.tags, Set(["a"]))
        XCTAssertEqual(obj.slots, Set())

        // Test that we are replacing, not unioning
        container.update(oid, tags: ["b"])

        obj = container.state(oid)
        XCTAssertEqual(obj.tags, Set(["b"]))
        XCTAssertEqual(obj.slots, Set())
    }

    func testRemove() {
        let container = SimpleContainer()
        let a = container.create()
        let b = container.create()

        XCTAssertTrue(container.isValid(a))
        XCTAssertTrue(container.isValid(b))

        container.remove(a)
        
        XCTAssertFalse(container.isValid(a))
        XCTAssertTrue(container.isValid(b))
        XCTAssertEqual(container.count, 1)
    }

    func testRemoveDependencies() {
        let container = SimpleContainer()
        let dead = container.create()
        let keep = container.create()
        let a = container.create()
        let b = container.create()
   
        container.bind(a, to: dead, slot: "next")
        container.bind(a, to: dead, slot: "other")
        container.bind(b, to: dead, slot: "next")
        container.bind(a, to: keep, slot: "keep")
        container.bind(b, to: keep, slot: "keep")

        XCTAssertTrue(container.bindings(a)["next"] == dead)
        XCTAssertTrue(container.bindings(a)["other"] == dead)
        XCTAssertTrue(container.bindings(b)["next"] == dead)
        XCTAssertTrue(container.bindings(a)["keep"] == keep)
        XCTAssertTrue(container.bindings(b)["keep"] == keep)
        container.remove(dead)

        XCTAssertTrue(container.bindings(a)["next"] == nil)
        XCTAssertTrue(container.bindings(a)["other"] == nil)
        XCTAssertTrue(container.bindings(b)["next"] == nil)
        XCTAssertTrue(container.bindings(a)["keep"] == keep)
        XCTAssertTrue(container.bindings(b)["keep"] == keep)
    }

    func testBind() {
        let container = SimpleContainer()
        let head, node: OID
        var obj: ObjectState

        head = container.create()
        node = container.create()

        container.update(head, tags: ["head"])
        container.bind(head, to: node, slot: "next")

        obj = container.state(head)
        XCTAssertEqual(obj.tags, Set(["head"]))
        XCTAssertEqual(obj.slots, Set(["next"]))
    }

    func testUnbind() {
        let container = SimpleContainer()
        let head, node: OID
        var obj: ObjectState

        head = container.create()
        node = container.create()

        container.update(head, tags: ["head"])
        container.bind(head, to: node, slot: "next")
        container.unbind(head, slot: "next")

        obj = container.state(head)
        XCTAssertEqual(obj.tags, Set(["head"]))
        XCTAssertEqual(obj.slots, Set())
    }

    func testContext() {
        let container = SimpleContainer()
        let head, left, right: OID
        var context: ObjectContext

        head = container.create()
        left = container.create()
        right = container.create()

        container.update(head, tags: ["head"])
        container.bind(head, to: left, slot: "left")
        container.bind(head, to: right, slot: "right")

        context = container.context(head)
        XCTAssertEqual(context.direct.tags, Set(["head"]))
        XCTAssertEqual(context.direct.slots, Set(["left", "right"]))

        XCTAssertEqual(Array(context.indirect.keys), ["left", "right"])
    }

    func testUnarySelect() {
        //
        //  A --> C --> D
        //        ^
        //        |
        //  B ----+
        //
        //

        let container = SimpleContainer()
        let a, b, c, d: OID
        var context: ObjectContext

        a = container.create()
        b = container.create()
        c = container.create()
        d = container.create()

        container.update(a, tags: ["a", "head"])
        container.update(b, tags: ["b", "head"])
        container.update(c, tags: ["c"])
        container.update(d, tags: ["d"])

        container.bind(a, to: c, slot: "next")
        container.bind(b, to: c, slot: "next")
        container.bind(c, to: d, slot: "next")

        // # Direct
        // 
    }
}
        

