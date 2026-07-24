CC = gcc
CFLAGS = -O2 -Wall -Wextra -Iinclude
LDFLAGS = -lsqlite3 -larchive -lgpgme -lpthread -lz

SRC = $(wildcard src/*.c)
OBJ = $(SRC:.c=.o)
TARGET = flash

.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

src/%.o: src/%.c include/flash.h
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJ) $(TARGET)

install: $(TARGET)
	install -D $(TARGET) /usr/bin/$(TARGET)
