TERMUX_PKG_HOMEPAGE="https://dicom.offis.de/dcmtk"
TERMUX_PKG_DESCRIPTION="A collection of libraries and applications implementing large parts the DICOM standard"
TERMUX_PKG_GROUPS="science"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_LICENSE_FILE="COPYRIGHT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.7.0"
TERMUX_PKG_SRCURL="https://github.com/DCMTK/dcmtk/archive/refs/tags/DCMTK-$TERMUX_PKG_VERSION.tar.gz"
TERMUX_PKG_SHA256=5bb3ec8317dc465788bed2ca789e76d03ae5848c9381cce3b14c1a3f8b6aca56
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="libc++, libpng, libtiff, libxml2, openssl, zlib"
# As of 3.6.9, libsndfile and openjpeg are detected but not linked against
TERMUX_PKG_BUILD_DEPENDS="libsndfile, openjpeg, openjpeg-tools"
TERMUX_PKG_BUILD_IN_SRC=true
# TODO: Verify the below
#   - DCMTK_FIXED_ICONV_CONVERSION_FLAGS: The output printed by the test program
#    config/tests/iconv.cc, when run on the target platform. This value is only
#    used when compiling with old libiconv versions (older than libiconv 1.8)
#    and determines the iconv behaviour when encountering illegal byte sequences
#    during a character set conversion. Possible values are:
#    - "AbortTranscodingOnIllegalSequence" (use as default)
#    - "DiscardIllegalSequences"
#  - DCMTK_STDLIBC_ICONV_HAS_DEFAULT_ENCODING: true if the test program
#    config/tests/lciconv.cc exits with a return code of zero, false otherwise.
#    This test determines if libiconv has a default encoding, i.e. if
#    iconv_open() accepts "" as an argument. Use FALSE as default.
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DDCMTK_NO_TRY_RUN=ON
-DDCMTK_ICONV_FLAGS_ANALYZED=ON
-DDCMTK_FIXED_ICONV_CONVERSION_FLAGS=DiscardIllegalSequences
-DDCMTK_STDLIBC_ICONV_HAS_DEFAULT_ENCODING=TRUE
-DBUILD_SHARED_LIBS=ON
-DDCMTK_WITH_ICONV=ON
-DDCMTK_WITH_ICU=OFF
-DDCMTK_WITH_XML=ON
-DDCMTK_WITH_PNG=ON
-DDCMTK_WITH_OPENJPEG=ON
-DDCMTK_WITH_OPENSSL=ON
-DDCMTK_WITH_SNDFILE=ON
-DDCMTK_WITH_TIFF=ON
-DDCMTK_WITH_ZLIB=ON
-DANDROID_TEMPORARY_FILES_LOCATION=$TERMUX_PREFIX/tmp
"

termux_step_pre_configure() {
	cp "$TERMUX_PKG_BUILDER_DIR/arith.h/$TERMUX_ARCH.h" "$TERMUX_PKG_SRCDIR/config/include/dcmtk/config/arith.h"
}
