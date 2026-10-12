#!/usr/bin/env python3
"""Ajusta el scaffold Android generado por Flutter a los requisitos de Combo Manager."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
# `flutter create --project-name app .` puede cambiar el nombre del paquete Dart
# en ciertas versiones. Los imports y las pruebas usan `package:combo_manager`.
pubspec = root / 'pubspec.yaml'
if not pubspec.exists():
    raise SystemExit('No se encontró pubspec.yaml en la raíz del proyecto.')
pubspec_content = pubspec.read_text(encoding='utf-8')
pubspec_content, reemplazos = re.subn(
    r'(?m)^name:\s*[^\s]+\s*$', 'name: combo_manager', pubspec_content, count=1
)
if reemplazos != 1:
    raise SystemExit('No se pudo asegurar el nombre Dart `combo_manager` en pubspec.yaml.')
pubspec.write_text(pubspec_content, encoding='utf-8')

manifest_root = root / 'android' / 'app' / 'src'
main_manifest = manifest_root / 'main' / 'AndroidManifest.xml'
if not main_manifest.exists():
    raise SystemExit('No se encontró el AndroidManifest.xml generado por Flutter.')

for manifest in manifest_root.rglob('AndroidManifest.xml'):
    content = manifest.read_text(encoding='utf-8')
    content = re.sub(r'\s*<uses-permission[^>]+android\.permission\.INTERNET[^>]*/>', '', content)
    if manifest == main_manifest:
        content = re.sub(r'android:label="[^"]*"', 'android:label="Combo Manager"', content, count=1)
        if 'android:screenOrientation=' not in content:
            content = re.sub(r'(<activity\b[^>]*android:name="[^"]*MainActivity"[^>]*)', r'\1 android:screenOrientation="portrait"', content, count=1)
        else:
            content = re.sub(r'android:screenOrientation="[^"]*"', 'android:screenOrientation="portrait"', content)
    manifest.write_text(content, encoding='utf-8')

# Asegura el identificador solicitado, tanto en Groovy como en Kotlin DSL.
for gradle in (root / 'android' / 'app').glob('build.gradle*'):
    content = gradle.read_text(encoding='utf-8')
    content = re.sub(r'namespace\s*=\s*["\'][^"\']+["\']', 'namespace = "com.combomanager.app"', content)
    content = re.sub(r'applicationId\s*=\s*["\'][^"\']+["\']', 'applicationId = "com.combomanager.app"', content)
    content = re.sub(r'namespace\s+["\'][^"\']+["\']', 'namespace "com.combomanager.app"', content)
    content = re.sub(r'applicationId\s+["\'][^"\']+["\']', 'applicationId "com.combomanager.app"', content)
    gradle.write_text(content, encoding='utf-8')

print('Configuración Android aplicada: Combo Manager, paquete com.combomanager.app, orientación vertical y sin permiso INTERNET.')

# Ícono sencillo en la paleta naranja/blanco, incluidos recursos adaptativos de Android.
import struct
import zlib

res = root / 'android' / 'app' / 'src' / 'main' / 'res'
values = res / 'values'
values.mkdir(parents=True, exist_ok=True)
(values / 'ic_launcher_background.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources><color name="ic_launcher_background">#FF6B35</color></resources>
''', encoding='utf-8')

drawable = res / 'drawable'
drawable.mkdir(parents=True, exist_ok=True)
(drawable / 'ic_launcher_foreground.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
  <path android:fillColor="#FFFFFFFF" android:pathData="M24,43 L84,43 L84,54 L24,54 Z M29,55 L79,55 L79,82 L29,82 Z"/>
  <path android:fillColor="#FFE63946" android:pathData="M49,43 L59,43 L59,82 L49,82 Z"/>
  <path android:fillColor="#FFFFFFFF" android:pathData="M49,42 C39,43 31,37 31,29 C31,22 38,20 43,25 C47,29 51,37 54,42 Z M59,42 C69,43 77,37 77,29 C77,22 70,20 65,25 C61,29 57,37 54,42 Z"/>
</vector>
''', encoding='utf-8')
anydpi = res / 'mipmap-anydpi-v26'
anydpi.mkdir(parents=True, exist_ok=True)
adaptive = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
'''
(anydpi / 'ic_launcher.xml').write_text(adaptive, encoding='utf-8')
(anydpi / 'ic_launcher_round.xml').write_text(adaptive, encoding='utf-8')


def png_bytes(size):
    orange = (255, 107, 53, 255)
    white = (255, 255, 255, 255)
    red = (230, 57, 70, 255)
    rows = []
    scale = size / 192.0
    for y in range(size):
        row = bytearray([0])
        for x in range(size):
            # Fondo cuadrado con esquinas redondeadas.
            r = 22 * scale
            cx = min(max(x, r), size - r)
            cy = min(max(y, r), size - r)
            inside = (x - cx) ** 2 + (y - cy) ** 2 <= r ** 2 or (r <= x < size-r and r <= y < size-r)
            color = orange if inside else (0, 0, 0, 0)
            # Lazo, tapa y cuerpo de regalo.
            nx, ny = x / scale, y / scale
            left_loop = ((nx - 76) / 19) ** 2 + ((ny - 60) / 14) ** 2 <= 1
            right_loop = ((nx - 116) / 19) ** 2 + ((ny - 60) / 14) ** 2 <= 1
            if left_loop or right_loop:
                color = white
            if 44 <= nx <= 148 and 70 <= ny <= 88:
                color = white
            if 52 <= nx <= 140 and 87 <= ny <= 145:
                color = white
            if 89 <= nx <= 103 and 70 <= ny <= 145:
                color = red
            row.extend(bytes(color))
        rows.append(bytes(row))
    raw = b''.join(rows)
    def chunk(name, data):
        return struct.pack('!I', len(data)) + name + data + struct.pack('!I', zlib.crc32(name + data) & 0xffffffff)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', size, size, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')

for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    folder = res / f'mipmap-{density}'
    folder.mkdir(parents=True, exist_ok=True)
    (folder / 'ic_launcher.png').write_bytes(png_bytes(size))
    (folder / 'ic_launcher_round.png').write_bytes(png_bytes(size))

print('Ícono Combo Manager creado en los tamaños de lanzamiento Android.')
