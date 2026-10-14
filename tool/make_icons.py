"""Renders the Planetarium launcher icon set (adaptive + legacy + web).

The artwork is the app's astronaut helmet with Mars in the visor, drawn
procedurally with numpy so it can be regenerated without design tools:

    python3 tool/make_icons.py
"""

import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
WEB = os.path.join(ROOT, 'web')
N = 1296  # 108 units * 12 px, supersampled


def grid(n):
    y, x = np.mgrid[0:n, 0:n].astype(np.float64)
    u = n / 108.0
    return x / u, y / u  # coordinates in adaptive-icon units (0..108)


def smooth(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def value_noise(x, y, scale, seed):
    rng = np.random.default_rng(seed)
    g = rng.random((64, 64))
    xs, ys = x * scale, y * scale
    xi, yi = np.floor(xs).astype(int) % 63, np.floor(ys).astype(int) % 63
    xf, yf = xs - np.floor(xs), ys - np.floor(ys)
    xf, yf = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
    a, b = g[yi, xi], g[yi, xi + 1]
    c, d = g[yi + 1, xi], g[yi + 1, xi + 1]
    return (a * (1 - xf) + b * xf) * (1 - yf) + (c * (1 - xf) + d * xf) * yf


def fbm(x, y, scale, seed):
    s, amp = 0, 0.5
    for i in range(4):
        s = s + amp * value_noise(x, y, scale * (2 ** i), seed + i)
        amp *= 0.5
    return s


def over(dst, rgb, a):
    a = a[..., None]
    dst[..., :3] = rgb * a + dst[..., :3] * (1 - a)
    dst[..., 3:] = a + dst[..., 3:] * (1 - a)


def background():
    x, y = grid(N)
    img = np.zeros((N, N, 4))
    d = np.hypot(x - 40, y - 34) / 90
    top = np.array([0.16, 0.15, 0.17])
    bot = np.array([0.02, 0.02, 0.025])
    t = np.clip(d, 0, 1)[..., None]
    img[..., :3] = top * (1 - t) + bot * t
    img[..., 3] = 1
    # Warm sun glow, top right.
    glow = np.exp(-np.hypot(x - 100, y - 8) / 22)[..., None]
    img[..., :3] += glow * np.array([0.55, 0.3, 0.08]) * 0.8
    rng = np.random.default_rng(7)
    for _ in range(60):
        sx, sy = rng.random() * 108, rng.random() * 108
        r = 0.18 + rng.random() ** 3 * 0.45
        b = 0.35 + rng.random() * 0.65
        m = smooth(r + 0.1, r - 0.1, np.hypot(x - sx, y - sy))
        img[..., :3] += m[..., None] * b
    img[..., :3] = np.clip(img[..., :3], 0, 1)
    return img


def helmet(mono=False):
    x, y = grid(N)
    img = np.zeros((N, N, 4))
    cx, cy, R = 54.0, 50.0, 26.0
    aa = 0.12

    def sphere_shade(px, py, pcx, pcy, pr, light=(-0.55, -0.6, 0.58)):
        nx, ny = (px - pcx) / pr, (py - pcy) / pr
        nz = np.sqrt(np.clip(1 - nx * nx - ny * ny, 0, 1))
        L = np.array(light) / np.linalg.norm(light)
        lam = np.clip(nx * L[0] + ny * L[1] + nz * L[2], 0, 1)
        return nx, ny, nz, lam

    white = np.array([1.0, 1.0, 1.0])

    # Neck ring.
    ring = smooth(1 + aa, 1 - aa, np.hypot((x - 54) / 19, (y - 77.5) / 4.6))
    shade = 0.62 + 0.38 * smooth(70, 40, x)
    over(img, white * (1 if mono else shade[..., None]), ring)

    # Ear pieces.
    for ex in (cx - R - 1.2, cx + R + 1.2):
        d = np.maximum(np.abs(x - ex) - 1.1, 0) ** 2 + np.maximum(np.abs(y - 53) - 4.5, 0) ** 2
        m = smooth(1.3 + aa, 1.3 - aa, np.sqrt(d))
        over(img, white * (1 if mono else 0.8), m)

    # Shell.
    d = np.hypot(x - cx, y - cy)
    shell = smooth(R + aa, R - aa, d)
    _, _, nz, lam = sphere_shade(x, y, cx, cy, R)
    tone = 0.64 + 0.36 * lam + 0.08 * nz
    over(img, white * (1 if mono else np.clip(tone, 0, 1)[..., None]), shell)

    # Visor.
    vx, vy, va, vb = cx, cy + 3.5, 19.0, 16.0
    vd = np.hypot((x - vx) / va, (y - vy) / vb)
    rim = smooth(1.16 + 0.01, 1.16 - 0.01, vd)
    if mono:
        over(img, np.zeros(3), smooth(1.0 + 0.01, 1.0 - 0.01, vd))
        # Keep the planet as a white dome in the monochrome layer.
        pd = np.hypot(x - vx, y - (vy + 15))
        dome = smooth(13.5 + aa, 13.5 - aa, pd) * smooth(1.0 + 0.01, 1.0 - 0.01, vd)
        over(img, white, dome)
        img[..., 3] = img[..., 3] * (img[..., 0] > 0.5)
        return img
    metal = 0.55 + 0.4 * smooth(-1, 1, np.sin(np.arctan2(y - vy, x - vx) * 1.0 + 2.4))
    over(img, metal[..., None] * white, rim)
    visor = smooth(1.0 + 0.012, 1.0 - 0.012, vd)
    glass = np.clip(0.03 + 0.07 * (1 - vd), 0, 1)
    over(img, glass[..., None] * np.array([1, 1, 1.08]), visor)

    # Stars in the visor.
    rng = np.random.default_rng(3)
    for _ in range(14):
        sx = vx + (rng.random() - 0.5) * 30
        sy = vy - 13 + rng.random() * 14
        r = 0.16 + rng.random() * 0.22
        m = smooth(r + 0.08, r - 0.08, np.hypot(x - sx, y - sy)) * visor
        over(img, white * 0.9, m)

    # Mars dome.
    px, py, pr = vx, vy + 15.0, 13.5
    pd = np.hypot(x - px, y - py)
    planet = smooth(pr + aa, pr - aa, pd) * visor
    nx, ny, nz, lam = sphere_shade(x, y, px, py, pr, light=(0.35, -0.85, 0.45))
    f = fbm(x, y, 0.22, 11)
    rust = np.array([0.80, 0.40, 0.18])
    dark = np.array([0.42, 0.18, 0.08])
    k = smooth(0.42, 0.62, f)[..., None]
    col = rust * (1 - k) + dark * k
    col = col * (0.85 + 0.3 * fbm(x, y, 0.9, 21))[..., None]
    light = (0.06 + 0.94 * lam ** 0.85)[..., None]
    col = col * light
    fres = ((1 - nz) ** 2.5)[..., None]
    col = col + fres * np.array([1.0, 0.65, 0.45]) * 0.5 * smooth(-0.2, 0.6, -ny)[..., None]
    over(img, np.clip(col, 0, 1), planet)

    # Glass highlight arc.
    hl = smooth(1.0, 0.92, vd) * smooth(0.82, 0.9, np.hypot((x - vx - 1.5) / va, (y - vy - 1.8) / vb))
    hl = hl * smooth(vy + 4, vy - 12, y) * smooth(vx + 8, vx - 12, x)
    over(img, white, hl * 0.45)
    glint = smooth(1.6, 0.0, np.hypot(x - (vx + 12), y - (vy - 9))) * visor
    over(img, white, glint * 0.6)
    return img


def to_image(arr, size):
    a = np.clip(arr, 0, 1)
    rgb = a[..., :3] * a[..., 3:]  # premultiply for clean downsampling
    im = Image.fromarray((np.concatenate([rgb, a[..., 3:]], -1) * 255).astype(np.uint8), 'RGBA')
    im = im.resize((size, size), Image.LANCZOS)
    p = np.asarray(im).astype(np.float64) / 255
    alpha = p[..., 3:]
    p[..., :3] = np.where(alpha > 0, p[..., :3] / np.maximum(alpha, 1e-6), 0)
    return Image.fromarray((np.clip(p, 0, 1) * 255).astype(np.uint8), 'RGBA')


def flatten(fg, bg):
    out = bg.copy()
    a = fg[..., 3:]
    out[..., :3] = fg[..., :3] * a + bg[..., :3] * (1 - a)
    out[..., 3] = 1
    return out


def circle_mask(arr):
    x, y = grid(N)
    m = smooth(54.2, 53.8, np.hypot(x - 54, y - 54))
    out = arr.copy()
    out[..., 3] *= m
    return out


def crop_legacy(arr):
    # Legacy icons show the central 72/108 of the adaptive canvas, upscaled.
    lo, hi = int(N * 18 / 108), int(N * 90 / 108)
    sub = arr[lo:hi, lo:hi]
    im = Image.fromarray((np.clip(sub, 0, 1) * 255).astype(np.uint8), 'RGBA').resize((N, N), Image.LANCZOS)
    return np.asarray(im).astype(np.float64) / 255


def main():
    bg = background()
    fg = helmet()
    mono = helmet(mono=True)
    full = flatten(fg, bg)

    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, k in densities.items():
        d = os.path.join(RES, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        adaptive = int(108 * k)
        legacy = int(48 * k)
        to_image(fg, adaptive).save(os.path.join(d, 'ic_launcher_foreground.png'))
        to_image(bg, adaptive).save(os.path.join(d, 'ic_launcher_background.png'))
        to_image(mono, adaptive).save(os.path.join(d, 'ic_launcher_monochrome.png'))
        leg = crop_legacy(full)
        to_image(rounded(leg), legacy).save(os.path.join(d, 'ic_launcher.png'))
        to_image(circle_mask(leg), legacy).save(os.path.join(d, 'ic_launcher_round.png'))

    # Splash (Android 12+ shows the icon inside a 160dp circle; use 288px fg).
    for name, k in densities.items():
        d = os.path.join(RES, f'drawable-{name}')
        os.makedirs(d, exist_ok=True)
        to_image(circle_mask(full), int(160 * k)).save(os.path.join(d, 'splash_icon.png'))

    to_image(circle_mask(full), 512).save(os.path.join(ROOT, 'assets', 'icon.png'))
    icons = os.path.join(WEB, 'icons')
    to_image(rounded(crop_legacy(full)), 192).save(os.path.join(icons, 'Icon-192.png'))
    to_image(rounded(crop_legacy(full)), 512).save(os.path.join(icons, 'Icon-512.png'))
    to_image(full, 192).save(os.path.join(icons, 'Icon-maskable-192.png'))
    to_image(full, 512).save(os.path.join(icons, 'Icon-maskable-512.png'))
    to_image(rounded(crop_legacy(full)), 32).save(os.path.join(WEB, 'favicon.png'))


def rounded(arr, radius=0.22):
    n = arr.shape[0]
    y, x = np.mgrid[0:n, 0:n].astype(np.float64) / n
    r = radius
    dx = np.maximum(np.abs(x - 0.5) - (0.5 - r), 0)
    dy = np.maximum(np.abs(y - 0.5) - (0.5 - r), 0)
    d = np.hypot(dx, dy)
    m = smooth(r + 0.002, r - 0.002, d)
    out = arr.copy()
    out[..., 3] *= m
    return out


if __name__ == '__main__':
    main()
