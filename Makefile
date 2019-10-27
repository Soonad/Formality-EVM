.POSIX:
.PHONY: all check clean
.SUFFIXES: .evm .easm

EVM?=evm

all: net.evm

.easm.evm:
	$(EVM) compile $< >$@

check: net.evm
	./runtests

clean:
	rm -f net.evm
