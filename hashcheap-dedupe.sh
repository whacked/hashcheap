#!/usr/bin/env bash
# dedupe-from-hashcheap.sh
# Delete files in TARGET_DIR whose size, md5, sha256 match a hashcheap line.

set -euo pipefail
IFS=$'\n\t'

usage(){ echo "Usage: $0 <hashcheap_file> <target_dir> [--force] [--dry-run]"; exit 1; }
[ $# -ge 2 ] || usage

HASHFILE="$1"
TARGET_DIR="$2"
shift 2 || true

DRY_RUN=1
while [ $# -gt 0 ]; do
  case "$1" in
    --force) DRY_RUN=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
  shift
done

[ -f "$HASHFILE" ] || { echo "hash file not found: $HASHFILE" >&2; exit 1; }
[ -d "$TARGET_DIR" ] || { echo "target dir not found: $TARGET_DIR" >&2; exit 1; }

[ $DRY_RUN -eq 1 ] && echo "[DRY-RUN] no deletions will be made."

deleted_files=0
deleted_bytes=0

while IFS= read -r line; do
  # skip headers and blanks
  [[ "$line" =~ ^(%%%%|##|[[:space:]]*$) ]] && continue

  IFS=',' read -r sz md5 sha relpath <<< "$line"

  # basic validation
  [[ "$sz" =~ ^[0-9]+$ ]] || { echo "[SKIP] bad size: $line" >&2; continue; }
  [[ "$md5" =~ ^[0-9a-fA-F]{32}$ ]] || { echo "[SKIP] bad md5: $line" >&2; continue; }
  [[ "$sha" =~ ^[0-9a-fA-F]{64}$ ]] || { echo "[SKIP] bad sha256: $line" >&2; continue; }
  [ -n "${relpath:-}" ] || { echo "[SKIP] missing path: $line" >&2; continue; }

  tgt="$TARGET_DIR/$relpath"

  if [ ! -f "$tgt" ]; then
    echo "[MISSING] $tgt" >&2
    continue
  fi

  # size
  size=$(stat -c%s -- "$tgt" 2>/dev/null || stat --format=%s -- "$tgt")
  # hashes
  md5c=$(md5sum -- "$tgt" | awk '{print $1}')
  shac=$(sha256sum -- "$tgt" | awk '{print $1}')

  if [ "$size" = "$sz" ] && [ "$md5c" = "$md5" ] && [ "$shac" = "$sha" ]; then
    if [ $DRY_RUN -eq 1 ]; then
      echo "[MATCH] $tgt"
    else
      if rm -f -- "$tgt"; then
        echo "[DELETED] $tgt ($sha)"
        deleted_files=$((deleted_files+1))
        deleted_bytes=$((deleted_bytes+size))
      else
        echo "[ERROR] failed to delete: $tgt" >&2
      fi
    fi
  else
    echo "[DIFF] $tgt" >&2
  fi
done < "$HASHFILE"

[ $DRY_RUN -eq 0 ] && {
  echo "Deleted files: $deleted_files"
  echo "Deleted bytes: $deleted_bytes"
}

