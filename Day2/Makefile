all:
	nasm -f elf64 -F dwarf -g lettercount.asm
	gcc lettercount.o -o lettercount

clean:
	rm lettercount
	rm *.o