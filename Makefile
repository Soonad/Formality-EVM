.POSIX:
.PHONY: all check clean
.SUFFIXES: .evm .easm
.PRECIOUS: net.easm

EVM?=evm
M4?=m4

all: net.evm

net.easm: net.easm.m4
	$(M4) net.easm.m4 >$@.tmp && mv $@.tmp $@

.easm.evm:
	$(EVM) compile $< >$@.tmp && mv $@.tmp $@

check: net.evm
	./runtests

clean:
	rm -f net.evm net.easm
