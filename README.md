# swift-iso-8825

Use this package when you need to read or write ASN.1 values as BER or DER bytes, for example to handle keys, certificates or CMS messages. Parse with `ISO_8825.DER.parse(_:)` or `ISO_8825.BER.parse(_:)` into an `ISO_8825.Node`, decode its parts with the `ISO_8825.DER` or `ISO_8825.BER` helpers, and write with `ISO_8825.DER.Serializer`. The values themselves, such as `ISO_8824.ObjectIdentifier` and the time and string types, come from swift-iso-8824.

## Laws

- Input must hold exactly one element. Trailing bytes are refused, and so is nesting deeper than 50 levels.
- DER parsing refuses indefinite lengths, a long-form length that would fit the short form, and a length written in more bytes than it needs. BER parsing accepts all three, and allows an indefinite length only on a constructed element.
- A tag number below 31 written in the long form is refused under both rules.
- Writing always produces DER. Lengths are definite and as short as possible, and a SET OF is written with its elements sorted by their encoded bytes.
- An `ISO_8825.Any` holds DER bytes. Wrapping a BER node in one re-encodes it with definite lengths.
- A sequence decoded with `ISO_8825.DER.sequence(_:identifier:_:)` must consume every element, or decoding fails.
- Reading a SET OF checks that its elements are sorted under DER and does not under BER.
- An optional tagged field counts as absent when the next element has a different tag. An explicit tag must wrap exactly one element.
- Under DER, a DEFAULT field that is present and equal to its default is refused. Under BER it is accepted.
- A DER boolean must be the byte 0x00 or 0xFF. Under BER any non-zero byte is true. Writing always uses 0xFF.
- A DER integer must use the fewest bytes. Under BER extra leading bytes are accepted. Under both, empty content is refused, and a value that doesn't fit the Swift integer type is refused. An unsigned type refuses a negative encoding and gains a leading zero byte when written if its top bit is set.
- Under BER, an octet string or a string type may be constructed from pieces, which are joined. DER accepts only the primitive form. A constructed bit string is refused under both.
- `ISO_8824.PrintableString`, `ISO_8824.VisibleString` and `ISO_8824.IA5String` check their characters when decoded. The other string types take the bytes as they are.
- A GeneralizedTime must be written as year, month, day, hour, minute and second, an optional fraction, and Z. Offsets, missing seconds, an empty fraction and trailing zeros in the fraction are refused, under BER as well as DER.
- A UTCTime must be written with seconds and Z. Its two-digit year 50 to 99 means 1950 to 1999, and 00 to 49 means 2000 to 2049.
- A NULL must have empty content.
