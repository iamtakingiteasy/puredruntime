module mangle_ulong;

import object;
import types;


class TypeInfo_m : TypeInfo {
    @trusted:
    const:
    pure:
    nothrow:

    override string toString() const pure nothrow @safe { 
        return "ulong"; 
    }

    override size_t getHash(scope const void* p) {
        static if (ulong.sizeof <= size_t.sizeof) {
            return *cast(const ulong*)p;
        } else {
            return hashOf(*cast(const ulong*)p);
        }
    }

    override bool equals(in void* p1, in void* p2) {
        return *cast(ulong *)p1 == *cast(ulong *)p2;
    }

    override int compare(in void* p1, in void* p2) {
        if (*cast(ulong *)p1 < *cast(ulong *)p2) {
            return -1;
        } else if (*cast(ulong *)p1 > *cast(ulong *)p2) {
            return 1;
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure {
        return ulong.sizeof;
    }

    override const(void)[] initializer() const @trusted {
        return (cast(void *)null)[0 .. ulong.sizeof];
    }

    override void swap(void *p1, void *p2) {
        ulong t;

        t = *cast(ulong *)p1;
        *cast(ulong *)p1 = *cast(ulong *)p2;
        *cast(ulong *)p2 = t;
    }

    override @property size_t talign() nothrow pure {
        return ulong.alignof;
    }
}
