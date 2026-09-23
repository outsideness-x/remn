"""Lays a faint paper tooth over the rendered icons and writes opaque sRGB PNGs."""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

STRENGTH = {"AppIcon": 3.2, "AppIcon-Dark": 2.4, "AppIcon-Tinted": 0.0}


def grain(size: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    tooth = rng.normal(0, 1, (size, size))
    # Soft, uneven pulp: coarse noise blown up and smoothed.
    coarse = Image.fromarray(((rng.normal(0, 1, (size // 16, size // 16)) + 4) * 32).clip(0, 255).astype(np.uint8))
    pulp = np.asarray(coarse.resize((size, size), Image.BICUBIC), dtype=np.float32) / 32 - 4
    return tooth * 0.8 + pulp * 0.35


def main(folder: Path) -> None:
    for path in sorted(folder.glob("AppIcon*.png")):
        variant = path.stem
        image = Image.open(path).convert("RGB")
        pixels = np.asarray(image, dtype=np.float32)
        strength = STRENGTH.get(variant, 0.0)
        if strength:
            pixels += grain(image.width, seed=17)[..., None] * strength
        Image.fromarray(pixels.clip(0, 255).astype(np.uint8)).save(path, optimize=True)
        print(f"grained {path.name}")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
