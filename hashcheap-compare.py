def read_csv_data(filename):
    """Read CSV data and return a dictionary of hashes to file paths."""
    data = {}
    with open(filename, mode='r', encoding='utf-8') as file:
        for line in file:
            line = line.rstrip('\n')
            if not line or line.startswith('%%') or line.startswith('##'):
                continue
            parts = line.split(',', 3)
            if len(parts) < 4:
                continue
            _, md5, sha256, filepath = parts
            hash_key = (md5, sha256)
            if hash_key in data:
                data[hash_key].append(filepath)
            else:
                data[hash_key] = [filepath]
    return data

def find_identical_files(data1, data2):
    """Find identical files in two data dictionaries and return their paths."""
    identical_files = []
    for hash_key in data1:
        if hash_key in data2:
            if len(data1[hash_key]) > 1:
                print('[WARN] identical: ', data1[hash_key])
            identical_files.extend(data1[hash_key])
    return identical_files

def main(csv_file1, csv_file2):
    
    # Read data from both CSV files
    data1 = read_csv_data(csv_file1)
    data2 = read_csv_data(csv_file2)
    
    # Find identical files
    identical_files = find_identical_files(data1, data2)
    
    # Output identical files
    if identical_files:
        print(f"{len(identical_files)} Identical files found out of {len(data1)} files in {csv_file1} and {len(data2)} files in {csv_file2}:")
        for filepath in set(sorted(identical_files)):  # Use set to remove duplicates from list
            print(filepath)
    else:
        print("No identical files found.")

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 3:
        print('usage: finds files from input1 that are already in input2, so you can delete them from input1')
        print('need <input1> <input2>')
        exit()
    main(sys.argv[-2], sys.argv[-1])

