# Núcleos propios (contra los cierres en iPhone)

En iOS 26.2 y posteriores, Safari cierra la página a los ~70 s con los núcleos de EmulatorJS 4.2.3
(ver https://github.com/EmulatorJS/EmulatorJS/issues/1143). Estos archivos son los mismos núcleos
compilados de nuevo con:

- memoria fija (sin `ALLOW_MEMORY_GROWTH`; en las versiones con hilos, memoria compartida fija),
- sin Asyncify,
- sin OpenAL: el sonido sale por el controlador `rwebaudio` de RetroArch.

La app los usa en todas las consolas menos la Nintendo 64, que sigue con el núcleo de EmulatorJS.
Se pueden desactivar en Ajustes › «Emuladores anticierres».

| Consola | Núcleo | Memoria fija | Fuente (fork de EmulatorJS) | Licencia |
|---|---|---|---|---|
| GBA | mgba | 256 MB | mgba @1d9dbb1dc | MPL-2.0 |
| Game Boy / Color | gambatte | 256 MB | gambatte-libretro @4ac2b30d1 | GPL-2.0 |
| NES | fceumm | 256 MB | libretro-fceumm @d9d7e1412 | GPL-2.0 |
| Super Nintendo | snes9x | 256 MB | snes9x @6ca2343e5 | licencia de Snes9x (uso no comercial) |
| Mega Drive / Game Gear | genesis_plus_gx | 1024 MB | Genesis-Plus-GX @594cdf3a6 | licencia de Genesis Plus GX (uso no comercial) |
| Nintendo DS | melonds | 1024 MB | melonDS @18a057d37 | GPL-3.0 |
| PlayStation | pcsx_rearmed | 1024 MB | pcsx_rearmed @f29871dde | GPL-2.0 |

Común a todos: Emscripten 4.0.8 y RetroArch del fork de EmulatorJS (`next` @6dd435393, GPL-3.0) con el
parche `retroarch-ejs-rwebaudio-nogrowth.patch`. Cada `.data` (archivo 7z) lleva su `license.txt`,
`build.json` y `core.json` originales. `build-core.sh <núcleo>` los vuelve a generar.

melonDS lleva además `melonds-fullpath.patch`: el núcleo lee la ROM él mismo en vez de recibirla ya cargada,
así el juego está una sola vez en memoria. Con la memoria fija, los juegos más grandes de la DS (512 MB, como
Kingdom Hearts 358/2 Days) no cabían y salía «Failed to start game».

melonDS lleva también `melonds-lado-a-lado.patch`: con las pantallas lado a lado («Left/Right») respeta el hueco
entre ellas (`melonds_screen_gap`), que el núcleo original solo dejaba con las pantallas una encima de otra. Lo usan
las skins horizontales de la DS (Gris, Verde y Negra y oro), que tienen una franja entre las dos pantallas.
