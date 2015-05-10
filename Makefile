all: task1
	
hello: 
	mkdir build
	yasm -f win32 hello.asm -o build/hello.o
	gcc build/hello.o -o hello.exe
	rm -r build
	
task1:
	yasm -f win32 task1.asm -o build/task1.o
	gcc build/task1.o -o task1.exe