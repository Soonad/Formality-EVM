# Formality-EVM

EVM implementation of Formality

## Requirements

- go-ethereum containing [b0b27752] (2019-10-29)

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

[b0b27752]: https://github.com/ethereum/go-ethereum/commit/b0b277525cb4e476deb461de1b5827a33daa2086
