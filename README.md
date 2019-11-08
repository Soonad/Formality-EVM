# Formality-EVM

EVM implementation of Formality

## Requirements

- go-ethereum v1.9.7 or newer ([2e6aa596] required for tests, not yet upstream).

## Interaction net representation

Formality-EVM currently uses a slightly different net representation to
simplify things and minimize gas used in rewrites. Each node consists
of four 64-bit integers with big-endian byte-order. They are used to
store the main port, aux0 port, aux1 port, and node info.

The node info integer specifies the type of each of the ports, the node
kind, the node type, and the node label.

| Bits  | Size | Description                            |
|:-----:|-----:|----------------------------------------|
|  0:7  |    8 | main port type (`PTR`, `NUM`, `ERA`)   |
|  8:15 |    8 | aux0 port type (`PTR`, `NUM`, `ERA`)   |
| 16:23 |    8 | aux1 port type (`PTR`, `NUM`, `ERA`)   |
| 24:31 |    8 | node type (`CON`, `OP1`, `OP2`, `ITE`) |
| 32:63 |   32 | node label                             |

This encoding has a couple advantages:

- Nodes fill a single EVM register
- Port type of neighboring nodes can be changed in a single `MSTORE8`,
  without first loading the node clearing the original port type,
  setting the new one, and then storing.

## Current status

- `NUM` - `CON`: DONE
- `NUM` - `OP1`: DONE (mostly)
- `NUM` - `OP2`: DONE
- `NUM` - `ITE`: DONE
- `ERA` - ` * `: DONE

## Implementation notes

The source code is first processed with [m4(1)] to enable use of macros
for common code.

[2e6aa596]: https://github.com/ethereum/go-ethereum/commit/2e6aa5962e1b26ab6a0339551bff9713734c1706
[m4(1)]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/m4.html
