import py7zr, sys, os
out, js, wasm, stockdir = sys.argv[1:5]
with py7zr.SevenZipFile(out, 'w') as a:
    a.write(js, 'mgba_libretro.js'); a.write(wasm, 'mgba_libretro.wasm')
    for f in ['build.json','core.json','license.txt']: a.write(os.path.join(stockdir,f), f)
print(out, os.path.getsize(out), [i.filename for i in py7zr.SevenZipFile(out).list()])
