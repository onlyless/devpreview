#!/usr/bin/env python3
"""Generate DevPreview.app's ICNS icon using only the Python standard library."""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
ICON_PATH = ROOT / "App" / "Resources" / "AppIcon.icns"
PREVIEW_PATH = Path("/tmp/devpreview-icon-1024.png")


def blend_pixel(pixels: bytearray, width: int, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if x < 0 or y < 0 or x >= width:
        return
    index = (y * width + x) * 4
    if index + 3 >= len(pixels):
        return

    src_r, src_g, src_b, src_a = color
    src_alpha = src_a / 255.0
    dst_r = pixels[index]
    dst_g = pixels[index + 1]
    dst_b = pixels[index + 2]
    dst_alpha = pixels[index + 3] / 255.0

    out_alpha = src_alpha + dst_alpha * (1.0 - src_alpha)
    if out_alpha <= 0.0001:
        return

    pixels[index] = round((src_r * src_alpha + dst_r * dst_alpha * (1.0 - src_alpha)) / out_alpha)
    pixels[index + 1] = round((src_g * src_alpha + dst_g * dst_alpha * (1.0 - src_alpha)) / out_alpha)
    pixels[index + 2] = round((src_b * src_alpha + dst_b * dst_alpha * (1.0 - src_alpha)) / out_alpha)
    pixels[index + 3] = round(out_alpha * 255)


def draw_segment(
    pixels: bytearray,
    width: int,
    p1: tuple[float, float],
    p2: tuple[float, float],
    thickness: float,
    color: tuple[int, int, int, int],
    offset: tuple[float, float] = (0.0, 0.0),
) -> None:
    x1, y1 = p1[0] + offset[0], p1[1] + offset[1]
    x2, y2 = p2[0] + offset[0], p2[1] + offset[1]
    half = thickness / 2.0
    min_x = max(0, int(math.floor(min(x1, x2) - half - 1)))
    max_x = min(width - 1, int(math.ceil(max(x1, x2) + half + 1)))
    min_y = max(0, int(math.floor(min(y1, y2) - half - 1)))
    max_y = min(width - 1, int(math.ceil(max(y1, y2) + half + 1)))

    dx = x2 - x1
    dy = y2 - y1
    length_squared = dx * dx + dy * dy

    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            px = x + 0.5
            py = y + 0.5
            if length_squared == 0:
                t = 0.0
            else:
                t = ((px - x1) * dx + (py - y1) * dy) / length_squared
                t = max(0.0, min(1.0, t))
            nearest_x = x1 + t * dx
            nearest_y = y1 + t * dy
            distance = math.hypot(px - nearest_x, py - nearest_y)
            if distance <= half:
                blend_pixel(pixels, width, x, y, color)


def draw_circle_fill(
    pixels: bytearray,
    width: int,
    center: tuple[float, float],
    radius: float,
    color: tuple[int, int, int, int],
) -> None:
    cx, cy = center
    min_x = max(0, int(math.floor(cx - radius - 1)))
    max_x = min(width - 1, int(math.ceil(cx + radius + 1)))
    min_y = max(0, int(math.floor(cy - radius - 1)))
    max_y = min(width - 1, int(math.ceil(cy + radius + 1)))

    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= radius:
                blend_pixel(pixels, width, x, y, color)


def draw_circle_ring(
    pixels: bytearray,
    width: int,
    center: tuple[float, float],
    radius: float,
    thickness: float,
    color: tuple[int, int, int, int],
) -> None:
    cx, cy = center
    inner = radius - thickness / 2.0
    outer = radius + thickness / 2.0
    min_x = max(0, int(math.floor(cx - outer - 1)))
    max_x = min(width - 1, int(math.ceil(cx + outer + 1)))
    min_y = max(0, int(math.floor(cy - outer - 1)))
    max_y = min(width - 1, int(math.ceil(cy + outer + 1)))

    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            distance = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if inner <= distance <= outer:
                blend_pixel(pixels, width, x, y, color)


def render_master(size: int = 1024, supersample: int = 2) -> bytearray:
    width = size * supersample
    pixels = bytearray(width * width * 4)
    scale = width / 1024.0

    margin = 62 * scale
    radius = 210 * scale
    left = margin
    right = width - margin
    top = margin
    bottom = width - margin

    for y in range(width):
        for x in range(width):
            nearest_x = min(max(x + 0.5, left + radius), right - radius)
            nearest_y = min(max(y + 0.5, top + radius), bottom - radius)
            inside = (
                left <= x + 0.5 <= right
                and top <= y + 0.5 <= bottom
                and math.hypot(x + 0.5 - nearest_x, y + 0.5 - nearest_y) <= radius
            )
            if not inside:
                continue

            t = ((x / width) + (y / width)) * 0.5
            r = round(79 + (8 - 79) * t)
            g = round(70 + (145 - 70) * t)
            b = round(229 + (178 - 229) * t)

            highlight_x = x / width - 0.32
            highlight_y = y / width - 0.18
            highlight = max(0.0, 1.0 - math.hypot(highlight_x, highlight_y) / 0.55)
            r = min(255, r + round(26 * highlight))
            g = min(255, g + round(30 * highlight))
            b = min(255, b + round(34 * highlight))

            index = (y * width + x) * 4
            pixels[index] = r
            pixels[index + 1] = g
            pixels[index + 2] = b
            pixels[index + 3] = 255

    shadow = (7, 12, 30, 70)
    white = (255, 255, 255, 244)
    glass = (255, 255, 255, 26)
    shadow_offset = (0.0, 12.0 * scale)

    left_bracket = [(356.0 * scale, 330.0 * scale), (214.0 * scale, 512.0 * scale), (356.0 * scale, 694.0 * scale)]
    right_bracket = [(668.0 * scale, 330.0 * scale), (810.0 * scale, 512.0 * scale), (668.0 * scale, 694.0 * scale)]
    slash = [(568.0 * scale, 306.0 * scale), (456.0 * scale, 718.0 * scale)]

    for points in (left_bracket, right_bracket):
        for start, end in zip(points, points[1:]):
            draw_segment(pixels, width, start, end, 64 * scale, shadow, shadow_offset)
    draw_segment(pixels, width, slash[0], slash[1], 58 * scale, shadow, shadow_offset)

    for points in (left_bracket, right_bracket):
        for start, end in zip(points, points[1:]):
            draw_segment(pixels, width, start, end, 64 * scale, white)
    draw_segment(pixels, width, slash[0], slash[1], 58 * scale, white)

    lens_center = (747.0 * scale, 706.0 * scale)
    lens_radius = 142.0 * scale
    ring_width = 48.0 * scale
    handle_start = (842.0 * scale, 802.0 * scale)
    handle_end = (900.0 * scale, 860.0 * scale)

    draw_circle_ring(
        pixels,
        width,
        lens_center,
        lens_radius + 6 * scale,
        ring_width + 12 * scale,
        shadow,
    )
    draw_segment(pixels, width, handle_start, handle_end, 56 * scale, shadow, shadow_offset)
    draw_circle_fill(pixels, width, lens_center, lens_radius, glass)
    draw_circle_ring(pixels, width, lens_center, lens_radius, ring_width, white)
    draw_segment(pixels, width, handle_start, handle_end, 56 * scale, white)

    return pixels


def downsample(pixels: bytearray, source_size: int, target_size: int) -> bytes:
    if source_size % target_size != 0:
        raise ValueError("source size must divide evenly")

    factor = source_size // target_size
    area = factor * factor
    output = bytearray(target_size * target_size * 4)

    for target_y in range(target_size):
        for target_x in range(target_size):
            sum_r = 0
            sum_g = 0
            sum_b = 0
            sum_a = 0

            for offset_y in range(factor):
                source_y = target_y * factor + offset_y
                base = (source_y * source_size + target_x * factor) * 4
                for offset_x in range(factor):
                    index = base + offset_x * 4
                    alpha = pixels[index + 3]
                    sum_a += alpha
                    sum_r += pixels[index] * alpha
                    sum_g += pixels[index + 1] * alpha
                    sum_b += pixels[index + 2] * alpha

            out_index = (target_y * target_size + target_x) * 4
            if sum_a == 0:
                output[out_index : out_index + 4] = b"\x00\x00\x00\x00"
            else:
                output[out_index] = round(sum_r / sum_a)
                output[out_index + 1] = round(sum_g / sum_a)
                output[out_index + 2] = round(sum_b / sum_a)
                output[out_index + 3] = round(sum_a / area)

    return bytes(output)


def png_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + chunk_type
        + payload
        + struct.pack(">I", zlib.crc32(chunk_type + payload) & 0xFFFFFFFF)
    )


