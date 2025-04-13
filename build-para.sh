TARGET_DEVICE=$1
BUILD_DATE=$(date "+%Y%m%d-%H%M")

#ccache
export CCACHE_DIR="$HOME/.cache/ccache_mikernel"
export CC="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache:$PATH"
echo "CCACHE_DIR: [$CCACHE_DIR]"

MAKE_ARGS="O=out \
CC=clang \
AR=llvm-ar \
NM=llvm-nm \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
HOSTCC=clang \
HOSTCXX=clang++ \
LD=ld.lld \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
LLVM=1 \
LLVM_IAS=1"

if [ ! -f "arch/arm64/configs/${TARGET_DEVICE}_defconfig" ]; then
    echo "No [${TARGET_DEVICE}] defconfig found."
    echo "Avaliable defconfigs:"
    ls arch/arm64/configs/*_defconfig
    exit 1
fi

KSU_ZIP_STR=noksu
if [ "$2" == "ksu" ]; then
    KSU_E=1
    KSU_ZIP_STR=ksu
else
    KSU_E=0
fi

if [ $KSU_E -eq 1 ]; then
    echo "dloading ksu & applying patches"
    curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -
#    wget https://gist.githubusercontent.com/zainarbani/2b482e9e9c415a644953397b6ba5571f/raw/b66cf8d0683b5397fc1f7cc6b33ff12cc9bf9292/ksu.patch
#    git apply ksu.patch
else 
    echo "no ksu build"
fi

rm -rf out/

#----------------------build shit here

echo "======= START OF BUILD ======="
make $MAKE_ARGS ${TARGET_DEVICE}_defconfig

if [ $KSU_E -eq 1 ]; then
    scripts/config --file out/.config -e KSU
fi

make $MAKE_ARGS -j$(nproc --all)
echo "======= END OF BUILD ======="

KOUT_PATH="/mnt/d/users/juan/kernels/${TARGET_DEVICE}/$(date "+%Y%m%d-%H%M")_noksu"

if [ -f "out/arch/arm64/boot/Image" ]; then
    echo "Image found. Build successful"
    if [ ! -d "/mnt/d/users/juan/kernels/${TARGET_DEVICE}" ]; then
        mkdir /mnt/d/users/juan/kernels/${TARGET_DEVICE}/
    fi0
        mkdir $KOUT_PATH
        cp out/arch/arm64/boot/Image $KOUT_PATH/
else
    echo "Image not found. Pizdec blyat"
    exit 1
fi
