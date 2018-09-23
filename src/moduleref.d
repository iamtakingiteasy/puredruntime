module moduleref;

import object;
import types;
import mock;
import memory;

extern(C) size_t _d_array_cast_len(size_t len, size_t elemsz, size_t newelemsz) {
    if (newelemsz == 1) {
        return len*elemsz;
    } else if ((len*elemsz) % newelemsz) {
        return 0;
    }
    return (len*elemsz)/newelemsz;
}

extern (C) void* _d_dynamic_cast(Object o, ClassInfo c) {
    size_t offset = 0;

    if (o) {
        return (cast(void*)o + offset);
    }

    return cast(void*)o;
}

inout(TypeInfo) unqualify(inout(TypeInfo) cti) pure nothrow @nogc {
    TypeInfo ti = cast() cti;
    while (ti) {
        auto tti = typeid(ti);
        if (tti is typeid(TypeInfo_Const)) {
            ti = (cast(TypeInfo_Const)cast(void*)ti).base;
        } else if (tti is typeid(TypeInfo_Invariant)) {
            ti = (cast(TypeInfo_Invariant)cast(void*)ti).base;
        } else if (tti is typeid(TypeInfo_Shared)) {
            ti = (cast(TypeInfo_Shared)cast(void*)ti).base;
        } else if (tti is typeid(TypeInfo_Inout)) {
            ti = (cast(TypeInfo_Inout)cast(void*)ti).base;
        } else {
            break;
        }
    }
    return ti;
}

extern (C) void[] _d_arraycatnTX(const TypeInfo ti, byte[][] arrs) {
    size_t length;
    auto tinext = unqualify(ti.next);
    auto size = tinext.tsize;

    foreach(b; arrs) {
        length += b.length;
    }

    if (!length) {
        return null;
    }

    auto allocsize = length * size;
    auto info = __arrayAlloc(allocsize, ti, tinext);
    auto isshared = typeid(ti) is typeid(TypeInfo_Shared);
    __setArrayAllocLength(info, allocsize, isshared, tinext);
    void *a = __arrayStart (info);

    size_t j = 0;
    foreach(b; arrs) {
        if (b.length) {
            memcpy(a + j, b.ptr, b.length * size);
            j += b.length * size;
        }
    }

    __doPostblit(a, j, tinext);

    return a[0..length];
}

enum : size_t {
    PAGESIZE = 4096,
    BIGLENGTHMASK = ~(PAGESIZE - 1),
    SMALLPAD = 1,
    MEDPAD = ushort.sizeof,
    LARGEPREFIX = 16,
    LARGEPAD = LARGEPREFIX + 1,
    MAXSMALLSIZE = 256-SMALLPAD,
    MAXMEDSIZE = (PAGESIZE / 2) - MEDPAD,
}

T addu(T)(T x, T y, ref bool overflow) {
    immutable T r = x + y;
    if (r < x || r < y) {
        overflow = true;
    }
    return r;
}

T mulu(T)(T x, T y, ref bool overflow) {
    immutable T r = T(x) * T(y);
    if (r < x || r < y) {
        overflow = true;
    }
    return r;
}

size_t structTypeInfoSize(const TypeInfo ti) pure nothrow @nogc {
    if (ti && typeid(ti) is typeid(TypeInfo_Struct)) {
        auto sti = cast(TypeInfo_Struct)cast(void*)ti;
        if (sti.xdtor) {
            return size_t.sizeof;
        }
    }
    return 0;
}

GC.BlkInfo __arrayAlloc(size_t arrsize, const TypeInfo ti, const TypeInfo tinext) nothrow pure {
    size_t typeInfoSize = structTypeInfoSize(tinext);
    size_t padsize = arrsize > MAXMEDSIZE ? LARGEPAD : ((arrsize > MAXSMALLSIZE ? MEDPAD : SMALLPAD) + typeInfoSize);

    bool overflow;
    auto padded_size = addu(arrsize, padsize, overflow);

    if (overflow) {
        return GC.BlkInfo();
    }

    uint attr = (!(tinext.flags & 1) ? GC.BlkAttr.NO_SCAN : 0) | GC.BlkAttr.APPENDABLE;
    if (typeInfoSize) {
        attr |= GC.BlkAttr.STRUCTFINAL | GC.BlkAttr.FINALIZE;
    }
    return GC.qalloc(padded_size, attr, ti);
}

bool cas(T)(shared T* d, T expect, T newvalue) {
    if (*d == expect) {
        return false;
    } else {
        *d = newvalue;
        return true;
    }
}

