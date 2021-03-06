PKG_NAME="dropbear"
PKG_VER="2013.58"
PKG_REV="1"
PKG_DESC="SSH2 server and client"
PKG_CAT="Administration"
PKG_DEPS="zlib"
PKG_LICENSE="custom"

# the package source files
PKG_SRC="http://matt.ucc.asn.au/dropbear/releases/$PKG_NAME-$PKG_VER.tar.bz2"

# the programs to build
PROGRAMS="dropbear dbclient dropbearkey scp"

build() {
	# extract the sources
	extract_tarball $PKG_NAME-$PKG_VER.tar.bz2
	[ 0 -ne $? ] && return 1

	cd $PKG_NAME-$PKG_VER

	# configure the package
	./configure $AUTOTOOLS_BASE_OPTS \
	            --enable-zlib \
	            --disable-pam \
	            --enable-openpty \
	            --enable-syslog \
	            --enable-shadow \
	            --enable-bundled-libtom \
	            --enable-lastlog \
	            --enable-utmp \
	            --enable-utmpx \
	            --enable-wtmp \
	            --enable-wtmpx \
	            --enable-loginfunc \
	            --disable-pututline \
	            --disable-pututxline \
	            --with-zlib \
	            --without-pam \
	            --with-lastlog=/$LOG_DIR/lastlog
	[ 0 -ne $? ] && return 1

	# set the xauth path
	sed -i s~'/usr/bin/X11/xauth'~"$(which xauth)"~ options.h
	[ 0 -ne $? ] && return 1

	# set the key paths
	sed -i s~/etc/dropbear~"/$CONF_DIR/dropbear"~g options.h
	[ 0 -ne $? ] && return 1

	# change Dropbear's banner, so it doesn't contain the SSH server name and
	# version
	sed -i s~'^#define LOCAL_IDENT .*'~'#define LOCAL_IDENT "SSH-2.0-None"'~ \
	       sysoptions.h
	[ 0 -ne $? ] && return 1

	# build the package
	make -j $BUILD_THREADS PROGRAMS="$PROGRAMS" MULTI=1
	[ 0 -ne $? ] && return 1

	return 0
}

package() {
	# install the multi-call binary
	install -D -m 755 dropbearmulti $INSTALL_DIR/$BIN_DIR/dropbear
	[ 0 -ne $? ] && return 1

	# add the configuration directory
	mkdir -p $INSTALL_DIR/$CONF_DIR/dropbear
	[ 0 -ne $? ] && return 1

	# create symlinks to the multi-call binary
	for i in $PROGRAMS ssh
	do
		[ "dropbear" = "$i" ] && continue
		ln -s dropbear $INSTALL_DIR/$BIN_DIR/$i
		[ 0 -ne $? ] && return 1
	done

	# install the man pages
	install -D -m 644 dropbear.8 $INSTALL_DIR/$MAN_DIR/man8/dropbear.8
	[ 0 -ne $? ] && return 1
	install -D -m 644 dbclient.1 $INSTALL_DIR/$MAN_DIR/man1/dbclient.1
	[ 0 -ne $? ] && return 1
	install -D -m 644 dropbearkey.8 $INSTALL_DIR/$MAN_DIR/man8/dropbearkey.8
	[ 0 -ne $? ] && return 1

	# install the license
	install -D -m 644 LICENSE $INSTALL_DIR/$LEGAL_DIR/$PKG_NAME/LICENSE
	[ 0 -ne $? ] && return 1

	return 0
}