# Fix virglrenderer-native build with newer glibc (2.41+) where system <threads.h>
# is included via <stdlib.h>, causing conflicting types for once_flag/call_once
# with virglrenderer's bundled C11 threads emulation.
# Replace the bundled shim with a thin wrapper that uses system C11 threads.
do_configure:prepend:class-native() {
    cat > ${S}/src/mesa/compat/c11/threads.h << 'EOF'
#ifndef EMULATED_THREADS_H_INCLUDED_
#define EMULATED_THREADS_H_INCLUDED_
#include <threads.h>
#include <pthread.h>
#endif
EOF
    : > ${S}/src/mesa/compat/c11/threads_posix.h
}
