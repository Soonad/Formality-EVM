.POSIX:
.PHONY: all clean
.SUFFIXES: .evm .easm

EVM?=evm

all: net.evm

.easm.evm:
	$(EVM) compile $< >$@

clean:
	rm -f net.evm
