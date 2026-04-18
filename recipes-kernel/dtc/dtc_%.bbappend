# Fix dtc build failure with newer GCC (-Werror=discarded-qualifiers)
EXTRA_OEMESON:append = " -Dwerror=false"
