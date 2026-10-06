# 7-Zip para abrir .7z y .rar

`7zz.umd.js` y `7zz.wasm` son 7-Zip 24.09 compilado a WebAssembly, del paquete npm
[7z-wasm 1.2.0](https://github.com/use-strict/7z-wasm) sin cambios. La app los carga en un Worker solo
cuando se añade un `.7z` o un `.rar` (Versión 97). Licencia: GNU LGPL + restricción de unRAR
(ver `License.txt` y `unRarLicense.txt`).
