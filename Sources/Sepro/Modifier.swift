
// Change
//

enum RelativeSide {
    case this
    case other
}
enum EffectiveSubject: Equatable {
    case direct
    case indirect(Slot)

    var isIndirect: Bool {
        switch self {
        case .direct: return false
        case .indirect: return true
        }
    }
}

func ==(lhs: EffectiveSubject, rhs: EffectiveSubject) -> Bool {
    switch(lhs, rhs) {
    case (.direct, .direct): return true
    case (.indirect(let s), .indirect(let t)): return s == t
    default: return false
    }    
}

/// Tuple representing a slot in effective subject. Uniquely identifies a slot
/// within object context that is to be bound to another target object.
///
struct EffectiveSlot: Hashable {
    let subject: EffectiveSubject
    let slot: Slot

    var hashValue: Int {
        switch subject {
        case .direct: return slot.hashValue
        case .indirect(let other): return slot.hashValue ^ other.hashValue
        }
    }
}

func ==(lhs: EffectiveSlot, rhs: EffectiveSlot) -> Bool {
    return lhs.subject == rhs.subject && lhs.slot == rhs.slot
}


enum EffectiveTarget {
    case subject
    case direct(Slot)
    case indirect(Slot, Slot)

    var isIndirect: Bool {
        switch self {
        case .indirect: return true
        default: return false
        }
    }
}

enum BindingModifier {
    case unbind
    case bind(EffectiveTarget)

    var isIndirect: Bool {
        switch self {
        case .unbind: return false
        case .bind(let target): return target.isIndirect
        }
    }
}

struct ObjectModifier {
    let addedTags: Set<Tag>
    let subtractedTags: Set<Tag>
    let bindingModifiers: [EffectiveSlot:BindingModifier]

    init(addedTags: Set<Tag>, subtractedTags: Set<Tag>,
            bindingModifiers: [EffectiveSlot:BindingModifier]){

        precondition(!bindingModifiers.contains {
            $0.key.subject.isIndirect && $0.value.isIndirect
        }, "Owner and target should not be both indirect")
        
        self.addedTags = addedTags
        self.subtractedTags = subtractedTags
        self.bindingModifiers = bindingModifiers
    }
}
