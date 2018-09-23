module mangle_byte;

import object;
import types;


class TypeInfo_g : TypeInfo {
    @trusted:
    const:
    pure:
    nothrow:

    override string toString() const pure nothrow @safe { 
        return "byte"; 
    }

    override size_t getHash(scope const void* p) {
        return *cast(const ubyte *)p;
    }

    override bool equals(in void* p1, in void* p2) {
        return *cast(byte *)p1 == *cast(byte *)p2;
    }

    override int compare(in void* p1, in void* p2) {
        return *cast(byte *)p1 - *cast(byte *)p2;
    }

    override @property size_t tsize() nothrow pure {
        return byte.sizeof;
    }

    override const(void)[] initializer() @trusted {
        return (cast(void *)null)[0 .. byte.sizeof];
    }

    override void swap(void *p1, void *p2) {
        byte t;

        t = *cast(byte *)p1;
        *cast(byte *)p1 = *cast(byte *)p2;
        *cast(byte *)p2 = t;
    }
}
