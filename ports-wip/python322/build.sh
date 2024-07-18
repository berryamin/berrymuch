#!/usr/bin/env bash

# This code Copyright 2012 Todd Mortimer <todd.mortimer@gmail.com>
#
# You may do whatever you like with this code, provided the above
# copyright notice and this paragraph are preserved.


set -e
source ../../lib.sh

DISTVER="Python"
#GITTAG="v1.43"
DISTSUFFIX="git"
DISTFILES="https://github.com/BerryFarm/$DISTVER.$DISTSUFFIX"

TASK=fetch
package_init "$@"
CONFIGURE_CMD=" ./configure 
                --host=$PBHOSTARCH
                --build=$PBBUILDARCH 
                --target=$PBTARGETARCH 
                --prefix=$PREFIX 
                CC=$PBTARGETARCH-gcc
                "

clean()
{
	SEARCHDIRS="Doc Grammar Include Lib Mac Misc Modules Objects Parser PC Python Tools"
	find ${SEARCHDIRS} -name '*.[oa]' -delete
	find ${SEARCHDIRS} -name '*.s[ol]' -delete
	find ${SEARCHDIRS} -name '*.so.[0-9]*.[0-9]*' -delete
	find ${SEARCHDIRS} -name '*.gc??' -delete
	#find ${SEARCHDIRS} -name '__pycache__' -exec rm -rf {} \;
	rm -f Lib/lib2to3/*Grammar*.pickle
	rm -f python Parser/pgen libpython*.so* libpython*.a \
	      tags TAGS Parser/pgen.stamp \
	      config.cache config.log pyconfig.h Modules/config.c
	rm -rf build platform
	rm -rf Lib/test/data
	rm -f core Makefile Makefile.pre config.status \
	      Modules/Setup Modules/Setup.local Modules/Setup.config \
	      Modules/ld_so_aix Modules/python.exp Misc/python.pc
	rm -f python*-gdb.py
	rm -f pybuilddir.txt
}

if [ "$TASK" == "fetch" ]
then
  cd "$WORKROOT"
  # delete old version
  #rm -rf "$DISTVER"
  git clone $DISTFILES $DISTVER
  cd $DISTVER
  #git checkout $GITTAG
  TASK=patch
fi

package_patch 1

if [ "$TASK" == "patch" ]
then
  echo "Patching"
  cd "$WORKDIR"
 
  for apatch in $EXECDIR/post-conf-patches/*
   do
        patch -p0 < $apatch
   done

  TASK=build
fi

if [ "$TASK" == "build" ]
then
  echo "Building"
  cd "$WORKDIR"
  mv Python-3/* .
  rm -rf Python-3/

  for TARGET in host nto-x86 nto-armv7; do
  echo "************************************************************************"
  echo " Building for ${TARGET}..."
  echo "************************************************************************"
        clean
        ./${TARGET}.build
        if [ $? != 0 ]; then
                echo "Build failed!"
                break
        fi
  done

  TASK=install
fi


package_install


if [ "$TASK" == "bundle" ]
then
	echo "Zipping and copying to packages"
	echo $ROOTDIR
	cd $WORKROOT/$DISTVER/nto-armv7/accounts/1000/shared/misc/clitools
	zip -yr $DISTVER.zip .
	mv $DISTVER.zip $ROOTDIR/packages

	echo "Moving to archive"
	mv $WORKROOT/$DISTVER/nto-armv7/accounts $ROOTDIR/archive/

	echo "Moving host to $ROOTDIR/host for future builds"
	mv $WORKROOT/$DISTVER/host $ROOTDIR/
fi
package_bundle
