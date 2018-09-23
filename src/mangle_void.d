module mangle_void;

import types;
import object;

class TypeInfo_v : TypeInfo {
    @trusted:
    const:
    pure:
    nothrow:

    override string toString() const pure nothrow @safe { 
        return "void"; 
    }

    override size_t getHash(scope const void* p) {
        return 0;
        //assert(0);
    }

    override bool equals(in void* p1, in void* p2) {
        return *cast(byte *)p1 == *cast(byte *)p2;
    }

    override int compare(in void* p1, in void* p2) {
        return *cast(byte *)p1 - *cast(byte *)p2;
    }

    override @property size_t tsize() nothrow pure {
        return void.sizeof;
    }

    override const(void)[] initializer() const @trusted {
        return (cast(void *)null)[0 .. void.sizeof];
    }

    override void swap(void *p1, void *p2) {
        byte t;

        t = *cast(byte *)p1;
        *cast(byte *)p1 = *cast(byte *)p2;
        *cast(byte *)p2 = t;
    }

    override @property uint flags() nothrow pure {
        return 1;
    }
}
