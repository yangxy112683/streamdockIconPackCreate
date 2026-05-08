#!/usr/bin/env python3

import argparse
import json
from pathlib import Path

from PIL import Image, ImageOps


DEFAULT_STREAMDOCK_ROOT = Path("/Users/dawn80s/Library/Application Support/HotSpot/StreamDock")
DEFAULT_CONFIG_PATH = (
    DEFAULT_STREAMDOCK_ROOT
    / "logs"
    / "scripts"
    / "icon-pack-configs"
    / "cn-sites.json"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a StreamDock icon pack from a JSON config."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG_PATH,
        help="Path to icon pack config JSON.",
    )
    parser.add_argument(
        "--streamdock-root",
        type=Path,
        default=DEFAULT_STREAMDOCK_ROOT,
        help="StreamDock root directory.",
    )
    return parser.parse_args()


def load_config(config_path: Path) -> dict:
    return json.loads(config_path.read_text(encoding="utf-8"))


def resolve_path(path_value: str, config_dir: Path, streamdock_root: Path) -> Path:
    path = Path(path_value).expanduser()
    if path.is_absolute():
        return path
    return (config_dir / path).resolve() if (config_dir / path).exists() else (streamdock_root / path).resolve()


def ensure_dirs(pack_root: Path, preview_root: Path) -> Path:
    pack_icons_dir = pack_root / "icons"
    pack_icons_dir.mkdir(parents=True, exist_ok=True)
    preview_root.mkdir(parents=True, exist_ok=True)
    return pack_icons_dir


def render_icon(source_path: Path, target_size: tuple[int, int], canvas_size: tuple[int, int]) -> Image.Image:
    image = Image.open(source_path).convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox:
        image = image.crop(bbox)

    scale = min(target_size[0] / image.width, target_size[1] / image.height)
    resized = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.LANCZOS,
    )

    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (canvas_size[0] - resized.width) // 2
    y = (canvas_size[1] - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def write_manifest(pack_root: Path, manifest: dict) -> None:
    (pack_root / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_icons_json(pack_root: Path, icons: list[dict]) -> None:
    output = [
        {
            "path": f"{icon['name']}.png",
            "name": icon["name"],
            "tags": icon.get("tags", []),
        }
        for icon in icons
    ]
    (pack_root / "icons.json").write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def write_cover_icon(pack_root: Path, pack_icons_dir: Path, cover_config: dict, icon_names: list[str]) -> None:
    size = tuple(cover_config.get("size", [256, 256]))
    background = tuple(cover_config.get("background", [24, 24, 28, 255]))
    tile_size = tuple(cover_config.get("tile_size", [104, 104]))
    tile_background = tuple(cover_config.get("tile_background", [44, 44, 50, 255]))
    tile_fit = tuple(cover_config.get("tile_fit", [96, 96]))
    center_fit = tuple(cover_config.get("center_fit", [88, 88]))
    positions = [tuple(item) for item in cover_config.get("positions", [])]
    center_icon_name = cover_config.get("center_icon")

    cover = Image.new("RGBA", size, background)

    tiled_names = [name for name in icon_names if name != center_icon_name]
    for position, name in zip(positions, tiled_names):
        tile = Image.new("RGBA", tile_size, tile_background)
        source = Image.open(pack_icons_dir / f"{name}.png").convert("RGBA")
        fitted = ImageOps.contain(source, tile_fit, Image.LANCZOS)
        tile.alpha_composite(
            fitted,
            ((tile.width - fitted.width) // 2, (tile.height - fitted.height) // 2),
        )
        cover.alpha_composite(tile, position)

    if center_icon_name:
        center_icon = Image.open(pack_icons_dir / f"{center_icon_name}.png").convert("RGBA")
        center_icon = ImageOps.contain(center_icon, center_fit, Image.LANCZOS)
        cover.alpha_composite(
            center_icon,
            ((cover.width - center_icon.width) // 2, (cover.height - center_icon.height) // 2),
        )

    cover.save(pack_root / "icon.png")


def main() -> None:
    args = parse_args()
    streamdock_root = args.streamdock_root.resolve()
    config_path = args.config.resolve()
    config_dir = config_path.parent
    config = load_config(config_path)

    pack_root = resolve_path(config["pack_root"], config_dir, streamdock_root)
    preview_root = resolve_path(config["preview_root"], config_dir, streamdock_root)
    pack_icons_dir = ensure_dirs(pack_root, preview_root)

    canvas_size = tuple(config.get("canvas_size", [144, 144]))
    icons = config["icons"]

    for icon in icons:
        source_path = resolve_path(icon["source"], config_dir, streamdock_root)
        target_size = tuple(icon["target_size"])
        rendered = render_icon(source_path, target_size, canvas_size)
        rendered.save(pack_icons_dir / f"{icon['name']}.png")
        rendered.save(preview_root / f"{icon['name']}-pack.png")

    write_manifest(pack_root, config["manifest"])
    write_icons_json(pack_root, icons)
    write_cover_icon(
        pack_root,
        pack_icons_dir,
        config["cover"],
        [icon["name"] for icon in icons],
    )
    print(f"Generated icon pack at {pack_root}")


if __name__ == "__main__":
    main()
