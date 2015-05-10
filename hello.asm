extern _puts

section .data
	hello_world_str db "Hello, world!", 10, 0

section .text
global _main

_main:
	push hello_world_str
	call _puts
	add esp, 4
	ret

