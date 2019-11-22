# Formality-EVM

EVM implementation of Formality

`net.easm` implements the rewrite function of FM-Net.

It also performs the following operations before `rewrite`:

- Set up a jump table in memory (at address `0x0`) for `OP1` numeric
  operations. An OP1 node with label `N` will load the address stored at
  `N * 32`, then jump to it.
- Set up a jump table in memory (at address `0x200`) for main port type.
- Store the free list terminator (-1) at address `0x300`.
- Store the interaction net size (in bytes) at address `0x320`.
- Load the interaction net from call data (EVM input) at offset `0x20`
  into memory (at address `0x400`).
- Load the redex index from call data at offset `0x0` onto the stack.
- Store the current gas remaining on the stack.

These operations only need to be run once before a series of rewrites.

It also performs the following operations after `rewrite`:

- Calculate gas used in the rewrite operation.
- Return the gas used (at offset `0x0`) and the rewritten net to
  the caller (at offset `0x20`).

The `rewrite` function is intended be called multiple times by a `reduce`
function that is yet to be written.

## Requirements

- go-ethereum containing [0bf6382e] (not yet upstream).

## Debugging

The `runtests` script will generate test inputs, run them through `evm`,
and compare with the expected output. To debug an individual test, you can
run `evm` manually with this input with the `--debug --nomemory`
flags. One helpful technique is to add a `STOP` instruction at a certain
point, in order to inspect the stack and verify your assumptions.

```
evm --codefile net.evm --inputfile test/num-op1.test.input --debug --nomemory run
```

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
- `NUM` - `OP1`: DONE
- `NUM` - `OP2`: DONE
- `NUM` - `ITE`: DONE
- `ERA` - ` * `: DONE
- Annihilation: DONE (mostly, needs some tweaks to the `NET_SET` macro to store the right port type)
- Unary duplication: DONE (mostly, needs to set reverse edges from neighbors)
- Binary duplication: TODO

## Implementation notes

The source code is first processed with [m4(1)] to enable use of macros
for common code.

[0bf6382e]: https://github.com/ethereum/go-ethereum/pull/20362/commits/0bf6382e19d307ebcb0d24f25673174f200c98e2
[m4(1)]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/m4.html
