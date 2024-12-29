TARGET:
	nasm -f elf64 -g -F dwarf main.asm
	gcc -nostartfiles -no-pie -o main main.o
