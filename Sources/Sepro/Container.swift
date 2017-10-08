typealias OID = Int

protocol Container {
    func create() -> OID
    func remove(_ oid: OID)
    
    func state(_ oid: OID) -> Set<Tag>
    func update(_ oid: OID, state: Set<Tag>) -> Set<Tag>
    
    func bind(source: OID, target: OID, slot: Slot)
    func unbind(object: OID, slot: Slot)
}

class Object {
    var tags: Set<Tag>
    var slots: [Slot:OID]
    
    init(tags: Set<Tag>? = nil) {
        self.tags = tags ?? Set<Tag>()
        self.slots = [Slot:OID]()
    }
}

struct ObjectState {
    let tags: Set<Tag>
    let slots: Set<Slot>

    init(tags: Set<Tag>?=nil, slots: Set<Slot>?=nil) {
        self.tags = tags ?? Set()
        self.slots = slots ?? Set()
    }
}

struct ObjectContext {
    let direct: ObjectState
    let indirect: [Slot: ObjectState]

    init(direct: ObjectState?=nil, indirect: [Slot: ObjectState]?=nil) {
        self.direct = direct ?? ObjectState()
        self.indirect = indirect ?? [:]
    }
}

/// Simple implementation of object container.
/// 
/// Object container is guaranteed to maintain internal consistency – there
/// should be no invalid references.
///
class SimpleContainer {
    var objects: [OID:Object]
    var sequence: Int = 1
    
    init() {
        objects = [OID:Object]()
    }
    
    @discardableResult
    func create() -> OID {
        let oid = sequence
        sequence += 1
        
        objects[oid] = Object()
        
        return oid
    }

    /// Returns: `true` if `oid` is valid object reference.
    // Note: We are not calling it "contain", since object references are
    // private
    func isValid(_ oid: OID) -> Bool {
        return objects[oid] != nil
    }

    /// Returns: count of objects in the container.
    var count: Int {
        return objects.count
    }
    
    /// Removes object `oid` from the container. 
    ///
    /// Complexity: O(n+m) where `n` is number of objects and `m` is number of
    /// slots in the container.
    // Todo: this can be done better.
    func remove(_ oid: OID) {
        // TODO: This is quite expensive [debt]
        let toRemove: [(OID, Slot)] = objects.flatMap {
            // objItem key: OID, value: Object
            // We need to filter Objects and slots to be removed
            objItem in
            objItem.value.slots.filter {
                $0.value == oid
            }.map {
                slotItem in
                (objItem.key, slotItem.key) 
            }
        }

        toRemove.forEach {
            (oid, slot) in
            unbind(oid, slot: slot)
        }

        objects.removeValue(forKey: oid)
    }

    /// Returns: state of object `oid`.
    ///
    /// Prerequisite: Object reference must be valid OID.
    ///
    func state(_ oid: OID) -> ObjectState {
        guard let object = objects[oid] else {
            preconditionFailure("Invalid object reference \(oid)")
        }
        return ObjectState(tags: object.tags,
                           slots: Set(object.slots.keys))
    }

    func update(_ oid: OID, tags: Set<Tag>) {
        guard let object = objects[oid] else {
            preconditionFailure("Invalid object reference \(oid)")
        }

        object.tags = tags
    }
    
    /// Create binding between `source` object at `slot` to `target`.
    /// Precondition: Target object and source must be valid OIDs.
    ///
    func bind(_ source: OID, to target: OID, slot: Slot) {
        guard let object = objects[source] else {
            preconditionFailure("Invalid source object reference \(source)")
        }
        guard objects[target] != nil else {
            preconditionFailure("Invalid target object reference \(target)")
        }
        
        object.slots[slot] = target
    }
    
    /// Remove binding from `source` object at `slot`.
    /// Precondition: Source must be a valid OID.
    ///
    func unbind(_ source: OID, slot: Slot) {
        guard let object = objects[source] else {
            preconditionFailure("Invalid source object reference \(source)")
        }
        
        object.slots.removeValue(forKey: slot)
    }

    /// Returns: A dictionary of bindings for object `oid` where keys are slots
    /// and values are OIDs of referenced objects.
    ///
    func bindings(_ oid: OID) -> [Slot:OID] {
        guard let object = objects[oid] else {
            preconditionFailure("Invalid source object reference \(oid)")
        }
        return object.slots 
    }
    
    // # Selectors
    //

    /// Returns: Object context for object `oid`.
    ///
    func context(_ oid: OID) -> ObjectContext {
        guard let object = objects[oid] else {
            preconditionFailure("Invalid object reference \(oid)")
        }

        var indirect: [Slot: ObjectState] = [:]

        object.slots.forEach {
            item in
            
            indirect[item.key] = state(item.value)
        }
        
        return ObjectContext(direct: state(oid), indirect: indirect)
    }

    func select(unary selector: ContextSelector) -> Array<OID>{
        let result = objects.keys.filter {
            obj in
            let context = self.context(obj)

            return selector.matches(context: context)
        }

        return result
    }

    /// Returns: OID of effective subject based on `candidate`.
    /// Precondition: Valid candidate OID
    //
    // TODO: We need to validate the subject
    func getSubject(_ oid: OID, effective: EffectiveSubject) -> OID? {
        guard let candidate = objects[oid] else {
            preconditionFailure("Invalid source object reference \(oid)")
        }

        switch effective {
        case .direct: return oid
        case .indirect(let slot): return candidate.slots[slot]
        }
    }

    func getTarget(_ subject: OID, effectiveTarget: EffectiveTarget) -> OID? {
        let target: OID?

        switch effectiveTarget {
        case .subject:
            target = subject
        case .direct(let slot):
            if let obj = objects[subject] {
                target = obj.slots[slot]
            }
            else {
                target = nil
            }
        case .indirect(let indirectSlot, let slot):
            // Try to get direct object
            if let direct = objects[subject],
               let indirectOid = direct.slots[indirectSlot],
               let indirect = objects[indirectOid] {
                target = indirect.slots[slot]       
            }
            else {
                target = nil
            }
        } 

        return target
    }

    /// Modify a binding in effective slot of context of object `oid`
    ///
    /// Precondition: Effective subject must exist
    ///
    func modifyBinding(_ oid: OID,
                       effectiveSubject: EffectiveSubject,
                       slot: Slot,
                       modifier: BindingModifier) {
        guard let subject: OID = getSubject(oid, effective: effectiveSubject)  else {
            // TODO: Failure?
            preconditionFailure("Effective subject does not exist.")
        }

        switch modifier {
        case .unbind:
            unbind(subject, slot: slot)
        case .bind(let effectiveTarget):
            if let target = getTarget(subject, effectiveTarget: effectiveTarget) {
                bind(subject, to: target, slot: slot)
            }
            // TODO: This is an error
        }
    }

    func modify(_ oid: OID, modifier: ObjectModifier) {
        let object = objects[oid]!

        // Update tags
        object.tags = object.tags.union(modifier.addedTags)
                                 .subtracting(modifier.subtractedTags)


        // Unbind Slots
        modifier.bindingModifiers.forEach {
            modifyBinding(oid,
                          effectiveSubject: $0.key.subject,
                          slot: $0.key.slot,
                          modifier: $0.value)
        }
    }

}

