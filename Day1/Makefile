all:
	nasm -f elf64 -F dwarf -g frequency_1.asm
	gcc frequency_1.o -o frequency_1

	nasm -f elf64 -F dwarf -g frequency_2.asm
	nasm -f elf64 -F dwarf -g dynamic_array.asm
	gcc frequency_2.o dynamic_array.o -o frequency_2

clean:
	rm frequency_*
	rm *.o