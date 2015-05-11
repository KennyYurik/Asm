all: task1
	
hello: hello.asm
	mkdir build
	yasm -f win32 hello.asm -o build/hello.o
	gcc build/hello.o -o hello.exe
	rm -r build
	
task1: task1.asm
	mkdir build
	yasm -f win32 task1.asm -o build/task1.o
	gcc build/task1.o -o task1.exe
	rm -r build