module object;

import types;
import mock;
import traits;
import templates;

class Object {
    string toString() {
        return typeid(this).name;
    }

    size_t toHash() @trusted nothrow {
        size_t addr = cast(size_t) cast(void*) this;
        return addr ^ (addr >>> 4);
    }

    int opCmp(Object o) {
        return 0; //fixme
    }

    bool opEquals(Object o) {
        return this is o;
    }

    interface Monitor {
        void lock();
        void unlock();
    }

    static Object factory(string classname) {
        auto ci = TypeInfo_Class.find(classname);
        if (ci) {
            return ci.create();
        }
        return null;
    }
}

size_t hashOf(T)(T val, size_t seed = 0) {
    return seed;
}

bool opEquals(Object lhs, Object rhs) {
    if (lhs is rhs) {
        return true;
    }

    if (lhs is null || rhs is null) {
        return false;
    }

    return lhs.opEquals(rhs) && rhs.opEquals(lhs);
}

bool opEquals(const Object lhs, const Object rhs) {
    return opEquals(cast()lhs, cast()rhs);
}

bool _xopEquals(in void*, in void*) {
    return false; // fixme
}

bool __equals(T1, T2)(T1[] lhs, T2[] rhs) {
    alias U1 = Unqual!T1;
    alias U2 = Unqual!T2;

    static @trusted ref R at(R)(R[] r, size_t i) { 
        return r.ptr[i]; 
    }

    static @trusted R trustedCast(R, S)(S[] r) { 
        return cast(R) r; 
    }

    if (lhs.length != rhs.length) {
        return false;
    }

    if (lhs.length == 0 && rhs.length == 0) {
        return true;
    }

    static if (is(U1 == void) && is(U2 == void)) {
        return __equals(trustedCast!(ubyte[])(lhs), trustedCast!(ubyte[])(rhs));
    } else static if (is(U1 == void)) {
        return __equals(trustedCast!(ubyte[])(lhs), rhs);
    } else static if (is(U2 == void)) {
        return __equals(lhs, trustedCast!(ubyte[])(rhs));
    } else static if (!is(U1 == U2)) {
        foreach (const u; 0 .. lhs.length) {
            if (at(lhs, u) != at(rhs, u)) {
                return false;
            }
        }
        return true;
    } else static if (__traits(isIntegral, U1)) {
        foreach (const u; 0 .. lhs.length) {
            if (at(lhs, u) != at(rhs, u)) {
                return false;
            }
        }
        return true;
    } else {
        foreach (const u; 0 .. lhs.length) {
            static if (__traits(compiles, __equals(at(lhs, u), at(rhs, u)))) {
                if (!__equals(at(lhs, u), at(rhs, u))) {
                    return false;
                }
            } else static if (__traits(isFloating, U1)) {
                if (at(lhs, u) != at(rhs, u)) {
                    return false;
                }
            } else static if (is(U1 : Object) && is(U2 : Object)) {
                if (!(cast(Object)at(lhs, u) is cast(Object)at(rhs, u) || at(lhs, u) && (cast(Object)at(lhs, u)).opEquals(cast(Object)at(rhs, u)))) {
                    return false;
                }
            } else static if (__traits(hasMember, U1, "opEquals")) {
                if (!at(lhs, u).opEquals(at(rhs, u))) {
                    return false;
                }
            } else static if (is(U1 == delegate)) {
                if (at(lhs, u) != at(rhs, u)) {
                    return false;
                }
            } else static if (is(U1 == U11*, U11)) {
                if (at(lhs, u) != at(rhs, u)) {
                    return false;
                }
            } else static if (__traits(isAssociativeArray, U1)) {
                if (at(lhs, u) != at(rhs, u)) {
                    return false;
                }
            } else {
                if (at(lhs, u).tupleof != at(rhs, u).tupleof) {
                    return false;
                }
            }
        }

        return true;
    }
}

private inout(TypeInfo) getElement(inout TypeInfo value) @trusted pure nothrow {
    TypeInfo element = cast() value;
    for(;;) {
        if(auto qualified = cast(TypeInfo_Const) element) {
            element = qualified.base;
        } else if(auto redefined = cast(TypeInfo_Enum) element) {
            element = redefined.base;
        } else if(auto staticArray = cast(TypeInfo_StaticArray) element) {
            element = staticArray.value;
        } else if(auto vector = cast(TypeInfo_Vector) element) {
            element = vector.base;
        } else {
            break;
        }
    }
    return cast(inout) element;
}

