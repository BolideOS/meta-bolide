# Fix mesa-native build with newer glibc (2.41+) where system <threads.h>
# is included via <stdlib.h>, causing conflicting types for once_flag/call_once
# with mesa's src/c11/threads.h.
# 1) Add -DHAVE_THRD_CREATE so mesa's threads.h defers to system <threads.h>
#    (eliminates conflicting type definitions for once_flag, call_once, etc.)
# 2) Remove -Werror=incompatible-pointer-types because mesa's posix shim and
#    EGL code pass C11 thread types to pthread functions. The types are ABI-
#    compatible (glibc C11 threads wrap pthread) so this is safe for native tools.
do_configure:prepend:class-native() {
    sed -i "s/^with_c11_threads = false/with_c11_threads = false\npre_args += ['-DHAVE_THRD_CREATE', '-Wno-error=incompatible-pointer-types']/" ${S}/meson.build
    sed -i "s/'-Werror=incompatible-pointer-types',//" ${S}/meson.build
}
