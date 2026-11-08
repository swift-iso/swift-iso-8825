public import ISO_8824


extension ISO_8825 {
    public struct LazySetOfSequence<T>: Swift.Sequence {
        public typealias Element = Result<T, ISO_8824.Error>

        @usableFromInline
        package typealias Wrapped = LazyMapSequence<
            LazySequence<(ISO_8825.Node.Collection)>.Elements, Result<T, ISO_8824.Error>
        >

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

        @usableFromInline
        var wrapped: Wrapped

        @inlinable
        package init(_ wrapped: Wrapped) {
            self.wrapped = wrapped
        }

        @inlinable
        public func makeIterator() -> Iterator {
            .init(wrapped.makeIterator())
        }
    }
}
