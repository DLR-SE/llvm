#!/bin/bash

commandline="$0 $*"
echo "Commandline + :" $commandline

if [ "$#" -lt 4 ]; then
  echo "Usage: s4e-builder USER UID_GID CI_COMMIT_BRANCH update|build|check" >&2
  exit 1
fi

set -e

userName=$1
shift
uid_gid=$1
shift
ci_commit_branch=$1
shift

if [ `id -u` -eq 0 ]; then
	if id -u $userName >/dev/null 2>&1; then
		echo "User_Group_ID $ud_gid already in user. User "$userName" will be deleted and added again"
		userdel $userName 
	fi
        if (groupadd $userName -g "$uid_gid" >/dev/null 2>&1); then
		echo "Group exists"
	fi
	useradd -u "$uid_gid" -m -g $userName $userName

	chown -hR $userName:$userName /home/$userName

        su -c "$commandline" $userName
        exit $?
fi

if [ `id -u` -ne "$uid_gid" ]; then
	echo "Expected UID=$uid_gid, got `id -u`, quitting" >&2
 exit 1
fi

export SOURCE_DIR=/home/$userName/src
export BUILD_DIR=/home/$userName/build
export INSTALL_DIR=/home/$userName/install
export EXTENSIBLE_COMPILER_SRC_DIR=$SOURCE_DIR/extensible-compiler
export EXTENSIBLE_COMPILER_BUILD_DIR=$BUILD_DIR/extensible-compiler
export EXTENSIBLE_COMPILER_INSTALL_DIR=$INSTALL_DIR/extensible-compiler

case $1 in
  update)
  if [ -d "$EXTENSIBLE_COMPILER_SRC_DIR/.git" ]; then
      cd $EXTENSIBLE_COMPILER_SRC_DIR

      #check if it is the same branch before pulling
      if [ "$(git rev-parse --abbrev-ref HEAD)" == "$ci_commit_branch" ]; then
         git pull
      else
          cd $SOURCE_DIR && git clone --single-branch --branch $ci_commit_branch https://oauth2:skp_NYRGVXs4sto__Y92@gitlab.dlr.de/scale4edge/extensible-compiler.git
      fi
  else
      cd $SOURCE_DIR && git clone --single-branch --branch $ci_commit_branch https://oauth2:skp_NYRGVXs4sto__Y92@gitlab.dlr.de/scale4edge/extensible-compiler.git
    fi
;;
  build)

    mkdir -p $EXTENSIBLE_COMPILER_BUILD_DIR

    cd $EXTENSIBLE_COMPILER_BUILD_DIR && cmake\
	  -DCMAKE_BUILD_TYPE=Debug\
          -DLLVM_TARGETS_TO_BUILD='RISCV'\
          -DLLVM_ENABLE_PROJECTS='clang;lld'\
          -DCMAKE_C_COMPILER=clang\
          -DCMAKE_CXX_COMPILER=clang++\
          -DCMAKE_INSTALL_PREFIX=$EXTENSIBLE_COMPILER_INSTALL_DIR\
          -DLLVM_OPTIMIZED_TABLEGEN=1\
          -DLLVM_USE_LINKER=lld\
          -DLLVM_PARALLEL_LINK_JOBS=1\
          -DLLVM_USE_SPLIT_DWARF=1\
          -DLLVM_DEFAULT_TARGET_TRIPLE='riscv32-unknown-elf'\
	  $EXTENSIBLE_COMPILER_SRC_DIR/llvm &&\
        make -j`nproc` || make -j`nproc` || make &&\
        make install
    
    export GCC_TOOLCHAIN_INSTALL_DIR=/opt/gcc-riscv
    export PATH=$EXTENSIBLE_COMPILER_INSTALL_DIR/bin:$GCC_TOOLCHAIN_INSTALL_DIR:$PATH
    export SYSROOT=$GCC_TOOLCHAIN_INSTALL_DIR/riscv32-unknown-elf
    export LLVM_CONFIG=$EXTENSIBLE_COMPILER_INSTALL_DIR/bin/llvm-config
    export LLVM_BUILD=$EXTENSIBLE_COMPILER_INSTALL_DIR/
    export FLAGS="--target=riscv32-unknown-elf -march=rv32i -mabi=ilp32 --gcc-toolchain=$GCC_TOOLCHAIN_INSTALL_DIR --sysroot=$SYSROOT -B $GCC_TOOLCHAIN_INSTALL_DIR"
    export TEST_FLAGS="$FLAGS"
    mkdir -p $BUILD_DIR/rt
    cd $BUILD_DIR/rt && cmake\
            -DCOMPILER_RT_BUILD_BUILTINS=ON\
            -DCOMPILER_RT_BUILD_SANITIZERS=OFF\
            -DCOMPILER_RT_BUILD_XRAY=OFF\
            -DCOMPILER_RT_BUILD_LIBFUZZER=OFF\
            -DCOMPILER_RT_BUILD_PROFILE=OFF\
            -DCMAKE_C_COMPILER=$LLVM_BUILD/bin/clang\
            -DCMAKE_CXX_COMPILER=$LLVM_BUILD/bin/clang++\
            -DCMAKE_AR=$LLVM_BUILD/bin/llvm-ar\
            -DCMAKE_NM=$LLVM_BUILD/bin/llvm-nm\
            -DCMAKE_RANLIB=$LLVM_BUILD/bin/llvm-ranlib\
            -DCMAKE_C_COMPILER_TARGET="riscv32-unknown-elf"\
            -DCMAKE_ASM_COMPILER_TARGET="riscv32-unknown-elf"\
            -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON\
            -DCMAKE_C_FLAGS="$FLAGS"\
            -DCMAKE_CXX_FLAGS="$FLAGS"\
            -DCMAKE_ASM_FLAGS="$FLAGS"\
            -DCOMPILER_RT_OS_DIR="baremetal"\
            -DCOMPILER_RT_BAREMETAL_BUILD=ON\
            -DCOMPILER_RT_INCLUDE_TESTS=ON\
            -DCOMPILER_RT_EMULATOR="qemu-riscv32 -L $SYSROOT"\
            -DCOMPILER_RT_TEST_COMPILER="$LLVM_BUILD/bin/clang"\
            -DCOMPILER_RT_TEST_COMPILER_CFLAGS="$TEST_FLAGS"\
            -DLLVM_CONFIG_PATH=$LLVM_CONFIG\
	    -DLLVM_PARALLEL_LINK_JOBS=1\
	    -DLLVM_USE_SPLIT_DWARF=1\
            -DLLVM_DEFAULT_TARGET_TRIPLE="riscv32-unknown-elf"\
            -DCMAKE_INSTALL_PREFIX=$EXTENSIBLE_COMPILER_INSTALL_DIR/lib/clang/13.0.0\
            $EXTENSIBLE_COMPILER_SRC_DIR/compiler-rt &&\
        make -j`nproc` &&\
	make install
  ;;
  check)
    export PATH=$EXTENSIBLE_COMPILER_INSTALL_DIR/bin:$GCC_TOOLCHAIN_INSTALL_DIR:$PATH
    cd $EXTENSIBLE_COMPILER_BUILD_DIR && make check-all
    ;;
  *)
    echo "Usage: s4e-builder USER UID_GID CI_COMMIT_BRANCH update|build|check" >&2
    exit 1
  ;;
esac

