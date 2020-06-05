#!/bin/bash -eu

fatal() {
	echo >&2 "$*"
	exit 1
}

arch="$(uname -p)"

case "$arch" in
	amd64|x86_64)
		platform=x64
		;;
	ppc64el|ppc64le)
		platform=ppc64le
		;;
	s390x)
		platform=s390x
		;;
	*)
		fatal "Unsupported machine architecture: $arch"
		;;
esac

# Download and unpack freemarker.jar if needed.
if [ -f freemarker.jar ] ; then
	echo "freemarker.jar exists: skipping."
else
	echo "Fetching freemarker.jar ..."
	wget -q -O freemarker.tar.gz \
		https://sourceforge.net/projects/freemarker/files/freemarker/2.3.8/freemarker-2.3.8.tar.gz/download
	tar -xzf freemarker.tar.gz freemarker-2.3.8/lib/freemarker.jar --strip-components=2
	rm freemarker.tar.gz
fi

# Install some boot JDKs.
for version in 8 11 14 ; do
	jdk_name=bootjdk$version
	if [ -d $jdk_name ]; then
		echo "$jdk_name exists: skipping."
	elif [ -e $jdk_name ]; then
		echo "$jdk_name exists, but is not a directory: skipping."
	else
		echo "Fetching $jdk_name.tar.gz ..."
		wget -q -O $jdk_name.tar.gz \
			https://api.adoptopenjdk.net/v3/binary/latest/$version/ga/linux/$platform/jdk/openj9/normal/adoptopenjdk
		mkdir $jdk_name
		# AdoptOpenJDK produces tar files where the contained paths begin with './{jdk-root}/'
		# so we need to strip 2 leading segments to get the desired structure.
		tar -C $jdk_name --strip-components=2 -xzf $jdk_name.tar.gz
		rm $jdk_name.tar.gz
	fi
done
