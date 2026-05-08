# StreamDock / Stream Deck Icon Pack Template

This template builds an Elgato-style icon pack:

```text
build/
  com.example.my-icons.sdIconPack/
    manifest.json
    icons.json
    icon.png
    license.txt
    icons/
    previews/
  My_Icon_Pack.streamDeckIconPack
```

The `.streamDeckIconPack` file is the distributable zip package. The `.sdIconPack`
folder inside it is what StreamDock reads locally.

## How to Use

1. Put your icon images in `source/icons/`.
2. Optionally put preview images in `source/previews/`.
3. Replace `source/icon.png` with the pack cover image shown in the icon library.
4. Edit `source/meta/pack.json`.
5. Run:

```bash
./scripts/build-iconpack.sh
```

To also install the generated `.sdIconPack` into StreamDock:

```bash
./scripts/build-iconpack.sh --install-streamdock
```

Restart StreamDock after installing.

## Supported Image Types

The local StreamDock installation already contains icon packs using `png`, `jpg`,
`jpeg`, `svg`, and `gif`, so this template includes those extensions.

## Generated Files

`manifest.json` is generated from `source/meta/pack.json`.

`icons.json` is generated from the files in `source/icons/`. Each entry looks like:

```json
{
  "path": "My-Icon.png",
  "name": "My Icon",
  "tags": ["my", "icon"]
}
```

Tags are derived from the filename and any subfolder names.