bool __setArrayAllocLength(ref GC.BlkInfo info, size_t newlength, bool isshared, const TypeInfo tinext, size_t oldlength = ~0) pure nothrow {
    size_t typeInfoSize = structTypeInfoSize(tinext);

    if(info.size <= 256) {
        bool overflow;
        auto newlength_padded = addu(newlength, addu(SMALLPAD, typeInfoSize, overflow), overflow);

        if(newlength_padded > info.size || overflow) {
            return false;
        }

        auto length = cast(ubyte *)(info.base + info.size - typeInfoSize - SMALLPAD);

        if(oldlength != ~0) {
            if(isshared) {
                return cas(cast(shared)length, cast(ubyte)oldlength, cast(ubyte)newlength);
            } else {
                if(*length == cast(ubyte)oldlength) {
                    *length = cast(ubyte)newlength;
                } else {
                    return false;
                }
            }
        } else {
            *length = cast(ubyte)newlength;
        } if (typeInfoSize) {
            auto typeInfo = cast(TypeInfo*)(info.base + info.size - size_t.sizeof);
            *typeInfo = cast() tinext;
        }
    } else if(info.size < PAGESIZE) {
        if(newlength + MEDPAD + typeInfoSize > info.size) {
            return false;
        }
        auto length = cast(ushort *)(info.base + info.size - typeInfoSize - MEDPAD);
        if(oldlength != ~0) {
            if(isshared) {
                return cas(cast(shared)length, cast(ushort)oldlength, cast(ushort)newlength);
            } else {
                if(*length == oldlength) {
                    *length = cast(ushort)newlength;
                } else {
                    return false;
                }
            }
        } else {
            *length = cast(ushort)newlength;
        }
        if (typeInfoSize) {
            auto typeInfo = cast(TypeInfo*)(info.base + info.size - size_t.sizeof);
            *typeInfo = cast() tinext;
        }
    } else {
        if(newlength + LARGEPAD > info.size) {
            return false;
        }
        auto length = cast(size_t *)(info.base);
        if(oldlength != ~0) {
            if(isshared) {
                return cas(cast(shared)length, cast(size_t)oldlength, cast(size_t)newlength);
            } else {
                if(*length == oldlength) {
                    *length = newlength;
                } else {
                    return false;
                }
            }
        } else {
            *length = newlength;
        }
        if (typeInfoSize) {
            auto typeInfo = cast(TypeInfo*)(info.base + size_t.sizeof);
            *typeInfo = cast()tinext;
        }
    }
    return true;
}

void *__arrayStart(GC.BlkInfo info) nothrow pure {
    return info.base + ((info.size & BIGLENGTHMASK) ? LARGEPREFIX : 0);
}

bool hasPostblit(in TypeInfo ti) {
    return (&ti.postblit).funcptr !is &TypeInfo.postblit;
}

void __doPostblit(void *ptr, size_t len, const TypeInfo ti) {
    if (!hasPostblit(ti)) {
        return;
    }

    if(auto tis = cast(TypeInfo_Struct)ti) {
        auto pblit = tis.xpostblit;
        if(!pblit) {
            return;
        }

        immutable size = ti.tsize;
        const eptr = ptr + len;
        for(;ptr < eptr;ptr += size) {
            pblit(ptr);
        }
    } else {
        immutable size = ti.tsize;
        const eptr = ptr + len;
        for(;ptr < eptr;ptr += size) {
            ti.postblit(ptr);
        }
    }
}

extern (C) byte[] _d_arraycatT(const TypeInfo ti, byte[] x, byte[] y) out (result) {
    auto tinext = unqualify(ti.next);
    auto sizeelem = tinext.tsize; 

    size_t cap = GC.sizeOf(result.ptr);
} do {
    auto tinext = unqualify(ti.next);
    auto sizeelem = tinext.tsize;
    size_t xlen = x.length * sizeelem;
    size_t ylen = y.length * sizeelem;
    size_t len  = xlen + ylen;

    if (!len) {
        return null;
    }

    auto info = __arrayAlloc(len, ti, tinext);
    byte* p = cast(byte*)__arrayStart(info);
    p[len] = 0;
    memcpy(p, x.ptr, xlen);
    memcpy(p + xlen, y.ptr, ylen);
    __doPostblit(p, xlen + ylen, tinext);
    auto isshared = typeid(ti) is typeid(TypeInfo_Shared);
    __setArrayAllocLength(info, len, isshared, tinext);
    return p[0 .. x.length + y.length];
}

extern (C) void[] _d_newarrayU(const TypeInfo ti, size_t length) pure nothrow {
    auto tinext = unqualify(ti.next);
    auto size = tinext.tsize;

    if (length == 0 || size == 0) {
        return null;
    }

    bool overflow = false;
    size = mulu(size, length, overflow);
    if (!overflow) {
        goto Lcontinue;
    }

Loverflow:
    return null;
Lcontinue:

    auto info = __arrayAlloc(size, ti, tinext);
    if (!info.base) {
        goto Loverflow;
    }
    auto arrstart = __arrayStart(info);
    auto isshared = typeid(ti) is typeid(TypeInfo_Shared);
    __setArrayAllocLength(info, size, isshared, tinext);
    return arrstart[0..length];
}
extern (C) void[] _d_newarrayT(const TypeInfo ti, size_t length) pure nothrow {
    void[] result = _d_newarrayU(ti, length);
    auto tinext = unqualify(ti.next);
    auto size = tinext.tsize;

    memset(result.ptr, 0, size * length);
    return result;
}

extern (C) void _d_arraybounds(string file, uint line) {
}

struct CompilerDSOData {
    size_t _version;
    void** _slot;
    immutable(ModuleInfo*)* _minfo_beg, _minfo_end;
}
extern(C) void _d_dso_registry(void* data) {
    CompilerDSOData *dso = cast(CompilerDSOData*)data;
    immutable(ModuleInfo*)* p = dso._minfo_beg;
    
    while (p < dso._minfo_end) {
        printf("baka! %s\n".ptr, (*p).name.ptr);
        p++;
    }
}

extern (C) int printf(const char *fmt, ...);

alias ModuleInfo* ModuleReference;
extern (C) ModuleReference _Dmodule_ref;
