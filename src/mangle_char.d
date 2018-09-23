module mangle_char;

import object;
import types;

class TypeInfo_a : TypeInfo {
    @trusted:
    const:
    pure:
    nothrow:

    override string toString() const pure nothrow @safe { 
        return "char"; 
    }

    override size_t getHash(scope const void* p) {
        return *cast(const char *)p;
    }

    override bool equals(in void* p1, in void* p2) {
        return *cast(char *)p1 == *cast(char *)p2;
    }

    override int compare(in void* p1, in void* p2) {
        return *cast(char *)p1 - *cast(char *)p2;
    }

    override @property size_t tsize() nothrow pure {
        return char.sizeof;
    }

    override void swap(void *p1, void *p2) {
        char t;

        t = *cast(char *)p1;
        *cast(char *)p1 = *cast(char *)p2;
        *cast(char *)p2 = t;
    }

    override const(void)[] initializer() const @trusted {
        static immutable char c;
        return (&c)[0 .. 1];
    }
}
