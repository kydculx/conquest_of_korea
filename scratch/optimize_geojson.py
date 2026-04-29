import json

INPUT_PATH = "assets/data/korea_sido_2023.json"
OUTPUT_PATH = "assets/data/korea_sido_2023_optimized.json"

def simplify_coordinates(coords, precision=4):
    if isinstance(coords[0], (int, float)):
        return [round(c, precision) for c in coords]
    return [simplify_coordinates(c, precision) for c in coords]

def optimize_geojson():
    print("Optimizing GeoJSON...")
    with open(INPUT_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    for feature in data['features']:
        coords = feature['geometry']['coordinates']
        feature['geometry']['coordinates'] = simplify_coordinates(coords)
    
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
    
    print(f"Optimization complete. Saved to {OUTPUT_PATH}")

if __name__ == "__main__":
    optimize_geojson()
