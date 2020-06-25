#!/bin/bash -

fatal() {
  echo >&2 "$*"
  exit 1
}

here=$(pwd -P)

if [[ $here =~ ^(.*/jdk[0-9]+)(/|$) ]] ; then
  jdk=${BASH_REMATCH[1]}
  openj9=$jdk/openj9
else
  fatal "Can't decipher JDK root from path '$here'"
fi

if [[ $jdk =~ ^.*/jdk0*([1-9][0-9]*)$ ]] ; then
  version=${BASH_REMATCH[1]}
else
  fatal "Can't decipher JDK version from name '$jdk'"
fi

declare -a images=( $jdk/build/*/images )

if [ ${#images[*]} != 1 -o ! -d "$images" ] ; then
  # Try the current directory.
  images=$here/images
  if [ ! -d $images ] ; then
	fatal "Can't locate unique images directory"
  fi
fi

if [ $version = 8 ] ; then
  export TEST_JDK_HOME=$images/j2sdk-image
else
  export TEST_JDK_HOME=$images/jdk
fi

export JDK_VERSION=$version
export LD_LIBRARY_PATH=$images/test/openj9
export NATIVE_TEST_LIBS=$images/test/openj9

cd $openj9/test/TKG

echo "To download required test material & libraries and then compile:"
echo "  make compile"
echo "To generate makefiles and run tests:"
echo "  make _sanity.functional"

exec bash
