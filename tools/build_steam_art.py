#!/usr/bin/env python3
"""Build the Lobster Clicker Steam capsule and library image family."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "steam" / "assets" / "source"
FINAL = ROOT / "steam" / "assets" / "final"
FONT = ROOT / "assets" / "fonts" / "bungee" / "Bungee-Regular.ttf"


def cover(image: Image.Image, size: tuple[int, int], focus_x: float = 0.5, focus_y: float = 0.5) -> Image.Image:
    target_w, target_h = size
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = round((resized.width - target_w) * focus_x)
    top = round((resized.height - target_h) * focus_y)
    return resized.crop((left, top, left + target_w, top + target_h))


def logo(width: int = 1280, height: int = 330) -> Image.Image:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    label = "LOBSTER CLICKER"
    size = 180
    while True:
        font = ImageFont.truetype(str(FONT), size)
        bounds = draw.textbbox((0, 0), label, font=font, stroke_width=0)
        if bounds[2] - bounds[0] <= width - 70:
            break
        size -= 2
    x = (width - (bounds[2] - bounds[0])) // 2
    y = (height - (bounds[3] - bounds[1])) // 2 - bounds[1] - 10
    draw.text((x + 8, y + 13), label, font=font, fill="#1DD9F2", stroke_width=14, stroke_fill="#071725")
    draw.text((x, y), label, font=font, fill="#FF725E", stroke_width=13, stroke_fill="#071725")
    draw.line((120, height - 32, width - 120, height - 32), fill="#FFD166", width=9)
    return image


def composite_capsule(source: Image.Image, size: tuple[int, int], logo_scale: float, y_ratio: float, portrait: bool = False) -> Image.Image:
    base = cover(source, size, 0.5, 0.46 if portrait else 0.5).convert("RGBA")
    base = ImageEnhance.Contrast(base).enhance(1.05)
    shade = Image.new("RGBA", size, (0, 0, 0, 0))
    shade_draw = ImageDraw.Draw(shade)
    y0 = int(size[1] * max(0.0, y_ratio - 0.25))
    for y in range(y0, size[1]):
        alpha = int(160 * (y - y0) / max(1, size[1] - y0))
        shade_draw.line((0, y, size[0], y), fill=(3, 12, 24, alpha))
    base = Image.alpha_composite(base, shade)
    title = logo()
    target_w = int(size[0] * logo_scale)
    target_h = round(title.height * target_w / title.width)
    title = title.resize((target_w, target_h), Image.Resampling.LANCZOS)
    x = (size[0] - target_w) // 2
    y = min(size[1] - target_h - max(8, size[1] // 35), int(size[1] * y_ratio))
    base.alpha_composite(title, (x, y))
    return base.convert("RGB")


def save(image: Image.Image, name: str) -> None:
    path = FINAL / name
    image.save(path, optimize=True)
    print(f"{path.relative_to(ROOT)} {image.width}x{image.height}")


def main() -> None:
    FINAL.mkdir(parents=True, exist_ok=True)
    wide = Image.open(SOURCE / "key-art-wide.png").convert("RGB")
    portrait = Image.open(SOURCE / "key-art-portrait.png").convert("RGB")

    logo_image = logo()
    logo_image.save(FINAL / "library_logo.png", optimize=True)
    print(f"steam/assets/final/library_logo.png {logo_image.width}x{logo_image.height}")

    save(composite_capsule(wide, (920, 430), 0.92, 0.67), "header_capsule.png")
    save(composite_capsule(wide, (462, 174), 0.95, 0.59), "small_capsule.png")
    save(composite_capsule(wide, (1232, 706), 0.86, 0.70), "main_capsule.png")
    save(composite_capsule(portrait, (748, 896), 0.92, 0.72, True), "vertical_capsule.png")
    save(composite_capsule(portrait, (600, 900), 0.94, 0.74, True), "library_capsule.png")
    save(composite_capsule(wide, (920, 430), 0.92, 0.67), "library_header.png")

    save(cover(wide, (3840, 1240), 0.5, 0.50), "library_hero.png")
    background = cover(wide, (1438, 810), 0.5, 0.52)
    background = ImageEnhance.Brightness(background).enhance(0.62)
    background = background.filter(ImageFilter.GaussianBlur(radius=1.2))
    save(background, "page_background.png")


if __name__ == "__main__":
    main()
