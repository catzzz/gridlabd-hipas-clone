#!/bin/bash

function error()
{
	echo "ERROR: $*" > /dev/stderr
	exit 1
}

# check
if [ -d /usr/local/gridlabd -a ! -L /usr/local/gridlabd ]; then
    error "/usr/local/gridlabd is not a symbolic link"
fi
if [ $(whoami) == "root" ]; then
    error "do not run $0 as root"
fi
if [ -z "$(which doxygen)" ]; then
	error "doxygen is not installed"
fi
if [ -z "$(which mono)" ]; then
	error "mono is not installed"
fi
if [ -z "$(which natural_docs)" ]; then
	error "natural_docs is not installed"
fi

# autoconf
if [ ! "$1" == "quick" ]; then
    autoscan
fi
if [ ! -d autom4te.cache -o ! "$1" == "quick" ]; then
    autoreconf -isf
fi

# prep install dir
VERSION=`build-aux/version.sh --install`
INSTALL=/usr/local/$VERSION
sudo rm -rf $INSTALL || exit 1
sudo mkdir -p $INSTALL
sudo /usr/sbin/chown -R $USER $INSTALL
if [ ! -f configure -o ! "$1" == "quick" ]; then
    ./configure --prefix=$INSTALL $*
fi

# build everything
export PATH=$INSTALL/bin:/usr/local/bin:/usr/bin:/bin
make -j30
make install
make html 
cp -r documents/html $INSTALL
cp documents/index.html $INSTALL/html
#make index
#gridlabd --validate

# activate this version
if [ -x $INSTALL/bin/gridlabd-version ]; then
	gridlabd version set $VERSION
else
	sudo rm -f /usr/local/gridlabd
	sudo ln -s $INSTALL /usr/local/gridlabd
	if [ ! -f /usr/local/bin/gridlabd ]; then
		sudo ln -s /usr/local/gridlabd/bin/gridlabd /usr/local/bin/gridlabd
	fi
fi