private size_t getArrayHash(in TypeInfo element, in void* ptr, in size_t count) @trusted nothrow {
    if(!count) {
        return 0;
    }

    const size_t elementSize = element.tsize;
    if(!elementSize) {
        return 0;
    }

    static bool hasCustomToHash(in TypeInfo value) @trusted pure nothrow {
        const element = getElement(value);

        if(const struct_ = cast(const TypeInfo_Struct) element) {
            return !!struct_.xtoHash;
        }

        return cast(const TypeInfo_Array) element /*|| cast(const TypeInfo_AssociativeArray) element*/ || cast(const ClassInfo) element || cast(const TypeInfo_Interface) element;
    }

    if(!hasCustomToHash(element)) {
        return hashOf(ptr[0 .. elementSize * count]);
    }

    size_t hash = 0;
    foreach(size_t i; 0 .. count) {
        hash = hashOf(element.getHash(ptr + i * elementSize), hash);
    }
    return hash;
}
struct OffsetTypeInfo {
    size_t   offset;
    TypeInfo ti;
}

class TypeInfo {
    override string toString() const pure @safe nothrow {
        return typeid(this).name;
    }

    override size_t toHash() @trusted const nothrow {
        return hashOf(this.toString());
    }

    override int opCmp(Object o) {
        if (this is o) {
            return 0;
        }

        TypeInfo ti = cast(TypeInfo)o;

        if (ti is null) {
            return 1;
        }

        return strcmp(this.toString().ptr, ti.toString().ptr);
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }

        auto ti = cast(const TypeInfo)o;
        return ti && this.toString() == ti.toString();
    }

    size_t getHash(scope const void* p) @trusted nothrow const {
        return hashOf(p);
    }

    bool equals(in void* p1, in void* p2) const { 
        return p1 == p2; 
    }

    int compare(in void* p1, in void* p2) const { 
        return 0; // fixme
    }

    @property size_t tsize() nothrow pure const @safe @nogc { 
        return 0; 
    }

    void swap(void* p1, void* p2) const {
        immutable size_t n = tsize;
        for (size_t i = 0; i < n; i++) {
            byte t = (cast(byte *)p1)[i];
            (cast(byte*)p1)[i] = (cast(byte*)p2)[i];
            (cast(byte*)p2)[i] = t;
        }
    }

    @property inout(TypeInfo) next() nothrow pure inout @nogc { 
        return null; 
    }

    const(void)[] initializer() nothrow pure const @safe @nogc {
        return null;
    }

    @property uint flags() nothrow pure const @safe @nogc { 
        return 0; 
    }

    const(OffsetTypeInfo)[] offTi() const { 
        return null; 
    }

    void destroy(void* p) const {
    }

    void postblit(void* p) const {
    }


    @property size_t talign() nothrow pure const @safe @nogc { 
        return tsize; 
    }

    @property immutable(void)* rtInfo() nothrow pure const @safe @nogc { 
        return null; 
    }
    
    version (X86_64) {
        int argTypes(out TypeInfo arg1, out TypeInfo arg2) @safe nothrow {
            arg1 = this;
            return 0;
        }
    }
}

struct Interface {
    TypeInfo_Class classinfo;
    void*[]        vtbl;
    size_t         offset;
}

