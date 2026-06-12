#!/usr/bin/env python3
"""Generate app and extension icons for Safari Tab Tab."""
from __future__ import annotations

import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: Path, size: int, rgba_fn) -> None:
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            raw.extend(rgba_fn(x, y, size))

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    data = png_chunk(b"IHDR", ihdr)
    data += png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    data += png_chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + data)


def icon_rgba(x: int, y: int, size: int) -> bytes:
    cx = (size - 1) / 2
    cy = (size - 1) / 2
    dx = x - cx
    dy = y - cy
    dist = math.hypot(dx, dy)
    radius = size * 0.42

    if dist > radius:
        return bytes([0, 0, 0, 0])

    t = max(0.0, min(1.0, (y / max(size - 1, 1))))
    r = int(45 + (20 * t))
    g = int(120 + (35 * t))
    b = int(255 - (20 * t))
    alpha = 255

    if radius - size * 0.07 < dist <= radius - size * 0.02:
        return bytes([255, 255, 255, 180])

    if _point_in_polygon(x, y, _arrow_poly(size, left=True)):
        return bytes([255, 255, 255, 255])

    if _point_in_polygon(x, y, _arrow_poly(size, left=False)):
        return bytes([255, 255, 255, 255])

    return bytes([r, g, b, alpha])


def _arrow_poly(size: int, left: bool) -> list[tuple[float, float]]:
    s = size
    if left:
        return [
            (0.30 * s, 0.50 * s),
            (0.50 * s, 0.32 * s),
            (0.50 * s, 0.42 * s),
            (0.66 * s, 0.42 * s),
            (0.66 * s, 0.58 * s),
            (0.50 * s, 0.58 * s),
            (0.50 * s, 0.68 * s),
        ]
    return [
        (0.70 * s, 0.50 * s),
        (0.50 * s, 0.32 * s),
        (0.50 * s, 0.42 * s),
        (0.34 * s, 0.42 * s),
        (0.34 * s, 0.58 * s),
        (0.50 * s, 0.58 * s),
        (0.50 * s, 0.68 * s),
    ]


def _point_in_polygon(x: float, y: float, poly: list[tuple[float, float]]) -> bool:
    inside = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) or 1e-6) + xi):
            inside = not inside
        j = i
    return inside


def write_imageset(dir_path: Path, name: str, size: int) -> None:
    imageset = dir_path / f"{name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    write_png(imageset / f"{name}.png", size, icon_rgba)
    write_png(imageset / f"{name}@2x.png", size * 2, icon_rgba)
    (imageset / "Contents.json").write_text(
        json.dumps(
            {
                "images": [
                    {"filename": f"{name}.png", "idiom": "mac", "scale": "1x"},
                    {"filename": f"{name}@2x.png", "idiom": "mac", "scale": "2x"},
                ],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
    )


def main() -> None:
    assets_dir = ROOT / "SafariTabTab/Assets.xcassets"
    app_icon_dir = assets_dir / "AppIcon.appiconset"
    app_icon_dir.mkdir(parents=True, exist_ok=True)

    sizes = [16, 32, 128, 256, 512]
    images: list[dict] = []
    for size in sizes:
        filename = f"icon_{size}.png"
        write_png(app_icon_dir / filename, size, icon_rgba)
        images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": "1x",
            "size": f"{size}x{size}",
        })
        if size <= 256:
            filename2x = f"icon_{size * 2}.png"
            write_png(app_icon_dir / filename2x, size * 2, icon_rgba)
            images.append({
                "filename": filename2x,
                "idiom": "mac",
                "scale": "2x",
                "size": f"{size}x{size}",
            })

    (app_icon_dir / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2)
    )

    (assets_dir / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2)
    )

    write_imageset(assets_dir, "MenuBarIcon", 18)

    ext_dir = ROOT / "SafariTabTab Extension"
    write_png(ext_dir / "ToolbarItemIcon.png", 18, icon_rgba)
    write_png(ext_dir / "ToolbarItemIcon@2x.png", 36, icon_rgba)

    print("Icons generated.")


if __name__ == "__main__":
    main()
