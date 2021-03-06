module mangle_cfloat;

import object;
import types;
import mock;


class TypeInfo_q : TypeInfo {
  pure:
  nothrow:
  @safe:

    alias F = float;

    override string toString() const { 
        return F.stringof; 
    }

    override size_t getHash(scope const void* p) const @trusted {
        return hashOf(*cast(F*)p);
    }

    override bool equals(in void* p1, in void* p2) const @trusted {
        return memcmp(p1, p2, F.sizeof) == 0;
    }

    override int compare(in void* p1, in void* p2) const @trusted {
        return memcmp(p1, p2, F.sizeof);
    }

    override @property size_t tsize() const {
        return F.sizeof;
    }

    override void swap(void *p1, void *p2) const @trusted {
        F t = *cast(F*)p1;
        *cast(F*)p1 = *cast(F*)p2;
        *cast(F*)p2 = t;
    }

    override const(void)[] initializer() const @trusted {
        static immutable F r;
        return (&r)[0 .. 1];
    }

    override @property size_t talign() const {
        return F.alignof;
    }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
        arg1 = typeid(float);
        return 0;
    }
}
