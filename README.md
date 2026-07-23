# swift-iso-8825

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of ISO/IEC 8825 (ITU-T X.690) — the ASN.1 encoding rules: Basic Encoding Rules (BER) and Distinguished Encoding Rules (DER), with the shared TLV wire vocabulary.

---

## Overview

This package carries the transfer-syntax law of ASN.1: parsing and serializing the abstract value types defined by [swift-iso-8824](https://github.com/swift-iso/swift-iso-8824) (ITU-T X.680) under BER and DER. The split mirrors the specifications themselves — notation and value validity live in `ISO_8824`; this module supplies the wire conformances retroactively and adds the structural combinators (`sequence`, `set`, tagged optionals, defaults) that X.690 messages are built from.

Failures throw typed errors, so decoding a hostile input is exhaustive at the call site.

## Quick Start

```swift
import ISO_8825

// Parse a DER-encoded SEQUENCE.
let node = try ISO_8825.DER.parse(bytes)
let value = try ISO_8825.DER.sequence(node, identifier: .sequence) { iterator in
    let version = try ISO_8824.Integer(derEncoded: &iterator)
    let oid = try ISO_8824.ObjectIdentifier(derEncoded: &iterator)
    return (version, oid)
}

// Serialize back to DER.
var serializer = ISO_8825.DER.Serializer()
try serializer.serialize(oid)
let encoded = serializer.serializedBytes
```

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-iso/swift-iso-8825.git", branch: "main")
]
```

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "ISO 8825", package: "swift-iso-8825")
    ]
)
```

## Related Packages

- [swift-iso-8824](https://github.com/swift-iso/swift-iso-8824) — the ASN.1 abstract value types and tag vocabulary this package encodes.

## Acknowledgments

This package derives from Apple's [SwiftASN1](https://github.com/apple/swift-asn1); see NOTICE.txt and CONTRIBUTORS.txt for provenance.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE.txt](LICENSE.txt) for details.
