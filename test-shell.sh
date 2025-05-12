#!/bin/bash -

fatal() {
  echo >&2 "$*"
  exit 1
}

here=$(pwd -P)

# look for an ancestor directory containing closed/openjdk-tag.gmk
tag_file=closed/openjdk-tag.gmk
jdk=$here
while true ; do
  if [ -f $jdk/$tag_file ] ; then
    version=$(sed -E -n -e 's/^.*jdk-?([0-9]+).*$/\1/p' < $jdk/$tag_file)
    if [ -n "$version" ] ; then
      break
    fi
    fatal "Can't decipher JDK version from name '$jdk/$tag_file'"
  elif [ $jdk = / ] ; then
    fatal "Can't decipher JDK root from path '$here'"
  fi
  jdk=$(dirname $jdk)
done

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
export NATIVE_TEST_LIBS=$images/test/openj9

cd $jdk/openj9/test/TKG

echo "To download required test material & libraries and then compile:"
echo "  make compile"
echo "To generate makefiles and run tests:"
echo "  make _sanity.functional"

exec bash
