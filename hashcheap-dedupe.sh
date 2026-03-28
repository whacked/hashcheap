#!/usr/bin/env bash
# dedupe-from-hashcheap.sh
# Delete files in TARGET_DIR whose size, md5, sha256 match a hashcheap line.

set -euo pipefail
IFS=$'\n\t'

usage(){
  echo "Usage: $0 <hashcheap_file> <target_dir> [--delete]" >&2
  echo "           [--strip-source-prefix <prefix>] [--strip-target-prefix <prefix>]" >&2
  echo "(defaults to dry run; pass --delete to actually remove files)" >&2
  exit 1
}
[ $# -ge 2 ] || usage

HASHFILE="$1"
TARGET_DIR="$2"
shift 2 || true

DRY_RUN=1
STRIP_SOURCE_PREFIX=""
STRIP_TARGET_PREFIX=""
while [ $# -gt 0 ]; do
  case "$1" in
    --delete) DRY_RUN=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --strip-source-prefix) STRIP_SOURCE_PREFIX="$2"; shift ;;
    --strip-target-prefix) STRIP_TARGET_PREFIX="$2"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
  shift
done

[ -f "$HASHFILE" ] || { echo "hash file not found: $HASHFILE" >&2; exit 1; }
[ -d "$TARGET_DIR" ] || { echo "target dir not found: $TARGET_DIR" >&2; exit 1; }

[ $DRY_RUN -eq 1 ] && echo "[DRY-RUN] no deletions will be made."

effective_target="$TARGET_DIR"
[ -n "$STRIP_TARGET_PREFIX" ] && effective_target="${effective_target#$STRIP_TARGET_PREFIX}"
effective_target="${effective_target#/}"

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

  [ -n "$STRIP_SOURCE_PREFIX" ] && relpath="${relpath#$STRIP_SOURCE_PREFIX}"
  relpath="${relpath#/}"

  tgt="$effective_target/$relpath"

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
