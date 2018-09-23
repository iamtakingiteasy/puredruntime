module memory;

import types;

nothrow pure @nogc {
    extern (C) void* malloc(size_t n);
    extern (C) void* calloc(size_t nmemb, size_t n);
    extern (C) void* realloc(void *p, size_t n);
    extern (C) void free(void *p);
}

struct GC {
    @disable this();

    static struct Stats {
        size_t usedSize;
        size_t freeSize;
    }

    static void enable() nothrow {
    }
   
    static void disable() nothrow {
    }

    static void collect() nothrow {
    }

    static void minimize() nothrow {
    }


    enum BlkAttr : uint {
        NONE        = 0b0000_0000,
        FINALIZE    = 0b0000_0001,
        NO_SCAN     = 0b0000_0010,
        NO_MOVE     = 0b0000_0100,
        APPENDABLE  = 0b0000_1000,
        NO_INTERIOR = 0b0001_0000,
        STRUCTFINAL = 0b0010_0000,
    }

    struct BlkInfo {
        void*  base;
        size_t size;
        uint   attr;
    }

    static uint getAttr(in void* p) nothrow {
        return 0;
    }

    static uint getAttr(void* p) pure nothrow {
        return 0;
    }

    static uint setAttr(in void* p, uint a) nothrow {
        return 0;
    }

    static uint setAttr(void* p, uint a) pure nothrow {
        return 0;
    }

    static uint clrAttr( in void* p, uint a ) nothrow {
        return 0;
    }

    static uint clrAttr(void* p, uint a) pure nothrow {
        return 0;
    }

    static void* malloc( size_t sz, uint ba = 0, const TypeInfo ti = null ) pure nothrow {
        return memory.malloc(sz);
    }
    
    static BlkInfo qalloc( size_t sz, uint ba = 0, const TypeInfo ti = null ) pure nothrow {
        BlkInfo b;
        b.base = memory.malloc(sz);
        b.size = sz;
        b.attr = ba;
        return b;
    }

    static void* calloc( size_t sz, uint ba = 0, const TypeInfo ti = null ) pure nothrow {
        return memory.calloc(1, sz);
    }

    static void* realloc( void* p, size_t sz, uint ba = 0, const TypeInfo ti = null ) pure nothrow {
        return memory.realloc(p, sz);
    }

    static size_t extend( void* p, size_t mx, size_t sz, const TypeInfo ti = null ) pure nothrow {
        return 0;
    }

    static size_t reserve(size_t sz) nothrow {
        return 0;
    }

    static void free(void* p) pure nothrow @nogc {
        memory.free(p);
    }

    static inout(void)* addrOf(inout(void)* p) nothrow @nogc {
        return p;
    }

    static void* addrOf(void* p) pure nothrow @nogc {
        return p;
    }

    static size_t sizeOf(in void* p) nothrow @nogc {
        return 0;
 //       return gc_sizeOf(cast(void*)p);
    }

    static size_t sizeOf(void* p) pure nothrow @nogc {
        return 0;
    }

    static BlkInfo query(in void* p) nothrow {
        BlkInfo b;
        b.base = cast(void*)p;
        b.size = 0;
        b.attr = 0;
        return b;
    }

    static BlkInfo query(void* p) pure nothrow {
        BlkInfo b;
        b.base = p;
        b.size = 0;
        b.attr = 0;
        return b;
    }

    static Stats stats() nothrow {
        Stats s;
        return s;
    }
    static void addRoot(in void* p) nothrow @nogc {
    }
    
    static void removeRoot(in void* p) nothrow @nogc {
    }

    static void addRange(in void* p, size_t sz, const TypeInfo ti = null) @nogc nothrow {
    }

    static void removeRange(in void* p) nothrow @nogc {
    }

    static void runFinalizers(in void[] segment) {
    }
}
