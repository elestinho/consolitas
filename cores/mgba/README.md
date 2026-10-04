# Núcleo mGBA propio (prueba contra los cierres en iPhone)

En iOS 26.2 y posteriores, Safari cierra la página a los ~70 s con los núcleos de EmulatorJS 4.2.3
(ver https://github.com/EmulatorJS/EmulatorJS/issues/1143). Estos archivos son el mismo núcleo mGBA
compilado de nuevo con:

- memoria fija de 256 MB (sin `ALLOW_MEMORY_GROWTH`),
- sin Asyncify,
- sin OpenAL: el sonido sale por el controlador `rwebaudio` de RetroArch.

Fuentes:
- RetroArch, fork de EmulatorJS (`next` @6dd435393), con el parche `retroarch-ejs-rwebaudio-nogrowth.patch`.
- mgba, fork de EmulatorJS (@1d9dbb1dc), sin cambios.
- Emscripten 4.0.8. `build.sh` y `pack.py` los vuelven a generar.

Licencias: RetroArch es GPL-3.0 y mGBA es MPL-2.0; cada `.data` (archivo 7z) incluye su `license.txt`.
