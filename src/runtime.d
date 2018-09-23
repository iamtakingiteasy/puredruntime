module runtime;

import object;
import types;
import moduleref;

extern(C):
nothrow:
@nogc:

alias extern(C) int function(char[][] args) MainFunc;


extern (C) int printf(const char *fmt, ...);

void runModuleUnitTests() {
    ModuleInfo m;
    printf("abc\n".ptr);
 //   foreach (m; ModuleInfo) {
 //   }
}

int _d_run_main(int argc, char **argv, void *mainRaw) {
    MainFunc mainFunc = cast(MainFunc)mainRaw;
    char[][] args;
    int result = 1;
    runModuleUnitTests();
    result = mainFunc(args);
    return 5;
}