alias TypeInfo_Class ClassInfo;
class TypeInfo_Class : TypeInfo {
    override string toString() const { 
        return info.name; 
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_Class)o;
        return c && this.info.name == c.info.name;
    }

    override size_t getHash(scope const void* p) @trusted const {
        auto o = *cast(Object*)p;
        return o ? o.toHash() : 0;
    }

    override bool equals(in void* p1, in void* p2) const {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;

        return (o1 is o2) || (o1 && o1.opEquals(o2));
    }

    override int compare(in void* p1, in void* p2) const {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;
        int c = 0;

        if (o1 !is o2) {
            if (o1) {
                if (!o2) {
                    c = 1;
                } else {
                    c = o1.opCmp(o2);
                }
            } else {
                c = -1;
            }
        }
        return c;
    }

    override @property size_t tsize() nothrow pure const {
        return Object.sizeof;
    }

    override const(void)[] initializer() nothrow pure const @safe {
        return m_init;
    }

    override @property uint flags() nothrow pure const { 
        return 1; 
    }

    override @property const(OffsetTypeInfo)[] offTi() nothrow pure const {
        return m_offTi;
    }

    @property auto info() @safe nothrow pure const { 
        return this; 
    }

    @property auto typeinfo() @safe nothrow pure const { 
        return this; 
    }

    byte[]         m_init;
    string         name;
    void*[]        vtbl;
    Interface[]    interfaces;
    TypeInfo_Class base;
    void*          destructor;
    void function(Object) classInvariant;

    enum ClassFlags : uint {
        isCOMclass    = 1<<0,
        noPointers    = 1<<1,
        hasOffTi      = 1<<2,
        hasCtor       = 1<<3,
        hasGetMembers = 1<<4,
        hasTypeInfo   = 1<<5,
        isAbstract    = 1<<6,
        isCPPclass    = 1<<7,
        hasDtor       = 1<<8,
    }

    ClassFlags      m_flags;
    void*            deallocator;
    OffsetTypeInfo[] m_offTi;

    void function(Object) defaultConstructor;

    immutable(void)* m_RTInfo;
    override @property immutable(void)* rtInfo() const { 
        return m_RTInfo; 
    }

    static const(TypeInfo_Class) find(in char[] classname) {
        foreach (m; ModuleInfo) {
            if (m) {
                foreach (c; m.localClasses) {
                    if (c is null) {
                        continue;
                    }
                    if (c.name == classname) {
                        return c;
                    }
                }
            }
        }
        return null;
    }

    Object create() const {
        if (m_flags & 8 && !defaultConstructor) {
            return null;
        }
        if (m_flags & 64) {
            return null;
        }
//        Object o = _d_newclass(this);
//        if (m_flags & 8 && defaultConstructor) {
//            defaultConstructor(o);
//        }
//        return o;
        return null;
    }


}

class TypeInfo_Const : TypeInfo {
    override string toString() const {
        return cast(string) ("const(" ~ base.toString() ~ ")");
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }

        if (typeid(this) != typeid(o)) {
            return false;
        }

        auto t = cast(TypeInfo_Const)o;
        return base.opEquals(t.base);
    }

    override size_t getHash(scope const void *p) const { 
        return base.getHash(p); 
    }

    override bool equals(in void *p1, in void *p2) const { 
        return base.equals(p1, p2);
    }

    override int compare(in void *p1, in void *p2) const { 
        return base.compare(p1, p2); 
    }

    override @property size_t tsize() nothrow pure const { 
        return base.tsize; 
    }

    override void swap(void *p1, void *p2) const { 
        return base.swap(p1, p2); 
    }

    override @property inout(TypeInfo) next() nothrow pure inout { 
        return base.next; 
    }

    override @property uint flags() nothrow pure const { 
        return base.flags; 
    }

    override const(void)[] initializer() nothrow pure const {
        return base.initializer();
    }

    override @property size_t talign() nothrow pure const { 
        return base.talign; 
    }

    TypeInfo base;

    version (X86_64) {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
            return base.argTypes(arg1, arg2);
        }
    }
}

class TypeInfo_Interface : TypeInfo {
    override string toString() const { 
        return info.name; 
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_Interface)o;
        return c && this.info.name == typeid(c).name;
    }

    override size_t getHash(scope const void* p) @trusted const {
        if (!*cast(void**)p) {
            return 0;
        }
        Interface* pi = **cast(Interface ***)*cast(void**)p;
        Object o = cast(Object)(*cast(void**)p - pi.offset);
        //assert(o);
        return o.toHash();
    }

    override bool equals(in void* p1, in void* p2) const {
        Interface* pi = **cast(Interface ***)*cast(void**)p1;
        Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
        pi = **cast(Interface ***)*cast(void**)p2;
        Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);

        return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
    }

    override int compare(in void* p1, in void* p2) const {
        Interface* pi = **cast(Interface ***)*cast(void**)p1;
        Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
        pi = **cast(Interface ***)*cast(void**)p2;
        Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);
        int c = 0;

        if (o1 != o2) {
            if (o1) {
                if (!o2) {
                    c = 1;
                } else {
                    c = o1.opCmp(o2);
                }
            } else {
                c = -1;
            }
        }
        return c;
    }

    override @property size_t tsize() nothrow pure const {
        return Object.sizeof;
    }

    override const(void)[] initializer() const @trusted {
        return (cast(void *)null)[0 .. Object.sizeof];
    }

    override @property uint flags() nothrow pure const { 
        return 1; 
    }

    TypeInfo_Class info;
}

