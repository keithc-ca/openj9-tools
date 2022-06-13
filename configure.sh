#!/bin/bash -

fatal() {
	echo >&2 "$*"
	exit 1
}

do_config() {
	tooldir=$(dirname $PWD)
	thisdir=$(basename $PWD)

	# This script is expected to be run from the root working directory of an
	# extensions repository; we use openjdk-tag.gmk to identify the version.
	tag_file=closed/openjdk-tag.gmk
	if [ -f $tag_file ] ; then
		repo=$(sed -E -n -e 's/^.*jdk-?([0-9]+).*$/\1/p' < $tag_file)
	else
		repo=
	fi
	if [ -z "$repo" ] ; then
		fatal "Don't know which Java version to configure."
	fi

	bootversions="$(($repo - 1)) $repo"
	cmake="--with-cmake"
	debuginfo=
	freemarker=$tooldir/freemarker.jar
	openssl=fetched

	if [ -n "$CUDA_HOME" -a -f "$CUDA_HOME/include/cuda.h" ] ; then
		cuda="$CUDA_HOME"
	else
		cuda=
	fi

	if [ $repo -le 8 ] ; then
		debuginfo="--disable-zip-debug-info"
	else
		debuginfo="--with-native-debug-symbols=external"
	fi

	# use the first bootjdk we find
	for version in $bootversions ; do
		if [ -x "$tooldir/bootjdk$version/bin/java" ] ; then
			bootjdk=$tooldir/bootjdk$version
			break
		fi
	done

	if [ -z "$bootjdk" ] ; then
		fatal "Don't know which bootjdk to use for Java $repo"
	elif [ ! -x "$bootjdk/bin/java" ] ; then
		fatal "$bootjdk/bin/java does not exist or is not executable"
	elif [ -n "$cmake" -a -z "$freemarker" ] ; then
		fatal "Don't know which freemarker.jar to use for Java $repo"
	elif [ ! -f "$freemarker" ] ; then
		fatal "$freemarker does not exist or is not a file"
	else
		bash configure \
			--with-boot-jdk="$bootjdk" \
			${cuda:+--enable-cuda --with-cuda="$cuda"} \
			${cmake:---with-freemarker-jar="$freemarker"} \
			$debuginfo \
			--enable-jitserver \
			${openssl:+--with-openssl=$openssl --enable-openssl-bundling}
	fi
}

if [ $# -eq 0 ] ; then
	do_config
else
	for dir in "$@" ; do
		if [ ! -d "$dir" ] ; then
			echo >&2 "$dir does not exist"
		else
			echo "Running configure for $dir ..."
			( cd $dir ; do_config )
		fi
	done
fi
