enum Target: Hashable {
    case direct
    case indirect(Slot)

    var hashValue: Int {
        switch self {
        case .direct: return 0
        case .indirect(let slot): return slot.hashValue
        }
    }
}

func ==(lhs: Target, rhs: Target) -> Bool {
    switch (lhs, rhs) {
    case (.direct, .direct): return true
    case (.indirect, .direct): return false
    case (.direct, .indirect): return false
    case (.indirect(let lval), .indirect(let rval)): return lval == rval
    }
}

typealias TargetTagMap = [Target:Set<Tag>]
typealias TargetSlotMap = [Target:Set<Slot>]

struct ObjectSelector {
    let present: Set<Tag>?
    let absent: Set<Tag>?
    let bound: Set<Slot>?
    let unbound: Set<Slot>?

    init(present: Set<Tag>?=nil, absent: Set<Tag>?=nil, bound:
        Set<Slot>?=nil, unbound:Set<Slot>?=nil) {

        // TODO: present and absend must be disjoint
        // TODO: bound and unbound must be disjoint
        self.present = present
        self.absent = absent
        self.bound = bound
        self.unbound = unbound 
    }

    func matches(state: ObjectState) -> Bool {
        if let tags = present {
            if !tags.isSubset(of: state.tags) {
                return false
            }
        }
        if let tags = absent {
            if !tags.isDisjoint(with: state.tags) {
                return false
            }
        }
        if let slots = bound {
            if !slots.isSubset(of: state.slots) {
                return false
            }
        }
        if let slots = unbound {
            if !slots.isDisjoint(with: state.slots) {
                return false
            }
        }
        return true
    }
}

struct ContextSelector {
    let direct: ObjectSelector?
    let indirect: [Slot:ObjectSelector]

    init(direct: ObjectSelector?=nil, indirect: [Slot:ObjectSelector]?=nil) {
        self.direct = direct
        self.indirect = indirect ?? [:]
    }

    func matches(context: ObjectContext) -> Bool {
        if let selector = direct {
            if !selector.matches(state: context.direct) {
                return false
            }
        } 

        let miss = indirect.contains {
            if let state = context.indirect[$0.key] {
                return !$0.value.matches(state: state) 
            }
            else {
                return true
            }
        }
        
        // If we didn't miss anything, return true.
        return !miss
    }
}

struct BinarySelector {
    let left: ContextSelector
    let right: ContextSelector
}

