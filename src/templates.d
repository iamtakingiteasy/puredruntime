module templates;

import types;

char[] unsignedToTempString()(ulong value, return scope char[] buf, uint radix = 10) @safe {
    if (radix < 2) {
        return buf[$ .. $];
    }

    size_t i = buf.length;
    do {
        if (value < radix) {
            ubyte x = cast(ubyte)value;
            buf[--i] = cast(char)((x < 10) ? x + '0' : x - 10 + 'a');
            break;
        } else {
            ubyte x = cast(ubyte)(value % radix);
            value = value / radix;
            buf[--i] = cast(char)((x < 10) ? x + '0' : x - 10 + 'a');
        }
    } while (value);
    return buf[i .. $];
}
