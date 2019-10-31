divert(-1)

;; offset of redex in input
define(INPUT_REDEX, 0x0)
;; offset of net in input
define(INPUT_NET, 0x20)

;; address of op jump table in memory
define(OP_TABLE, 0x0)
;; address of scratch memory
define(SCRATCH, 0x200)
;; address of net in memory
define(NET, 0x300)

define(PORT_PTR, 0)
define(PORT_NUM, 1)
define(PORT_ERA, 2)

define(NODE_CON, 0)
define(NODE_OP1, 1)
define(NODE_OP2, 2)
define(NODE_ITE, 3)

define(OP_ADD, 0)
define(OP_SUB, 1)
define(OP_MUL, 2)
define(OP_DIV, 3)
define(OP_MOD, 4)
define(OP_POW, 5)
define(OP_AND, 6)
define(OP_BOR, 7)
define(OP_XOR, 8)
define(OP_NOT, 9)
define(OP_SHR, 10)
define(OP_SHL, 11)
define(OP_GTR, 12)
define(OP_LES, 13)
define(OP_EQL, 14)

;; input  = [pointer, ...]
;; output = [port value, port address, ...]
define(NET_LOAD,
	`PUSH 2
	SHL
	PUSH NET
	ADD
	DUP1
	MLOAD')dnl

;; input  = [info, ...]
;; output = [kind, ...]
define(INFO_KIND,
	`PUSH 6
	SHR
	PUSH 3
	AND')dnl

;; input  = [info, ...]
;; output = [type of port N, ...]
define(INFO_TYPE,
	`PUSH eval($1 * 2)
	SHR
	PUSH 3
	AND')dnl

define(STORE_LABEL,
`PUSH $3
PUSH eval($1 + $2 * 32)
MSTORE')dnl

divert(0)dnl
;; setup OP1 jump table in memory[OP_TABLE]
STORE_LABEL(OP_TABLE, OP_ADD, @num_opI_add)
STORE_LABEL(OP_TABLE, OP_SUB, @num_opI_sub)
STORE_LABEL(OP_TABLE, OP_MUL, @num_opI_mul)
STORE_LABEL(OP_TABLE, OP_DIV, @num_opI_div)
STORE_LABEL(OP_TABLE, OP_MOD, @num_opI_mod)
STORE_LABEL(OP_TABLE, OP_POW, @num_opI_pow)
STORE_LABEL(OP_TABLE, OP_AND, @num_opI_and)
STORE_LABEL(OP_TABLE, OP_BOR, @num_opI_bor)
STORE_LABEL(OP_TABLE, OP_XOR, @num_opI_xor)
STORE_LABEL(OP_TABLE, OP_NOT, @num_opI_not)
STORE_LABEL(OP_TABLE, OP_SHR, @num_opI_shr)
STORE_LABEL(OP_TABLE, OP_SHL, @num_opI_shl)
STORE_LABEL(OP_TABLE, OP_GTR, @num_opI_gtr)
STORE_LABEL(OP_TABLE, OP_LES, @num_opI_les)
STORE_LABEL(OP_TABLE, OP_EQL, @num_opI_eql)
;; XXX: floating point operations?

;; load net into memory[NET]
PUSH INPUT_NET
DUP1
CALLDATASIZE
SUB
DUP1
SWAP2
PUSH NET
CALLDATACOPY

;; load redex address
PUSH INPUT_REDEX
CALLDATALOAD
PUSH 2
SHL

GAS
SWAP1

;; stack = [redex, gas, net size]
rewrite:
	;; load node A
	DUP1
	NET_LOAD

	;; push A[0:3] onto stack
	PUSH 128
	SHR
	DUP1
	PUSH 0xffffffff
	AND
	SWAP1
	PUSH 32
	SHR
	DUP1
	PUSH 0xffffffff
	AND
	SWAP1
	PUSH 32
	SHR
	DUP1
	PUSH 0xffffffff
	AND
	SWAP1
	PUSH 32
	SHR

	;; push A port[0] type
	DUP4
	PUSH 3
	AND

	;; A port[0] type == PTR -> @ptr
	DUP1
	ISZERO
	JUMPI @ptr

	;; A port[0] == NUM -> @num
	PUSH 1
	EQ
	JUMPI @num

	;; otherwise -> @era
era:
	;; TODO: implement
	STOP

num:
	;; load A kind
	DUP4
	INFO_KIND

	;; A kind == CON -> @num_con
	DUP1
	ISZERO
	JUMPI @num_con

	;; A kind == OP1 -> @num_op1
	DUP1
	PUSH NODE_OP1
	EQ
	JUMPI @num_opI

	;; A kind == OP2 -> @num_opII
	PUSH NODE_OP2
	EQ
	JUMPI @num_opII

	;; otherwise -> @num_ite
num_ite:
	DUP4
	PUSH 0xffffff00
	AND
	DUP5
	INFO_TYPE(1)
	OR

	;; net[a[0]] &= ~3
	DUP3
	NET_LOAD
	PUSH 0xfffffffcffffffffffffffffffffffffffffffffffffffffffffffffffffffff
	AND
	SWAP1
	MSTORE

	SWAP1
	ISZERO
	JUMPI @num_ite_false

	DUP4
	PUSH 2
	SHR
	PUSH eval(3 << 2)
	AND
	PUSH eval(PORT_ERA << 4)
	OR

	OR

	SWAP3
	POP
	PUSH 0xffffffff
	SWAP2
	SWAP1

	;; nodes[a[1]] ^= 3
	DUP2
	NET_LOAD
	PUSH 0x0000000300000000000000000000000000000000000000000000000000000000
	XOR
	SWAP1
	MSTORE

	JUMP @store_A

num_ite_false:
	DUP4
	PUSH eval(3 << 4)
	AND
	PUSH eval(PORT_ERA << 2)
	OR

	OR

	SWAP3
	POP
	PUSH 0xffffffff
	SWAP1

	JUMP @store_A

num_opI:
	POP

	;; load op code
	DUP4
	PUSH 8
	SHR

	;; jump to op label
	PUSH 5
	SHL
	MLOAD
	JUMP

num_opI_add:
	ADD
	JUMP @num_opI_finish
num_opI_sub:
	SUB
	JUMP @num_opI_finish
num_opI_mul:
	MUL
	JUMP @num_opI_finish
num_opI_div:
	DIV
	JUMP @num_opI_finish
num_opI_mod:
	MOD
	JUMP @num_opI_finish
num_opI_pow:
	EXP
	JUMP @num_opI_finish
num_opI_and:
	AND
	JUMP @num_opI_finish
num_opI_bor:
	OR
	JUMP @num_opI_finish
num_opI_xor:
	XOR
	JUMP @num_opI_finish
num_opI_not:
	NOT
	JUMP @num_opI_finish
num_opI_shr:
	SHR
	JUMP @num_opI_finish
num_opI_shl:
	SHL
	JUMP @num_opI_finish
num_opI_gtr:
	GT
	JUMP @num_opI_finish
num_opI_les:
	LT
	JUMP @num_opI_finish
num_opI_eql:
	EQ

num_opI_finish:
	PUSH 224
	SHL

	;; XXX: condition on A type[2] == PTR

	;; load net[A[2]]
	SWAP1
	NET_LOAD

	;; set port to result
	PUSH 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
	AND
	DUP3
	OR
	DUP2
	MSTORE
	SWAP1
	POP

	;; set port type to NUM
	PUSH 0xf
	OR
	DUP1
	MLOAD
	PUSH 1
	OR
	SWAP1
	MSTORE8

	POP
	;; XXX: free A addr
	POP
	JUMP @return

num_opII:
	;; swap A[0] and A[1]
	SWAP1

	SWAP3
	PUSH eval(NODE_OP1 << 6 | PORT_NUM << 2)

	;; push A[3] & ~(3 << 6 | 3 << 0 | 3 << 2)
	DUP2
	PUSH 0xffffff30
	AND

	;; push A type[1]
	SWAP2
	INFO_TYPE(1)

	DUP1
	PUSH 0
	LT
	JUMPI @num_opII_nonptr

	;; load net[A[0]]
	DUP6
	NET_LOAD

	;; set port to 0 then store
	PUSH 0xfffffffcffffffffffffffffffffffffffffffffffffffffffffffffffffffff
	AND
	SWAP1
	MSTORE

num_opII_nonptr:
	OR
	OR
	SWAP3

	JUMP @store_A

num_con:
	POP

	DUP4
	INFO_TYPE(1)
	JUMPI @num_con_II

	;; net[a[1]] = a[0]
	DUP2
	NET_LOAD
	PUSH 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
	AND
	DUP3
	PUSH 224
	SHL
	OR
	DUP2
	MSTORE

	;; set net[a[1] | 3] port type[a[1] & 3] to NUM
	PUSH 0xc
	OR
	DUP1
	MLOAD
	DUP4
	PUSH 3
	AND
	PUSH 1
	SHL
	PUSH 224
	ADD
	PUSH PORT_NUM
	SWAP1
	SHL
	OR
	SWAP1
	MSTORE

num_con_II:
	SWAP1
	POP

	DUP3
	INFO_TYPE(2)
	JUMPI @num_con_done

	;; net[a[2]] = a[0]
	DUP2
	NET_LOAD
	PUSH 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
	AND
	DUP3
	PUSH 224
	SHL
	OR
	DUP2
	MSTORE

	;; set net[a[2] | 3] port type[a[2] & 3] to NUM
	PUSH 0xc
	OR
	DUP1
	MLOAD
	DUP4
	PUSH 3
	AND
	PUSH 1
	SHL
	PUSH 224
	ADD
	PUSH PORT_NUM
	SWAP1
	SHL
	OR
	SWAP1
	MSTORE

num_con_done:
	POP
	POP
	POP
	POP
	;; XXX: free redex
	JUMP @return

ptr:
	POP
	;; TODO: implement
	STOP

store_A:
	;; load A[0:3] into stack[0] bits 128:255
	PUSH 96
	SHL
	SWAP1
	PUSH 64
	SHL
	OR
	SWAP1
	PUSH 32
	SHL
	OR
	OR
	PUSH 128
	SHL

	;; store stack[0] into net[A addr]
	DUP2
	MLOAD
	PUSH 0xffffffffffffffffffffffffffffffff
	AND
	OR
	SWAP1
	MSTORE

return:
	POP

	;; calculate gas used
	GAS
	SWAP1
	SUB
	PUSH eval(NET - 32)
	SWAP1
	DUP2
	MSTORE

	;; return net
	SWAP1
	PUSH 32
	ADD
	SWAP1
	RETURN