class TypeInfo_Struct : TypeInfo {
    override string toString() const { 
        return name; 
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }

        auto s = cast(const TypeInfo_Struct)o;
        return s && this.name == s.name && this.initializer().length == s.initializer().length;
    }

    override size_t getHash(scope const void* p) @trusted pure nothrow const {
        if (xtoHash) {
            return (*xtoHash)(p);
        } else {
            return hashOf(p[0 .. initializer().length]);
        }
    }

    override bool equals(in void* p1, in void* p2) @trusted pure nothrow const {
        if (!p1 || !p2) {
            return false;
        } else if (xopEquals) {
            return (*xopEquals)(p1, p2);
        } else if (p1 == p2) {
            return true;
        } else {
            return memcmp(p1, p2, initializer().length) == 0;
        }
    }

    override int compare(in void* p1, in void* p2) @trusted pure nothrow const {
        if (p1 != p2) {
            if (p1) {
                if (!p2) {
                    return true;
                } else if (xopCmp) {
                    return (*xopCmp)(p2, p1);
                } else {
                    return memcmp(p1, p2, initializer().length);
                }
            } else {
                return -1;
            }
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure const {
        return initializer().length;
    }

    override const(void)[] initializer() nothrow pure const @safe {
        return m_init;
    }

    override @property uint flags() nothrow pure const { 
        return m_flags; 
    }

    override @property size_t talign() nothrow pure const { 
        return m_align;
    }

    final override void destroy(void* p) const {
        if (xdtor) {
            if (m_flags & StructFlags.isDynamicType) {
                (*xdtorti)(p, this);
            } else {
                (*xdtor)(p);
            }
        }
    }

    override void postblit(void* p) const {
        if (xpostblit) {
            (*xpostblit)(p); 
        }
    }

    string name;
    void[] m_init;
  
    @safe pure nothrow {
        size_t   function(in void*)           xtoHash;
        bool     function(in void*, in void*) xopEquals;
        int      function(in void*, in void*) xopCmp;
        string   function(in void*)           xtoString;

        enum StructFlags : uint {
            hasPointers   = 1<<0,
            isDynamicType = 1<<1,
        }
        StructFlags m_flags;
    }
    union {
        void function(void*)                           xdtor;
        void function(void*, const TypeInfo_Struct ti) xdtorti;
    }
    void function(void*)                    xpostblit;

    uint m_align;

    override @property immutable(void)* rtInfo() const { 
        return m_RTInfo; 
    }
    
    version (X86_64) {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
            arg1 = m_arg1;
            arg2 = m_arg2;
            return 0;
        }

        TypeInfo m_arg1;
        TypeInfo m_arg2;
    }
    
    immutable(void)* m_RTInfo;
}

