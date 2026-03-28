import argparse
import os

def read_files_data(filepath, strip_path):
    """Read file data from the given CSV file and strip the base path."""
    files_data = {}
    with open(filepath, encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n')
            if not line or line.startswith('%%') or line.startswith('##'):
                continue
            parts = line.split(',', 3)
            if len(parts) < 4:
                continue
            size, md5, sha256, path = parts
            normalized_path = os.path.relpath(path, strip_path)
            files_data[(normalized_path, size, md5, sha256)] = path
    return files_data

def find_duplicates(base_data, comparison_data):
    """Find duplicates in the comparison data based on base data."""
    duplicates = set(base_data.keys()) & set(comparison_data.keys())
    return [comparison_data[dup] for dup in duplicates]

def delete_files(files):
    """Delete the specified files."""
    for file in files:
        os.remove(file)
        print(f"Deleted: {file}")

def main():
    parser = argparse.ArgumentParser(description="Remove duplicate files from comparison directory.")
    parser.add_argument("base_file", help="CSV file with the base directory data")
    # parser.add_argument("base_dir", help="Base directory for the base file list to strip from paths", default=".")
    parser.add_argument("comparison_file", help="CSV file with the comparison directory data")
    # parser.add_argument("comparison_dir", help="Base directory for the comparison file list to strip from paths", default=".")
    parser.add_argument("--delete", action="store_true", help="Actually delete the duplicate files (default is dry run)")
    args = parser.parse_args()

    # Read files data
    base_dir = "."
    comparison_dir = "."
    base_data = read_files_data(args.base_file, base_dir)
    comparison_data = read_files_data(args.comparison_file, comparison_dir)

    # Find duplicates
    duplicates = find_duplicates(base_data, comparison_data)

    if duplicates:
        print(f"Found {len(duplicates)} duplicates out of {len(base_data)} base files.")
        if args.delete:
            delete_files(duplicates)
        else:
            print("Dry run mode. No files deleted. To delete files, run with '--delete'.")
            for file in duplicates:
                print(f"Would delete: {file}")
    else:
        print("No duplicates found.")

if __name__ == "__main__":
    main()

