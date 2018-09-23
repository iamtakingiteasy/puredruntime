module traits;

template Unqual(T) {
    static if (is(T U ==                 immutable U)) {
        alias Unqual = U;
    } else static if (is(T U == shared inout const U)) {
        alias Unqual = U;
    } else static if (is(T U == shared inout       U)) {
        alias Unqual = U;
    } else static if (is(T U == shared       const U)) {
        alias Unqual = U;
    } else static if (is(T U == shared             U)) {
        alias Unqual = U;
    } else static if (is(T U ==        inout const U)) {
        alias Unqual = U;
    } else static if (is(T U ==        inout       U)) {
        alias Unqual = U;
    } else static if (is(T U ==              const U)) {
        alias Unqual = U;
    } else {
        alias Unqual = T;
    }
}
