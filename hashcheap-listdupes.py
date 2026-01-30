#!/usr/bin/env python
import sys
import os
import hashlib
import csv
import glob

def hash_file(filename, algorithm):
    hash_algo = hashlib.new(algorithm)
    try:
        with open(filename, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_algo.update(chunk)
        return hash_algo.hexdigest()
    except FileNotFoundError:
        return None

def read_log_file(log_path):
    file_dict = {}
    with open(log_path, 'r', newline='') as file:
        reader = csv.DictReader(file)
        for i, row in enumerate(reader):
            if all(key in row for key in ['filepath', 'size', 'md5', 'sha256']):
                row['size'] = int(row['size'])
                file_dict[os.path.basename(row['filepath'])] = row
    return file_dict

def find_files(directory):
    return glob.glob(os.path.join(directory, '**/*'))

def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py <log_file> <directory>")
        sys.exit(1)

    log_file = sys.argv[1]
    directory = sys.argv[2]

    log_data = read_log_file(log_file)
    files_in_dir = find_files(directory)

    duplicates = []

    for file_path in files_in_dir:
        print(file_path)
        file_name = os.path.basename(file_path)
        if file_name in log_data:
            file_info = log_data[file_name]
            md5 = hash_file(file_path, 'md5')
            sha256 = hash_file(file_path, 'sha256')
            size = os.path.getsize(file_path)
            # print(file_path,size,md5,sha256)

            if md5 == file_info['md5'] and sha256 == file_info['sha256'] and size == file_info['size']:
                duplicates.append(file_info['filepath'])

    for info in duplicates:
        print(info)

if __name__ == "__main__":
    main()

