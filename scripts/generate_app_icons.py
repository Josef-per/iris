#!/usr/bin/env python3
"""Gera os ícones Android e web com a flor vetorial da logo existente.

Requer Python 3, PyGObject, pycairo e librsvg. Execute na raiz:
    python3 scripts/generate_app_icons.py
Os arquivos gerados são versionados; o build não depende dessas ferramentas.
"""

from pathlib import Path
import xml.etree.ElementTree as ET

import cairo
import gi

gi.require_version('Rsvg', '2.0')
from gi.repository import Rsvg


ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
BACKGROUND = '#462A7E'
FOREGROUND = '#FAF9F6'
ANDROID = 'http://schemas.android.com/apk/res/android'
SVG = 'http://www.w3.org/2000/svg'


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content + '\n', encoding='utf-8')


def main():
    logo = ET.parse(ROOT / 'assets/images/Login.svg')
    flower = logo.find(f'.//{{{SVG}}}g[@id="iris-flower-vector"]')
    if flower is None:
        raise SystemExit('A flor vetorial não foi encontrada na logo do Íris.')
    paths = [node.attrib['d'] for node in flower.findall(f'{{{SVG}}}path')]

    def png(path, size, scale):
        # Mesma geometria da logo; traço um pouco mais espesso para ícones pequenos.
        geometry = ''.join(f'<path d="{data}"/>' for data in paths)
        source = (
            f'<svg xmlns="{SVG}" width="108" height="108" viewBox="0 0 108 108">'
            f'<rect width="108" height="108" fill="{BACKGROUND}"/>'
            f'<g transform="matrix({scale} 0 0 {scale} {54 - 38 * scale} {54 - 55 * scale})" '
            f'fill="none" stroke="{FOREGROUND}" stroke-width="2.4" '
            f'stroke-linecap="round" stroke-linejoin="round">{geometry}</g></svg>'
        )
        path.parent.mkdir(parents=True, exist_ok=True)
        surface = cairo.ImageSurface(cairo.FORMAT_RGB24, size, size)
        viewport = Rsvg.Rectangle()
        viewport.width = viewport.height = size
        Rsvg.Handle.new_from_data(source.encode()).render_document(cairo.Context(surface), viewport)
        surface.write_to_png(str(path))

    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        png(RES / f'mipmap-{density}/ic_launcher.png', size, 0.72)
    for size in [192, 512]:
        png(ROOT / f'web/icons/Icon-{size}.png', size, 0.72)
        # Toda a flor cabe no círculo central seguro de um ícone maskable.
        png(ROOT / f'web/icons/Icon-maskable-{size}.png', size, 0.60)
    png(ROOT / 'web/icons/apple-touch-icon.png', 180, 0.72)
    png(ROOT / 'web/favicon.png', 32, 0.72)

    # Foreground adaptativo: a flor cabe na região segura central de 66 dp.
    vector_paths = '\n'.join(
        f'        <path android:pathData="{data}" android:fillColor="#00000000"\n'
        f'            android:strokeColor="{FOREGROUND}" android:strokeWidth="2.4"\n'
        '            android:strokeLineCap="round" android:strokeLineJoin="round" />'
        for data in paths
    )
    write(RES / 'drawable/ic_launcher_foreground.xml',
          f'<vector xmlns:android="{ANDROID}"\n'
          '    android:width="108dp" android:height="108dp"\n'
          '    android:viewportWidth="108" android:viewportHeight="108">\n'
          '    <group android:scaleX="0.48" android:scaleY="0.48"\n'
          '        android:translateX="35.76" android:translateY="27.6">\n'
          f'{vector_paths}\n    </group>\n</vector>')
    write(RES / 'values/ic_launcher_background.xml',
          f'<resources>\n    <color name="ic_launcher_background">{BACKGROUND}</color>\n</resources>')
    write(RES / 'mipmap-anydpi-v26/ic_launcher.xml',
          f'<adaptive-icon xmlns:android="{ANDROID}">\n'
          '    <background android:drawable="@color/ic_launcher_background" />\n'
          '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
          '</adaptive-icon>')


if __name__ == '__main__':
    main()
