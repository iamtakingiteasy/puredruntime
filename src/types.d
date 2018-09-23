module types;

version(D_LP64) {
    alias size_t = ulong;
    alias ptrdiff_t = long;
} else {
    alias size_t = uint;
    alias ptrdiff_t = int;
}
alias sizediff_t = ptrdiff_t;
alias hash_t = size_t;
alias equals_t = bool;
alias string  = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];
