# Formality-EVM

EVM implementation of Formality

## Requirements

- go-ethereum v1.9.7 or newer ([2e6aa596] required for tests, not yet upstream).

## Interaction net representation

Formality-EVM currently uses a slightly different net representation to
simplify things and minimize gas used in rewrites:

| Bits    | Description                            |
|--------------------------------------------------|
| 0:63    | main port                              |
| 64:127  | aux0 port                              |
| 128:191 | aux1 port                              |
| 192:199 | main port type (`PTR`, `NUM`, `ERA`)   |
| 200:207 | aux0 port type (`PTR`, `NUM`, `ERA`)   |
| 208:215 | aux1 port type (`PTR`, `NUM`, `ERA`)   |
| 216:223 | node type (`CON`, `OP1`, `OP2`, `ITE`) |
| 224:255 | node label                             |

This has a couple advantages:

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

[2e6aa596]: https://github.com/ethereum/go-ethereum/commit/2e6aa5962e1b26ab6a0339551bff9713734c1706
