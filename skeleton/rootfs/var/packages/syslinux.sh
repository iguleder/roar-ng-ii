#!/bin/sh

PKG_NAME="syslinux"
PKG_VER="4.05"
PKG_REV="2"
PKG_DESC="Lightweight boot loaders"
PKG_CAT="BuildingBlock"
PKG_DEPS=""

# the package source files
PKG_SRC="http://www.kernel.org/pub/linux/utils/boot/syslinux/$PKG_NAME-$PKG_VER.tar.xz"

download() {
	[ -f handle-ctors-dtors-via-init_array-and-fini_array.patch ] && return 0

	# download a required patch: the boot loader fails when built with GCC 4.7
	download_file \
	https://projects.archlinux.org/svntogit/packages.git/plain/trunk/handle-ctors-dtors-via-init_array-and-fini_array.patch?h=packages/syslinux \
	handle-ctors-dtors-via-init_array-and-fini_array.patch
	[ 0 -ne $? ] && return 1

	return 0
}

build() {
	# extract the sources tarball
	extract_tarball $PKG_NAME-$PKG_VER.tar.xz
	[ 0 -ne $? ] && return 1

	cd $PKG_NAME-$PKG_VER

	# patch the sources
	patch -p1 < ../handle-ctors-dtors-via-init_array-and-fini_array.patch
	[ 0 -ne $? ] && return 1

	# do not build the DOS and Windows tools - it will fail
	sed -i s/'dos win32 win64 dosutil'// Makefile
	[ 0 -ne $? ] && return 1

	# change the installation paths
	sed -e s~'^SBINDIR.*=.*'~"SBINDIR = /$SBIN_DIR"~ \
	    -e s~'^LIBDIR.*=.*'~"LIBDIR = /$LIB_DIR"~ \
	    -e s~'^AUXDIR.*=.*'~"AUXDIR = /$LIB_DIR/syslinux"~ \
	    -e s~'^MANDIR.*=.*'~"MANDIR = /$MAN_DIR"~ \
	    -i mk/syslinux.mk
	[ 0 -ne $? ] && return 1

	# set the compiler flags
	sed -i s~'^OPTFLAGS.*=.*'~"OPTFLAGS = $CFLAGS"~ mk/build.mk
	[ 0 -ne $? ] && return 1

	# build the package; do not set LDFLAGS, since the package has its own
	# and it's quite sensitive
	LDFLAGS="" make -j $BUILD_THREADS
	[ 0 -ne $? ] && return 1

	return 0
}

package() {
	# install the package
	make INSTALLROOT=$INSTALL_DIR install
	[ 0 -ne $? ] && return 1

	return 0
}
