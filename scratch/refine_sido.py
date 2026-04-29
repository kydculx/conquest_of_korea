import json

def refine_sido_geojson(input_path, output_path, point_threshold=50, precision=5):
    print(f"Loading {input_path}...")
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if data['type'] != 'FeatureCollection':
        print(f"Expected FeatureCollection, got {data['type']}")
        return

    new_features = []
    
    for feature in data['features']:
        name = feature['properties'].get('CTP_KOR_NM', 'Unknown')
        geom = feature['geometry']
        geom_type = geom['type']
        coords = geom['coordinates']
        
        print(f"Processing {name} ({geom_type})...")
        
        refined_coords = []
        
        # Handle both Polygon and MultiPolygon
        polygons = coords if geom_type == 'MultiPolygon' else [coords]
        
        for poly in polygons:
            outer_ring = poly[0]
            if len(outer_ring) >= point_threshold:
                # Round coordinates
                refined_ring = [[round(c[0], precision), round(c[1], precision)] for c in outer_ring]
                
                # Remove duplicate consecutive points
                cleaned_ring = []
                if refined_ring:
                    cleaned_ring.append(refined_ring[0])
                    for i in range(1, len(refined_ring)):
                        if refined_ring[i] != refined_ring[i-1]:
                            cleaned_ring.append(refined_ring[i])
                    
                    if len(cleaned_ring) > 3:
                        if cleaned_ring[0] != cleaned_ring[-1]:
                            cleaned_ring.append(cleaned_ring[0])
                        refined_coords.append([cleaned_ring])

        if refined_coords:
            feature['geometry'] = {
                "type": "MultiPolygon",
                "coordinates": refined_coords
            }
            new_features.append(feature)

    print(f"Original feature count: {len(data['features'])}")
    print(f"Refined feature count: {len(new_features)}")

    output_data = {
        "type": "FeatureCollection",
        "features": new_features
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, separators=(',', ':'))

    print(f"Saved to {output_path}")

if __name__ == "__main__":
    refine_sido_geojson(
        'assets/data/korea_sido_2023.json', 
        'assets/data/korea_sido_2023_refined.json',
        point_threshold=80, # Keep meaningful islands
        precision=5
    )