class TypeInfo_Pointer : TypeInfo {
    override string toString() const { 
        return m_next.toString() ~ "*";
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_Pointer)o;
        return c && this.m_next == c.m_next;
    }

    override size_t getHash(scope const void* p) @trusted const {
        size_t addr = cast(size_t) *cast(const void**)p;
        return addr ^ (addr >> 4);
    }

    override bool equals(in void* p1, in void* p2) const {
        return *cast(void**)p1 == *cast(void**)p2;
    }

    override int compare(in void* p1, in void* p2) const {
        if (*cast(void**)p1 < *cast(void**)p2) {
            return -1;
        } else if (*cast(void**)p1 > *cast(void**)p2) {
            return 1;
        } else {
            return 0;
        }
    }

    override @property size_t tsize() nothrow pure const {
        return (void*).sizeof;
    }

    override const(void)[] initializer() const @trusted {
        return (cast(void *)null)[0 .. (void*).sizeof];
    }

    override void swap(void* p1, void* p2) const {
        void* tmp = *cast(void**)p1;
        *cast(void**)p1 = *cast(void**)p2;
        *cast(void**)p2 = tmp;
    }

    override @property inout(TypeInfo) next() nothrow pure inout { 
        return m_next;
    }

    override @property uint flags() nothrow pure const { 
        return 1; 
    }

    TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo {
    override string toString() const { 
        return value.toString() ~ "[]";
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_Array)o;
        return c && this.value == c.value;
    }

    override size_t getHash(scope const void* p) @trusted const {
        void[] a = *cast(void[]*)p;
        return getArrayHash(value, a.ptr, a.length);
    }

    override bool equals(in void* p1, in void* p2) const {
        void[] a1 = *cast(void[]*)p1;
        void[] a2 = *cast(void[]*)p2;
        if (a1.length != a2.length) {
            return false;
        }
        size_t sz = value.tsize;
        for (size_t i = 0; i < a1.length; i++) {
            if (!value.equals(a1.ptr + i * sz, a2.ptr + i * sz)) {
                return false;
            }
        }
        return true;
    }

    override int compare(in void* p1, in void* p2) const {
        void[] a1 = *cast(void[]*)p1;
        void[] a2 = *cast(void[]*)p2;
        size_t sz = value.tsize;
        size_t len = a1.length;

        if (a2.length < len) {
            len = a2.length;
        }
        for (size_t u = 0; u < len; u++) {
            immutable int result = value.compare(a1.ptr + u * sz, a2.ptr + u * sz);
            if (result) {
                return result;
            }
        }
        return cast(int)a1.length - cast(int)a2.length;
    }

    override @property size_t tsize() nothrow pure const {
        return (void[]).sizeof;
    }

    override const(void)[] initializer() const @trusted {
        return (cast(void *)null)[0 .. (void[]).sizeof];
    }

    override void swap(void* p1, void* p2) const {
        void[] tmp = *cast(void[]*)p1;
        *cast(void[]*)p1 = *cast(void[]*)p2;
        *cast(void[]*)p2 = tmp;
    }

    TypeInfo value;

    override @property inout(TypeInfo) next() nothrow pure inout {
        return value;
    }

    override @property uint flags() nothrow pure const { 
        return 1; 
    }

    override @property size_t talign() nothrow pure const {
        return (void[]).alignof;
    }

    version (X86_64) {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
            arg1 = typeid(size_t);
            arg2 = typeid(void*);
            return 0;
        }
    }
}

class TypeInfo_Enum : TypeInfo {
    override string toString() const { 
        return name; 
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_Enum)o;
        return c && this.name == c.name && this.base == c.base;
    }

    override size_t getHash(scope const void* p) const { 
        return base.getHash(p);
    }

    override bool equals(in void* p1, in void* p2) const { 
        return base.equals(p1, p2); 
    }

    override int compare(in void* p1, in void* p2) const { 
        return base.compare(p1, p2);
    }

    override @property size_t tsize() nothrow pure const { 
        return base.tsize; 
    }

    override void swap(void* p1, void* p2) const { 
        return base.swap(p1, p2); 
    }

    override @property inout(TypeInfo) next() nothrow pure inout { 
        return base.next; 
    }

    override @property uint flags() nothrow pure const { 
        return base.flags; 
    }

    override const(void)[] initializer() const {
        return m_init.length ? m_init : base.initializer();
    }

    override @property size_t talign() nothrow pure const { 
        return base.talign; 
    }

    version (X86_64) {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
            return base.argTypes(arg1, arg2);
        }
    }

    override @property immutable(void)* rtInfo() const { 
        return base.rtInfo; 
    }

    TypeInfo base;
    string   name;
    void[]   m_init;
}

class TypeInfo_StaticArray : TypeInfo {
    override string toString() const {
        char[20] tmpBuff = void;
        return value.toString() ~ "[" ~ unsignedToTempString(len, tmpBuff, 10) ~ "]";
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_StaticArray)o;
        return c && this.len == c.len && this.value == c.value;
    }

    override size_t getHash(scope const void* p) @trusted const {
        return getArrayHash(value, p, len);
    }

    override bool equals(in void* p1, in void* p2) const {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++) {
            if (!value.equals(p1 + u * sz, p2 + u * sz)) {
                return false;
            }
        }
        return true;
    }

    override int compare(in void* p1, in void* p2) const {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++) {
            immutable int result = value.compare(p1 + u * sz, p2 + u * sz);
            if (result) {
                return result;
            }
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure const {
        return len * value.tsize;
    }

    override void swap(void* p1, void* p2) const {
        void* tmp;
        size_t sz = value.tsize;
        ubyte[16] buffer;
        void* pbuffer;

        if (sz < buffer.sizeof) {
            tmp = buffer.ptr;
        } else {
            tmp = pbuffer = (new void[sz]).ptr;
        }

        for (size_t u = 0; u < len; u += sz) {
            size_t o = u * sz;
            memcpy(tmp, p1 + o, sz);
            memcpy(p1 + o, p2 + o, sz);
            memcpy(p2 + o, tmp, sz);
        }

//        if (pbuffer)
  //          GC.free(pbuffer);
    }

    override const(void)[] initializer() nothrow pure const {
        return value.initializer();
    }

    override @property inout(TypeInfo) next() nothrow pure inout { 
        return value; 
    }

    override @property uint flags() nothrow pure const { 
        return value.flags; 
    }

    override void destroy(void* p) const {
        immutable sz = value.tsize;
        p += sz * len;
        foreach (i; 0 .. len) {
            p -= sz;
            value.destroy(p);
        }
    }

    override void postblit(void* p) const {
        immutable sz = value.tsize;
        foreach (i; 0 .. len) {
            value.postblit(p);
            p += sz;
        }
    }

    TypeInfo value;
    size_t   len;

    override @property size_t talign() nothrow pure const {
        return value.talign;
    }

    version (X86_64) {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
            arg1 = typeid(void*);
            return 0;
        }
    }
}

