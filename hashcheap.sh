#!/usr/bin/env bash

# Number of cores
num_cores=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)

# print hashdeep header
echo '%%%% HASHCHEAP-0.0'
echo '%%%% size,md5,sha256,filename'
echo "## Invoked from: $PWD"
echo "## $ hashdeep -l -e -r $PWD"
echo "##"

# Function to calculate hashes
function hash_file {
    filepath="$1"
    filesize=$(stat --printf="%s" "$filepath")
    md5hash=$(md5sum "$filepath" | cut -d' ' -f1)
    sha256hash=$(sha256sum "$filepath" | cut -d' ' -f1)
    # hashdeep compat
    echo "$filesize,$md5hash,$sha256hash,$filepath"
}

# Export function to use in xargs
export -f hash_file

# --- Argument parsing ---
MAXDEPTH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --maxdepth) MAXDEPTH="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; echo "Usage: $0 [--maxdepth <n>] <directory>" >&2; exit 1 ;;
    *) break ;;
  esac
done

if [ $# -ne 1 ]; then
  echo "Usage: $0 [--maxdepth <n>] <directory>" >&2
  exit 1
fi

directory="$1"

if [ ! -d "$directory" ]; then
    echo "Error: Directory does not exist." >&2
    exit 1
fi

find "$directory" ${MAXDEPTH:+-maxdepth "$MAXDEPTH"} -type f -print0 \
  | xargs -0 -P "$num_cores" -I {} bash -c 'hash_file "$@"' _ {}
