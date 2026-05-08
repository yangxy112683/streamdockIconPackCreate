#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${ROOT_DIR}/source"
META_FILE="${SOURCE_DIR}/meta/pack.json"
BUILD_DIR="${ROOT_DIR}/build"
INSTALL_STREAMDOCK=0

for arg in "$@"; do
  case "$arg" in
    --install-streamdock)
      INSTALL_STREAMDOCK=1
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

need_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

need_command jq
need_command zip

if [[ ! -f "$META_FILE" ]]; then
  printf 'Missing metadata file: %s\n' "$META_FILE" >&2
  exit 1
fi

PACK_DIR_NAME="$(jq -r '.packDirectory' "$META_FILE")"
PACK_NAME="$(jq -r '.name' "$META_FILE")"
PACK_ICON="$(jq -r '.icon // "icon.png"' "$META_FILE")"
PACK_LICENSE="$(jq -r '.license // "license.txt"' "$META_FILE")"

if [[ "$PACK_DIR_NAME" != *.sdIconPack ]]; then
  printf 'packDirectory must end with .sdIconPack: %s\n' "$PACK_DIR_NAME" >&2
  exit 1
fi

if [[ "$PACK_NAME" == "null" || -z "$PACK_NAME" ]]; then
  printf 'source/meta/pack.json must contain a non-empty name.\n' >&2
  exit 1
fi

PACK_DIR="${BUILD_DIR}/${PACK_DIR_NAME}"
PACKAGE_NAME="$(printf '%s' "$PACK_NAME" | tr -cs '[:alnum:]' '_' | sed 's/^_*//; s/_*$//')"
PACKAGE_FILE="${BUILD_DIR}/${PACKAGE_NAME}.streamDeckIconPack"

rm -rf "$PACK_DIR" "$PACKAGE_FILE"
mkdir -p "$PACK_DIR/icons" "$PACK_DIR/previews"

if [[ ! -f "${SOURCE_DIR}/${PACK_ICON}" ]]; then
  printf 'Missing pack cover image: %s\n' "${SOURCE_DIR}/${PACK_ICON}" >&2
  printf 'Put a cover image at source/%s or update source/meta/pack.json.\n' "$PACK_ICON" >&2
  exit 1
fi

cp "${SOURCE_DIR}/${PACK_ICON}" "${PACK_DIR}/${PACK_ICON}"

if [[ -f "${SOURCE_DIR}/meta/${PACK_LICENSE}" ]]; then
  cp "${SOURCE_DIR}/meta/${PACK_LICENSE}" "${PACK_DIR}/${PACK_LICENSE}"
fi

find "${SOURCE_DIR}/icons" -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.svg' -o -iname '*.gif' \) \
  -print0 | while IFS= read -r -d '' icon_file; do
    rel_path="${icon_file#${SOURCE_DIR}/icons/}"
    mkdir -p "${PACK_DIR}/icons/$(dirname "$rel_path")"
    cp "$icon_file" "${PACK_DIR}/icons/${rel_path}"
  done

icon_count="$(find "${PACK_DIR}/icons" -type f | wc -l | tr -d ' ')"
if [[ "$icon_count" == "0" ]]; then
  printf 'No icon images found in %s\n' "${SOURCE_DIR}/icons" >&2
  exit 1
fi

if [[ -d "${SOURCE_DIR}/previews" ]]; then
  find "${SOURCE_DIR}/previews" -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.svg' -o -iname '*.gif' \) \
    -print0 | while IFS= read -r -d '' preview_file; do
      rel_path="${preview_file#${SOURCE_DIR}/previews/}"
      mkdir -p "${PACK_DIR}/previews/$(dirname "$rel_path")"
      cp "$preview_file" "${PACK_DIR}/previews/${rel_path}"
    done
fi

jq '{
  Name: .name,
  Version: .version,
  Description: .description,
  Author: .author,
  URL: .url,
  Icon: (.icon // "icon.png"),
  License: (.license // "license.txt")
} + (if .streamdeckId then {StreamdeckID: .streamdeckId} else {} end)' \
  "$META_FILE" > "${PACK_DIR}/manifest.json"

find "${PACK_DIR}/icons" -type f | sort | while IFS= read -r file; do
  rel_path="${file#${PACK_DIR}/icons/}"
  base_name="$(basename "$rel_path")"
  name_without_ext="${base_name%.*}"
  display_name="$(printf '%s' "$name_without_ext" | sed 's/[_-]/ /g; s/  */ /g')"
  tag_source="$(printf '%s' "${rel_path%.*}" | tr '/_-' '   ' | tr '[:upper:]' '[:lower:]')"
  tags_json="$(printf '%s\n' $tag_source | awk 'length($0) > 1' | sort -u | jq -R . | jq -s .)"
  jq -n \
    --arg path "$rel_path" \
    --arg name "$display_name" \
    --argjson tags "$tags_json" \
    '{path: $path, name: $name, tags: $tags}'
done | jq -s . > "${PACK_DIR}/icons.json"

(
  cd "$BUILD_DIR"
  zip -qr "$PACKAGE_FILE" "$PACK_DIR_NAME"
)

printf 'Built icon pack directory: %s\n' "$PACK_DIR"
printf 'Built distributable package: %s\n' "$PACKAGE_FILE"
printf 'Icon count: %s\n' "$icon_count"

if [[ "$INSTALL_STREAMDOCK" == "1" ]]; then
  STREAMDOCK_ICONS_DIR="${HOME}/Library/Application Support/HotSpot/StreamDock/icons"
  TARGET_DIR="${STREAMDOCK_ICONS_DIR}/${PACK_DIR_NAME}"
  mkdir -p "$STREAMDOCK_ICONS_DIR"
  if [[ -e "$TARGET_DIR" ]]; then
    BACKUP_DIR="${TARGET_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$TARGET_DIR" "$BACKUP_DIR"
    printf 'Backed up existing pack: %s\n' "$BACKUP_DIR"
  fi
  cp -R "$PACK_DIR" "$TARGET_DIR"
  printf 'Installed to StreamDock: %s\n' "$TARGET_DIR"
fi

