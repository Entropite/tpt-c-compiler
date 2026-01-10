# tpt-c-compiler
A C compiler that emits TPTASM instructions specifically for [@lbphacker](https://github.com/lbphacker)'s R3 (a line of computers built in the simulation game "The Powder Toy")
The compiler is roughly based around ANSI C89 although some C features have not been implemented yet.

# Dependencies
[LPEG 1.1.0](https://luarocks.org/modules/gvvaughan/lpeg)
# Usage
lua cli.lua input.c output.asm

