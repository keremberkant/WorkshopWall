# Recreating simple Scene wallpapers

Wallpaper Engine *Scene* wallpapers use a proprietary renderer, so WorkshopWall can't play them directly.
Many popular scenes, though, are just **one image plus one or two built-in effects** (water waves, shake,
scroll, pulse…). Those can be rebuilt as a small WebGL web wallpaper that looks the same and plays in
WorkshopWall. Only do this with wallpapers you have the right to use.

## 1. Look inside the scene

A downloaded scene folder contains `project.json` and usually `scene.pkg`. The `.pkg` file is a simple archive:

```
"PKGV0005"-style header string (uint32 length + bytes)
uint32 file count
for each file: name (uint32 length + bytes), uint32 offset, uint32 size
file data (offsets are relative to the end of this table)
```

Extract it with a few lines of Python:

```python
import struct, os
f = open("scene.pkg", "rb")
def string():
    n = struct.unpack("<I", f.read(4))[0]; return f.read(n).decode("latin1")
string(); count = struct.unpack("<I", f.read(4))[0]
entries = [(string(), *struct.unpack("<II", f.read(8))) for _ in range(count)]
base = f.tell()
for name, offset, size in entries:
    f.seek(base + offset); os.makedirs(os.path.dirname("out/" + name) or "out", exist_ok=True)
    open("out/" + name, "wb").write(f.read(size))
```

`scene.json` lists the objects and their effects with their values (`constantshadervalues`).

## 2. Get the image

Textures are `.tex` files. Many of them simply embed a PNG or JPEG — search for the PNG signature:

```python
d = open("out/materials/MyImage.tex", "rb").read()
start = d.find(b"\x89PNG"); end = d.find(b"IEND", start) + 8
open("image.png", "wb").write(d[start:end])
```

(Textures stored as compressed GPU formats need a dedicated converter.)

## 3. Use the template

Copy [`templates/water-waves`](../templates/water-waves) to a new folder, save your image there as
`image.jpg`, and copy the effect values from `scene.json` into the `WAVES` array at the top of
`index.html`. Then drag the folder into WorkshopWall.

Other effects follow the same idea: move the texture coordinate over time in a fragment shader.
Pull requests with more templates are welcome.
