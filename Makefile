CC = gcc
ASM = nasm

CFLAGS = -c
ASMFLAGS = -f elf64

TARGET = f
OBJS = main.o f.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $(TARGET) $(OBJS)

main.o: main.c f.h
	$(CC) $(CFLAGS) -o main.o main.c

f.o: f.asm
	$(ASM) $(ASMFLAGS) -o f.o f.asm

clean:
	rm -f $(TARGET) $(OBJS)
	rm result.bmp
