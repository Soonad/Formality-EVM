divert(-1)

;; offset of redex in input
define(INPUT_REDEX, 0x0)
;; offset of net in input
define(INPUT_NET, 0x20)

;; address of op jump table in memory
define(OP_TABLE, 0x0)
;; address of type jump table in memory
define(TYPE_TABLE, 0x200)
;; address of scratch memory
define(SCRATCH, 0x300)
;; address of net in memory
define(NET, 0x400)

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
	`PUSH 3
	SHL
	PUSH NET
	ADD
	DUP1
	MLOAD')

;; usage  NET_SET(type, stack index of value in highest 64 bits)
;; input  = [pointer, ...]
;; output = [...]
define(NET_SET,
	`DUP1
	NET_LOAD

	;; clear old value
	PUSH 0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff
	AND

	ifelse($2, `', `',
	`;; set new value
	DUP`'eval($2 + 2)
	OR')

	;; store
	DUP2
	MSTORE

	;; compute address of port type
	PUSH eval(3 << 3)
	OR
	SWAP1
	PUSH 3
	AND
	PUSH 7
	SUB
	ADD

	;; set port type
	PUSH $1
	SWAP1
	MSTORE8')

;; input  = [node, ...]
;; output = [kind, ...]
define(NODE_KIND,
	`PUSH 28
	BYTE')

;; input  = [node, ...]
;; output = [type of port N, ...]
define(NODE_PORT_TYPE,
	`PUSH eval(31 - $1)
	BYTE')

;; input  = [node, ...]
;; output = [port N, ...]
define(NODE_PORT,
	`PUSH eval(192 - $1 * 64)
	SHR
	ifelse($1, 0, `',
	`PUSH 0xffffffffffffffff
	AND')')

;; input  = [node, ...]
;; output = [label, ...]
define(NODE_LABEL,
	`PUSH 32
	SHR
	PUSH 0xffffffff
	AND')

define(STORE_LABEL,
`PUSH $3
PUSH eval($1 + $2 * 32)
MSTORE')

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

;; setup port 0 type jump table in memory[TYPE_TABLE]
STORE_LABEL(TYPE_TABLE, PORT_PTR, @ptr)
STORE_LABEL(TYPE_TABLE, PORT_NUM, @num)
STORE_LABEL(TYPE_TABLE, PORT_ERA, @era)

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

	;; push A port[0] type
	DUP1
	NODE_PORT_TYPE(0)

	PUSH 5
	SHL
	PUSH TYPE_TABLE
	ADD
	MLOAD
	JUMP

ptr:
	;; TODO: implement
	STOP

num:
	;; load A kind
	DUP1
	NODE_KIND

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
	;; clear info bits (except A[2] type), A[0], and A[1]
	DUP1
	PUSH 0x00000000000000000000000000000000ffffffffffffffff0000000000ff0000
	AND

	;; set A'[0] type to A[1] type
	DUP2
	NODE_PORT_TYPE(1)
	OR

	;; set A'[0] to A[1]
	DUP2
	PUSH 0x0000000000000000ffffffffffffffff00000000000000000000000000000000
	AND
	PUSH 64
	SHL
	OR

	;; set net[A'[0]] slot to 0
	DUP1
	NODE_PORT(0)
	NET_LOAD
	PUSH 0xfffffffffffffffcffffffffffffffffffffffffffffffffffffffffffffffff
	AND
	SWAP1
	MSTORE

	DUP2
	NODE_PORT(0)
	JUMPI @num_ite_true

	;; set A'[1] type to ERA
	PUSH eval(PORT_ERA << 8)
	OR

	SWAP1
	POP
	SWAP1

	JUMP @store_A

num_ite_true:
	;; set A'[1] to A[2]
	DUP2
	PUSH 0x00000000000000000000000000000000ffffffffffffffff0000000000000000
	AND
	PUSH 64
	SHL
	OR

	;; clear A'[2] and A'[2] type
	PUSH 0xffffffffffffffffffffffffffffffff0000000000000000ffffffffff00ffff
	AND

	;; set A'[1] type to A[2] type
	DUP2
	NODE_PORT_TYPE(2)
	PUSH 8
	SHL
	OR

	;; set A'[2] type to ERA
	PUSH eval(PORT_ERA << 16)
	OR

	;; net[A'[1]] ^= 3
	DUP1
	NODE_PORT(1)
	NET_LOAD
	PUSH 0x0000000000000003000000000000000000000000000000000000000000000000
	XOR
	SWAP1
	MSTORE

	SWAP1
	POP
	SWAP1

	JUMP @store_A

num_opI:
	POP

	;; push A[1]
	DUP1
	NODE_PORT(1)

	;; push A[0]
	DUP2
	NODE_PORT(0)

	;; push op code
	DUP3
	NODE_LABEL

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
	;; shift result into the upper 64-bits
	PUSH 192
	SHL

	DUP2
	NODE_PORT(2)

	NET_SET(PORT_NUM, 2)
	POP
	POP
	POP
	;; XXX: free A addr
	JUMP @return

num_opII:
	DUP1
	PUSH 0xffffffffffffffffffffffff00ff0000
	AND

	;; set A'[1] to A[0]
	DUP2
	PUSH 64
	SHR
	PUSH 0x0000000000000000ffffffffffffffff00000000000000000000000000000000
	AND
	OR

	;; set A'[0] to A[1]
	DUP2
	PUSH 64
	SHL
	PUSH 0xffffffffffffffff000000000000000000000000000000000000000000000000
	AND
	OR

	DUP2
	NODE_PORT_TYPE(1)
	OR

	PUSH eval(NODE_OP1 << 24 | PORT_NUM << 8)
	OR

	SWAP1
	POP
	SWAP1

	;; push A' type[0]
	DUP2
	NODE_PORT_TYPE(0)

	JUMPI @store_A

	;; load net[A[0]]
	DUP2
	NODE_PORT(0)
	NET_LOAD

	;; set port to 0 then store
	PUSH 0xfffffffffffffffcffffffffffffffffffffffffffffffffffffffffffffffff
	AND
	SWAP1
	MSTORE

	JUMP @store_A

num_con:
	POP

	DUP1
	PUSH 0xffffffffffffffff000000000000000000000000000000000000000000000000
	AND

	DUP2
	NODE_PORT_TYPE(1)
	JUMPI @num_con_II

	DUP2
	NODE_PORT(1)
	NET_SET(PORT_NUM, 2)

num_con_II:
	SWAP1

	DUP1
	NODE_PORT_TYPE(2)
	JUMPI @num_con_done

	NODE_PORT(2)
	NET_SET(PORT_NUM, 2)

	PUSH 0 ;; to equilize stack between branches

num_con_done:
	POP
	POP
	POP
	;; XXX: free redex
	JUMP @return

era:
	;; check if port 1 type is PORT_PTR
	DUP1
	NODE_PORT_TYPE(1)
	JUMPI @era_II

	DUP1
	NODE_PORT(1)
	NET_SET(PORT_ERA)

era_II:
	;; check if port 2 type is PORT_PTR
	DUP1
	NODE_PORT_TYPE(2)
	JUMPI @era_done

	DUP1
	NODE_PORT(2)
	NET_SET(PORT_ERA)

era_done:
	POP
	POP
	;; XXX: free redex
	JUMP @return

store_A:
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
