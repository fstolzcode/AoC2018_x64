all:
	nasm -f elf64 -F dwarf -g frequency_1.asm
	gcc frequency_1.o -o frequency_1

clean:
	rm frequency_1
	rm *.o