public import ISO_8824

extension ISO_8825 {
    public struct LazySetOfSequence<T>: Swift.Sequence {
            LazySequence<(ISO_8825.Node.Collection)>.Elements, Result<T, ISO_8824.Error>
        >

        @usableFromInline
        var wrapped: Wrapped

        @inlinable
        package init(_ wrapped: Wrapped) {
            self.wrapped = wrapped
        }
    }
}

extension ISO_8825.LazySetOfSequence {
    public typealias Element = Result<T, ISO_8824.Error>

    @usableFromInline
    package typealias Wrapped = LazyMapSequence<

    public struct Iterator: IteratorProtocol {
        @usableFromInline
        var wrapped: Wrapped.Iterator

        @inlinable
        public mutating func next() -> Element? {
            wrapped.next()
        }

        @inlinable
        package init(_ wrapped: Wrapped.Iterator) {
            self.wrapped = wrapped
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        .init(wrapped.makeIterator())
    }
}
