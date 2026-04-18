# Fix mesa-native build with newer glibc (conflicting types for call_once
# between mesa's src/c11/threads.h and system threads.h)
EXTRA_OEMESON:append:class-native = " -Dc11-threads=disabled"
