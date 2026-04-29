import urllib.request
import json
import os

# 2023-07-01 version of South Korea Administrative Boundaries (Dong level)
URL = "https://raw.githubusercontent.com/vuski/admdongkor/master/ver20230701/HangJeongDong_ver20230701.geojson"
OUTPUT_PATH = "assets/data/korea_sido_2023.json"

def process_data():
    print(f"Downloading data from {URL}...")
    try:
        with urllib.request.urlopen(URL) as response:
            data = json.loads(response.read().decode('utf-8'))
        print("Download complete.")

        # Group by Sido
        sido_map = {}
        for feature in data['features']:
            props = feature['properties']
            sido_name = props.get('sidonm')
            if not sido_name: continue
            
            if sido_name not in sido_map:
                sido_map[sido_name] = {
                    "type": "Feature",
                    "properties": {
                        "name": sido_name,
                        "code": props.get('sido')
                    },
                    "geometry": {
                        "type": "MultiPolygon",
                        "coordinates": []
                    }
                }
            
            geom = feature['geometry']
            if geom['type'] == 'Polygon':
                sido_map[sido_name]['geometry']['coordinates'].append(geom['coordinates'])
            elif geom['type'] == 'MultiPolygon':
                sido_map[sido_name]['geometry']['coordinates'].extend(geom['coordinates'])

        # Create new FeatureCollection
        new_features = list(sido_map.values())
        result = {
            "type": "FeatureCollection",
            "features": new_features
        }

        # Ensure directory exists
        os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
        
        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False)
        
        print(f"Successfully saved {len(new_features)} Sido boundaries to {OUTPUT_PATH}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    process_data()