class TypeInfo_Vector : TypeInfo {
    override string toString() const { 
        return "__vector(" ~ base.toString() ~ ")"; 
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_Vector)o;
        return c && this.base == c.base;
    }

    override size_t getHash(scope const void* p) const { 
        return base.getHash(p); 
    }

    override bool equals(in void* p1, in void* p2) const { 
        return base.equals(p1, p2); 
    }

    override int compare(in void* p1, in void* p2) const { 
        return base.compare(p1, p2); 
    }

    override @property size_t tsize() nothrow pure const { 
        return base.tsize; 
    }

    override void swap(void* p1, void* p2) const { 
        return base.swap(p1, p2); 
    }

    override @property inout(TypeInfo) next() nothrow pure inout { 
        return base.next; 
    }

    override @property uint flags() nothrow pure const { 
        return base.flags; 
    }

    override const(void)[] initializer() nothrow pure const {
        return base.initializer();
    }

    override @property size_t talign() nothrow pure const { 
        return 16; 
    }

    version (X86_64) {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
            return base.argTypes(arg1, arg2);
        }
    }

    TypeInfo base;
}

class TypeInfo_Invariant : TypeInfo_Const {
    override string toString() const {
        return cast(string) ("immutable(" ~ base.toString() ~ ")");
    }
}

class TypeInfo_Shared : TypeInfo_Const {
    override string toString() const {
        return cast(string) ("shared(" ~ base.toString() ~ ")");
    }
}

class TypeInfo_Inout : TypeInfo_Const {
    override string toString() const {
        return cast(string) ("inout(" ~ base.toString() ~ ")");
    }
}


/*
class TypeInfo_AssociativeArray : TypeInfo {
    override string toString() const {
        return value.toString() ~ "[" ~ key.toString() ~ "]";
    }

    override bool opEquals(Object o) {
        if (this is o) {
            return true;
        }
        auto c = cast(const TypeInfo_AssociativeArray)o;
        return c && this.key == c.key && this.value == c.value;
    }

    override bool equals(in void* p1, in void* p2) @trusted const {
        return !!_aaEqual(this, *cast(const void**) p1, *cast(const void**) p2);
    }

    override hash_t getHash(scope const void* p) nothrow @trusted const {
        return _aaGetHash(cast(void*)p, this);
    }

    override @property size_t tsize() nothrow pure const {
        return (char[int]).sizeof;
    }

    override const(void)[] initializer() const @trusted {
        return (cast(void *)null)[0 .. (char[int]).sizeof];
    }

    override @property inout(TypeInfo) next() nothrow pure inout { 
        return value; 
    }

    override @property uint flags() nothrow pure const { 
        return 1; 
    }

    TypeInfo value;
    TypeInfo key;

    override @property size_t talign() nothrow pure const {
        return (char[int]).alignof;
    }

    version (X86_64) {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2) {
            arg1 = typeid(void*);
            return 0;
        }
    }
}
*/

enum {
    MIctorstart       = 1<<0,
    MIctordone        = 1<<1,
    MIstandalone      = 1<<2,
    MItlsctor         = 1<<3,
    MItlsdtor         = 1<<4,
    MIctor            = 1<<5,
    MIdtor            = 1<<6,
    MIxgetMembers     = 1<<7,
    MIictor           = 1<<8,
    MIunitTest        = 1<<9,
    MIimportedModules = 1<<10,
    MIlocalClasses    = 1<<11,
    MIname            = 1<<12,
}

