#!/bin/bash
# Simply run ./llvm_update_alternatives.sh <MAJOR_VERSION>

set -u

LLVM_VERSION=21
GCC_VERSION=12

update_to=$1
if [ -n "$update_to" ]; then
	if [ "$update_to" -lt 16 ] || [ "$update_to" -gt 21 ]; then
		echo "Invalid version number. Please provide a version number between 16 and 21"
		exit 1
	else
		LLVM_VERSION=$update_to
	fi
fi

remove_all="gcc g++ clang clang++ cc c++ llvm-config"
for rem in $remove_all; do
	sudo update-alternatives --remove-all $rem 2>/dev/null
done

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 70 --slave /usr/bin/g++ g++ /usr/bin/g++-$GCC_VERSION

sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$LLVM_VERSION 90 --slave /usr/bin/clang++ clang++ /usr/bin/clang++-$LLVM_VERSION
sudo update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-$LLVM_VERSION 180 \
	--slave /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-$LLVM_VERSION \
	--slave /usr/bin/llvm-as llvm-as /usr/bin/llvm-as-$LLVM_VERSION \
	--slave /usr/bin/llvm-link llvm-link /usr/bin/llvm-link-$LLVM_VERSION \
	--slave /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-$LLVM_VERSION \
	--slave /usr/bin/llvm-objdump llvm-objdump /usr/bin/llvm-objdump-$LLVM_VERSION \
	--slave /usr/bin/llvm-ranlib llvm-ranlib /usr/bin/llvm-ranlib-$LLVM_VERSION

sudo update-alternatives --install /usr/bin/cc cc /usr/bin/clang 150 --slave /usr/bin/c++ c++ /usr/bin/clang++
sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 100 --slave /usr/bin/c++ c++ /usr/bin/g++

if [ "$(readlink -f /usr/bin/clang)" = "/usr/lib/llvm-$LLVM_VERSION/bin/clang" ]; then
	echo "clang-$LLVM_VERSION is now the default version"
else
	echo "clang-$LLVM_VERSION is not the default version"
fi