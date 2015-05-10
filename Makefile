build/hello.exe: 
	yasm -f win32 hello.asm -o build/hello.o
	gcc build/hello.o -o build/hello.exe