struct ModuleInfo {
    uint _flags;
    uint _index;

    deprecated("ModuleInfo cannot be copy-assigned because it is a variable-sized struct.")
        void opAssign(in ModuleInfo m) {
            _flags = m._flags;
            _index = m._index; 
        }

nothrow:
pure:
    @nogc:
        const:
        private void* addrOf(int flag) in {
            //        assert(flag >= MItlsctor && flag <= MIname);
            //        assert(!(flag & (flag - 1)) && !(flag & ~(flag - 1) << 1));
        } do {
            void* p = cast(void*)&this + ModuleInfo.sizeof;

            if (flags & MItlsctor) {
                if (flag == MItlsctor) return p;
                p += typeof(tlsctor).sizeof;
            }

            if (flags & MItlsdtor) {
                if (flag == MItlsdtor) return p;
                p += typeof(tlsdtor).sizeof;
            }

            if (flags & MIctor) {
                if (flag == MIctor) return p;
                p += typeof(ctor).sizeof;
            }

            if (flags & MIdtor) {
                if (flag == MIdtor) return p;
                p += typeof(dtor).sizeof;
            }

            if (flags & MIxgetMembers) {
                if (flag == MIxgetMembers) return p;
                p += typeof(xgetMembers).sizeof;
            }

            if (flags & MIictor) {
                if (flag == MIictor) return p;
            p += typeof(ictor).sizeof;
        }

        if (flags & MIunitTest) {
            if (flag == MIunitTest) return p;
            p += typeof(unitTest).sizeof;
        }

        if (flags & MIimportedModules) {
            if (flag == MIimportedModules) return p;
            p += size_t.sizeof + *cast(size_t*)p * typeof(importedModules[0]).sizeof;
        }

        if (flags & MIlocalClasses) {
            if (flag == MIlocalClasses) return p;
            p += size_t.sizeof + *cast(size_t*)p * typeof(localClasses[0]).sizeof;
        }

        if (true || flags & MIname) {
            if (flag == MIname) return p;
            p += strlen(cast(immutable char*)p);
        }
        return null;
//        assert(0);
    }

    @property uint index() { 
        return _index; 
    }

    @property uint flags() { 
        return _flags; 
    }

    @property void function() tlsctor() {
        return flags & MItlsctor ? *cast(typeof(return)*)addrOf(MItlsctor) : null;
    }

    @property void function() tlsdtor() {
        return flags & MItlsdtor ? *cast(typeof(return)*)addrOf(MItlsdtor) : null;
    }

    @property void* xgetMembers() {
        return flags & MIxgetMembers ? *cast(typeof(return)*)addrOf(MIxgetMembers) : null;
    }

    @property void function() ctor() {
        return flags & MIctor ? *cast(typeof(return)*)addrOf(MIctor) : null;
    }

    @property void function() dtor() {
        return flags & MIdtor ? *cast(typeof(return)*)addrOf(MIdtor) : null;
    }

    @property void function() ictor() {
        return flags & MIictor ? *cast(typeof(return)*)addrOf(MIictor) : null;
    }

    @property void function() unitTest() {
        return flags & MIunitTest ? *cast(typeof(return)*)addrOf(MIunitTest) : null;
    }

    @property immutable(ModuleInfo*)[] importedModules() {
        if (flags & MIimportedModules) {
            auto p = cast(size_t*)addrOf(MIimportedModules);
            return (cast(immutable(ModuleInfo*)*)(p + 1))[0 .. *p];
        }
        return null;
    }

    @property TypeInfo_Class[] localClasses() {
        if (flags & MIlocalClasses) {
            auto p = cast(size_t*)addrOf(MIlocalClasses);
            return (cast(TypeInfo_Class*)(p + 1))[0 .. *p];
        }
        return null;
    }


    @property string name() {
        if (true || flags & MIname) {
            auto p = cast(immutable char*)addrOf(MIname);
            return p[0 .. strlen(p)];
        }
    }

    static int opApply(scope int delegate(ModuleInfo*) dg) {
        return 0;//moduleinfos_apply((immutable(ModuleInfo*)m) => dg(cast(ModuleInfo*)m));
    }

}

unittest {
}
