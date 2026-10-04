#!/bin/bash
# Custom EmulatorJS 4.2.3 core builder for iOS 26.2+ (fixed memory, no asyncify, rwebaudio instead of OpenAL).
# Usage: ./build-core.sh <core> [variants]   variants: subset of "wasm legacy thread thread-legacy" (default per core)
# Env overrides: INITIAL_HEAP=<bytes>, KEEP_SRC=1
# Toolchain: emsdk 4.0.8 in ./emsdk; RetroArch = EmulatorJS/RetroArch next @6dd435393 + retroarch-ejs-rwebaudio-nogrowth.patch
# Core sources: EmulatorJS forks, last first-parent commit before the stock 4.2.3 build (2025-06-14).
set -e
C=$(cd "$(dirname "$0")" && pwd)
core=$1; shift || true
MB=1048576
case $core in
  mgba)             repo=mgba;                    rev=1d9dbb1dc; bp=.;        mk=Makefile.libretro; lic=LICENSE;     heap=$((256*MB));  var="wasm legacy";;
  gambatte)         repo=gambatte-libretro;       rev=4ac2b30d1; bp=.;        mk=Makefile.libretro; lic=COPYING;     heap=$((256*MB));  var="wasm legacy";;
  fceumm)           repo=libretro-fceumm;         rev=d9d7e1412; bp=.;        mk=Makefile.libretro; lic=Copying;     heap=$((256*MB));  var="wasm legacy";;
  snes9x)           repo=snes9x;                  rev=6ca2343e5; bp=libretro; mk=Makefile;          lic=LICENSE;     heap=$((256*MB));  var="wasm legacy";;
  genesis_plus_gx)  repo=Genesis-Plus-GX;         rev=594cdf3a6; bp=.;        mk=Makefile.libretro; lic=LICENSE.txt; heap=$((1024*MB)); var="wasm legacy";;
  melonds)          repo=melonDS;                 rev=18a057d37; bp=.;        mk=Makefile;          lic=LICENSE;     heap=$((1024*MB)); var="wasm legacy thread thread-legacy";;
  pcsx_rearmed)     repo=pcsx_rearmed;            rev=f29871dde; bp=.;        mk=Makefile.libretro; lic=COPYING;     heap=$((1024*MB)); var="wasm legacy thread thread-legacy"; chd=0;;
  *) echo "unknown core $core"; exit 1;;
esac
[ -n "$1" ] && var="$*"
heap=${INITIAL_HEAP:-$heap}; stack=${stack:-4194304}; chd=${chd:-1}
OUT=$C/out-all; LOG=$C/logs; mkdir -p $OUT $LOG $C/src
source $C/emsdk/emsdk_env.sh >/dev/null 2>&1

# stock metadata (build.json/core.json/license.txt) from npm @emulatorjs/core-<core>@4.2.3
if [ ! -d $C/npm/$core ]; then (cd $C/npm && npm pack -q @emulatorjs/core-$core@4.2.3 && mkdir -p $core && tar xzf emulatorjs-core-$core-4.2.3.tgz -C $core --strip-components=1 && rm emulatorjs-core-$core-4.2.3.tgz); fi
S=$C/src/$core
if [ ! -d $S ]; then
  git clone -q --filter=blob:none https://github.com/EmulatorJS/$repo $S
  (cd $S && git checkout -q $rev && git submodule update -q --init --recursive || true)
  # arreglos propios de un núcleo (melonds-fullpath.patch: el núcleo lee la ROM él mismo, una sola copia en memoria)
  for p in $C/$core-*.patch; do [ -f "$p" ] && (cd $S && git apply "$p"); done
fi
uses_legacy=$(grep -l EMULATORJS_LEGACY $S/$bp/Makefile* 2>/dev/null | head -1 || true)
lastcore=""
for v in $var; do
  thr=0; leg=0
  case $v in thread) thr=1;; thread-legacy) thr=1; leg=1;; legacy) leg=1;; esac
  key="$thr-$([ -n "$uses_legacy" ] && echo $leg || echo x)"
  if [ "$key" != "$lastcore" ]; then
    echo "[$core] building core ($v)"
    cd $S/$bp; rm -f *.bc
    emmake make -f $mk clean >/dev/null 2>&1 || true
    args="platform=emscripten INITIAL_HEAP=$heap AUTO_MEMORY_GROWTH=0"
    [ $thr = 1 ] && args="$args EMULATORJS_THREADS=1"; [ $leg = 1 ] && args="$args EMULATORJS_LEGACY=1"
    emmake make -j$(nproc) -f $mk $args > $LOG/$core-$v-core.log 2>&1 || { echo "[$core] core build FAILED, see $LOG/$core-$v-core.log"; exit 1; }
    bc=$(ls *.bc | head -1); cp $bc $C/$core.core.a; lastcore=$key
  fi
  echo "[$core] linking $v (heap $((heap/MB))MB)"
  cd $C/RetroArch; make -f Makefile.emulatorjs clean >/dev/null; cp $C/$core.core.a libretro_emscripten.a
  emmake make -f Makefile.emulatorjs -j$(nproc) HAVE_CHD=$chd HAVE_THREADS=$thr PTHREAD_POOL_SIZE=$([ $thr = 1 ] && echo 4 || echo 0) \
    ASYNC=0 HAVE_AL=0 HAVE_RWEBAUDIO=1 AUTO_MEMORY_GROWTH=0 HAVE_OPENGLES3=$((1-leg)) STACK_SIZE=$stack INITIAL_HEAP=$heap \
    TARGET=${core}_libretro.js > $LOG/$core-$v-link.log 2>&1 || { echo "[$core] link FAILED, see $LOG/$core-$v-link.log"; exit 1; }
  sfx=""; [ $thr = 1 ] && sfx=-thread; [ $leg = 1 ] && sfx=$sfx-legacy; name=$core$sfx-wasm.data
  rm -rf $C/stockx && mkdir -p $C/stockx && python3 -c "import py7zr;py7zr.SevenZipFile('$C/npm/$core/$name').extractall('$C/stockx')"
  files="${core}_libretro.js ${core}_libretro.wasm"; if [ -f ${core}_libretro.worker.js ]; then files="$files ${core}_libretro.worker.js"; fi
  python3 - "$OUT/$name" "$C/stockx" $files <<'E'
import py7zr, sys, os
out, stock, files = sys.argv[1], sys.argv[2], sys.argv[3:]
with py7zr.SevenZipFile(out, 'w') as a:
    for f in files: a.write(f, os.path.basename(f))
    for f in sorted(os.listdir(stock)):
        if not any(f == os.path.basename(x) for x in files) and not f.endswith(('.js', '.wasm')): a.write(os.path.join(stock, f), f)
E
  python3 -c "
import py7zr;s=sorted(i.filename for i in py7zr.SevenZipFile('$C/npm/$core/$name').list());o=sorted(i.filename for i in py7zr.SevenZipFile('$OUT/$name').list())
print('[$core]', '$name', 'layout', 'OK' if s==o else 'DIFF stock=%s ours=%s'%(s,o))"
  python3 $C/memsec.py ${core}_libretro.wasm | sed "s|^.*memory|[$core] memory|"
  rm -f ${core}_libretro.js ${core}_libretro.wasm ${core}_libretro.worker.js libretro_emscripten.a
done
cd $C/RetroArch && make -f Makefile.emulatorjs clean >/dev/null; rm -rf $C/stockx $C/$core.core.a
[ "$KEEP_SRC" = 1 ] || rm -rf $S
