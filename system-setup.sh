#!/bin/bash -eu

fatal() {
	echo >&2 "$*"
	exit 1
}

arch="$(uname -p)"
libnuma=libnuma-dev
nasm=

case "$arch" in
	amd64|x86_64)
		nasm=nasm
		;;
	ppc64el|ppc64le)
		;;
	s390x)
		libnuma=
		;;
	*)
		fatal "Unsupported machine architecture: $arch"
		;;
esac

if [ $(id -u) != 0 ] ; then
	fatal "This script requires root privileges."
fi

apt-get update

apt-get install -qq -y --no-install-recommends \
	software-properties-common

add-apt-repository -y ppa:ubuntu-toolchain-r/test

apt-get update

apt-get install -qq -y --no-install-recommends \
	autoconf \
	ca-certificates \
	ccache \
	cmake \
	cpio \
	file \
	g++-7 \
	g++-8 \
	git \
	git-core \
	less \
	libasound2-dev \
	libcups2-dev \
	libdwarf-dev \
	libelf-dev \
	libfontconfig1-dev \
	libfreetype6-dev \
	$libnuma \
	libssl-dev \
	libx11-dev \
	libxext-dev \
	libxrandr-dev \
	libxrender-dev \
	libxt-dev \
	libxtst-dev \
	make \
	$nasm \
	pkg-config \
	ssh \
	systemtap-sdt-dev \
	unzip \
	vim \
	wget \
	zip

rm -rf /var/lib/apt/lists/*
