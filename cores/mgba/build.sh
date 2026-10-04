#!/bin/bash
# Rebuild custom mgba EJS cores (emscripten 4.0.8, RetroArch EmulatorJS/next @6dd435393, mgba EmulatorJS/master @1d9dbb1dc)
set -e
C=$(cd "$(dirname "$0")" && pwd); source $C/emsdk/emsdk_env.sh
cd $C/mgba && emmake make -j$(nproc) -f Makefile.libretro platform=emscripten
cd $C/RetroArch
for GLES3 in 0 1; do
  make -f Makefile.emulatorjs clean; cp $C/mgba/mgba_libretro_emscripten.bc libretro_emscripten.a
  emmake make -f Makefile.emulatorjs -j$(nproc) HAVE_CHD=1 HAVE_THREADS=0 PTHREAD_POOL_SIZE=0 ASYNC=0 \
    HAVE_AL=0 HAVE_RWEBAUDIO=1 AUTO_MEMORY_GROWTH=0 HAVE_OPENGLES3=$GLES3 STACK_SIZE=4194304 \
    INITIAL_HEAP=${INITIAL_HEAP:-268435456} TARGET=mgba_libretro.js
  n=$([ $GLES3 = 0 ] && echo mgba-legacy-wasm || echo mgba-wasm)
  python3 $C/pack.py $C/$n.data mgba_libretro.js mgba_libretro.wasm $C/stock/$n
done
