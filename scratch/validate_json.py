import json

def check_json_error(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            json.load(f)
        print("JSON is valid!")
    except json.JSONDecodeError as e:
        print(f"JSON Error: {e}")
        # Print the context around the error
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            start = max(0, e.lineno - 5)
            end = min(len(lines), e.lineno + 5)
            print("\nContext:")
            for i in range(start, end):
                prefix = ">> " if i + 1 == e.lineno else "   "
                print(f"{i+1:5}: {prefix}{lines[i].strip()}")

if __name__ == "__main__":
    check_json_error('scratch/check_2023.json')
