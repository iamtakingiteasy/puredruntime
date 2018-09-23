.PHONY: all clean wasm test

SRC = src/object.d \
	  src/runtime.d \
	  src/types.d \
	  src/mock.d \
	  src/traits.d \
	  src/templates.d \
	  src/memory.d \
	  src/mangle.d \
	  src/mangle_void.d \
	  src/mangle_char.d \
	  src/mangle_byte.d \
	  src/mangle_ubyte.d \
	  src/mangle_cdouble.d \
	  src/mangle_double.d  \
	  src/mangle_ulong.d  \
	  src/mangle_cfloat.d \
	  src/mangle_float.d \
	  src/mangle_uint.d \
	  src/moduleref.d # must be last

all: clean test

clean:
	rm -f *.o
	rm -f *.a
	rm -f *.wasm
	rm -f object

test:
	ldc2 -defaultlib= $(SRC) -main -unittest
	./object

wasm:
	ldc2 -mtriple=wasm32-unknown-unknown-wasm -defaultlib= $(SRC) -link-internally -L--no-entry -L--allow-undefined
