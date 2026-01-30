#!/usr/bin/env bash

# Check if a directory was provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

directory=$1

# Check if the provided directory exists
if [ ! -d "$directory" ]; then
    echo "Error: Directory does not exist."
    exit 1
fi

# Number of cores
num_cores=$(nproc)

if false; then
# Header for the output
echo "size,md5,sha256,filepath"
else

# print hashdeep header
echo '%%%% HASHCHEAP-0.0'
echo '%%%% size,md5,sha256,filename'
echo "## Invoked from: $PWD"
echo "## $ hashdeep -l -e -r $PWD"
echo "##" 

fi

# Function to calculate hashes
function hash_file {
    filepath="$1"
    filesize=$(stat --printf="%s" "$filepath")
    md5hash=$(md5sum "$filepath" | cut -d' ' -f1)
    sha256hash=$(sha256sum "$filepath" | cut -d' ' -f1)
    # echo "$filesize,$md5hash,$sha256hash,\"$filepath\""
    # hashdeep compat
    echo "$filesize,$md5hash,$sha256hash,$filepath"
}

# Export function to use in xargs
export -f hash_file

# Find all files and apply hash_file function in parallel
find "$directory" -type f -print0 | xargs -0 -n 1 -P $num_cores -I {} bash -c 'hash_file "$@"' _ {}
