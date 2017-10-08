extension Sequence {
    func any(where predicate: (Self.Element) throws -> Bool) rethrows -> Bool
    {
        return (try self.first(where: predicate)) != nil
    }

    func all(where predicate: (Self.Element) throws -> Bool) rethrows -> Bool
    {
        return try self.first { try !predicate($0) } == nil
    }

}
