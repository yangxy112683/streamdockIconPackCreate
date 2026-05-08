# streamdockIconPackCreate

This repository contains a reusable template and build script for creating StreamDock / Stream Deck icon packs.

The generated package follows the Elgato-style structure:

```text
*.streamDeckIconPack
└── *.sdIconPack/
    ├── manifest.json
    ├── icons.json
    ├── icon.png or icon.svg
    ├── license.txt
    ├── icons/
    └── previews/
```

## Usage

1. Put icon images in `iconpack-template/source/icons/`.
2. Optionally put preview images in `iconpack-template/source/previews/`.
3. Edit `iconpack-template/source/meta/pack.json`.
4. Run the build script:

```bash
cd iconpack-template
./scripts/build-iconpack.sh
```

The build output is written to `iconpack-template/build/`.

To install the generated `.sdIconPack` into the local StreamDock icon library:

```bash
cd iconpack-template
./scripts/build-iconpack.sh --install-streamdock
```

Restart StreamDock after installation.

## Template Files

- `iconpack-template/source/meta/pack.json`: package metadata used to generate `manifest.json`.
- `iconpack-template/source/icons/`: source icon images.
- `iconpack-template/source/previews/`: optional preview images.
- `iconpack-template/scripts/build-iconpack.sh`: build script that generates `manifest.json`, `icons.json`, the `.sdIconPack` directory, and the `.streamDeckIconPack` distributable.

## Notes

This repository stores the template and source assets only. Generated build output, local logs, and Playwright debug files are ignored by git.