def write_png(path: Path, size: int, rgba: bytes) -> None:
    raw = bytearray()
    stride = size * 4
    for y in range(size):
        raw.append(0)
        raw.extend(rgba[y * stride : (y + 1) * stride])

    header = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", header)
        + png_chunk(b"IDAT", zlib.compress(bytes(raw), level=9))
        + png_chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def write_icns(path: Path, images: dict[int, bytes]) -> None:
    entries = [
        ("icp4", images[16]),
        ("icp5", images[32]),
        ("icp6", images[64]),
        ("ic07", images[128]),
        ("ic08", images[256]),
        ("ic09", images[512]),
        ("ic10", images[1024]),
        ("ic11", images[32]),
        ("ic12", images[64]),
        ("ic13", images[256]),
        ("ic14", images[512]),
    ]

    body = bytearray()
    for kind, png in entries:
        body.extend(kind.encode("ascii"))
        body.extend(struct.pack(">I", len(png) + 8))
        body.extend(png)

    path.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + bytes(body))


def main() -> None:
    master_size = 2048
    master = render_master(supersample=2)

    images: dict[int, bytes] = {}
    for size in (16, 32, 64, 128, 256, 512, 1024):
        images[size] = downsample(master, master_size, size)

    write_png(PREVIEW_PATH, 1024, images[1024])
    ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    write_icns(ICON_PATH, images)
    print(f"Wrote {ICON_PATH} ({ICON_PATH.stat().st_size} bytes)")
    print(f"Wrote preview {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
