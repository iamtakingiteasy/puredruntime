module mangle;

import types;
import object;
import mock;

class TypeInfo_Ag : TypeInfo_Array {
    override bool opEquals(Object o) { 
        return TypeInfo.opEquals(o); 
    }

    override string toString() const { 
        return "byte[]"; 
    }

    override size_t getHash(scope const void* p) @trusted const {
        const s = *cast(const void[]*)p;
        return hashOf(s);
    }

    override bool equals(in void* p1, in void* p2) const {
        byte[] s1 = *cast(byte[]*)p1;
        byte[] s2 = *cast(byte[]*)p2;

        return s1.length == s2.length && memcmp(cast(byte *)s1, cast(byte *)s2, s1.length) == 0;
    }

    override int compare(in void* p1, in void* p2) const {
        byte[] s1 = *cast(byte[]*)p1;
        byte[] s2 = *cast(byte[]*)p2;
        size_t len = s1.length;

        if (s2.length < len) {
            len = s2.length;
        }

        for (size_t u = 0; u < len; u++) {
            int result = s1[u] - s2[u];
            if (result) {
                return result;
            }
        }

        if (s1.length < s2.length) {
            return -1;
        } else if (s1.length > s2.length) {
            return 1;
        }
        return 0;
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(byte);
    }
}

class TypeInfo_Ah : TypeInfo_Ag {
    override string toString() const { 
        return "ubyte[]"; 
    }

    override int compare(in void* p1, in void* p2) const {
        char[] s1 = *cast(char[]*)p1;
        char[] s2 = *cast(char[]*)p2;

        return strcmp(cast(immutable char*)s1.ptr, cast(immutable char*)s2.ptr);
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(ubyte);
    }
}

class TypeInfo_Av : TypeInfo_Ah {
    override string toString() const { 
        return "void[]"; 
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(void);
    }
}

class TypeInfo_Ab : TypeInfo_Ah {
    override string toString() const { 
        return "bool[]"; 
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(bool);
    }
}

class TypeInfo_Aa : TypeInfo_Ah {
    override string toString() const { 
        return "char[]";
    }

    override size_t getHash(scope const void* p) @trusted const {
        char[] s = *cast(char[]*)p;
        return hashOf(s);
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(char);
    }
}

class TypeInfo_Aya : TypeInfo_Aa {
    override string toString() const { 
        return "immutable(char)[]"; 
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(immutable(char));
    }
}

class TypeInfo_Axa : TypeInfo_Aa {
    override string toString() const { 
        return "const(char)[]"; 
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(const(char));
    }
}

class TypeInfo_Ar : TypeInfo_Array {
    alias F = cdouble;

    override bool opEquals(Object o) { 
        return TypeInfo.opEquals(o); 
    }

    override string toString() const { 
        return (F[]).stringof; 
    }

    override size_t getHash(scope const void* p) @trusted const {
        return hashOf(*cast(F[]*)p);
    }

    override bool equals(in void* p1, in void* p2) const {
        F[] fp1 = *cast(F[]*)p1;
        F[] fp2 = *cast(F[]*)p2;

        size_t len = fp1.length;
        if (fp2.length < len) {
            len = fp2.length;
        }

        return memcmp(fp1.ptr, fp2.ptr, len) == 0;
    }

    override int compare(in void* p1, in void* p2) const {
        F[] fp1 = *cast(F[]*)p1;
        F[] fp2 = *cast(F[]*)p2;

        size_t len = fp1.length;
        if (fp2.length < len) {
            len = fp2.length;
        }

        return memcmp(fp1.ptr, fp2.ptr, len);
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(F);
    }
}


class TypeInfo_Aq : TypeInfo_Array {
    alias F = cfloat;

    override bool opEquals(Object o) { return TypeInfo.opEquals(o); }

    override string toString() const { return (F[]).stringof; }

    override size_t getHash(scope const void* p) @trusted const {
        return hashOf(*cast(F[]*)p);
    }

    override bool equals(in void* p1, in void* p2) const {
        F[] fp1 = *cast(F[]*)p1;
        F[] fp2 = *cast(F[]*)p2;

        size_t len = fp1.length;
        if (fp2.length < len) {
            len = fp2.length;
        }

        return memcmp(fp1.ptr, fp2.ptr, len) == 0;
    }

    override int compare(in void* p1, in void* p2) const {
        F[] fp1 = *cast(F[]*)p1;
        F[] fp2 = *cast(F[]*)p2;

        size_t len = fp1.length;
        if (fp2.length < len) {
            len = fp2.length;
        }

        return memcmp(fp1.ptr, fp2.ptr, len);
    }

    override @property inout(TypeInfo) next() inout {
        return cast(inout)typeid(F);
    }
}

