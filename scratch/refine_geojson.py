import json

def refine_geojson(input_path, output_path, point_threshold=50, precision=6):
    print(f"Loading {input_path}...")
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Identify MultiPolygon
    if data['type'] == 'GeometryCollection':
        multi_poly = data['geometries'][0]
    else:
        # Fallback if structure is different
        print("Structure is not GeometryCollection, attempting to find MultiPolygon...")
        if 'features' in data:
            multi_poly = data['features'][0]['geometry']
        else:
            multi_poly = data

    if multi_poly['type'] != 'MultiPolygon':
        print(f"Expected MultiPolygon, got {multi_poly['type']}")
        return

    coords = multi_poly['coordinates']
    print(f"Original polygon count: {len(coords)}")

    new_coords = []
    for poly in coords:
        # poly is a list of rings, usually only one for outer boundary
        outer_ring = poly[0]
        
        if len(outer_ring) >= point_threshold:
            # Round coordinates
            refined_ring = [[round(c[0], precision), round(c[1], precision)] for c in outer_ring]
            
            # Remove duplicate consecutive points after rounding
            cleaned_ring = []
            if refined_ring:
                cleaned_ring.append(refined_ring[0])
                for i in range(1, len(refined_ring)):
                    if refined_ring[i] != refined_ring[i-1]:
                        cleaned_ring.append(refined_ring[i])
                
                # Ensure it's still closed
                if len(cleaned_ring) > 3:
                    if cleaned_ring[0] != cleaned_ring[-1]:
                        cleaned_ring.append(cleaned_ring[0])
                    new_coords.append([cleaned_ring])

    print(f"Refined polygon count: {len(new_coords)}")

    # Update data
    multi_poly['coordinates'] = new_coords
    
    # Create a cleaner FeatureCollection output instead of GeometryCollection
    output_data = {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "properties": {"name": "Korea Outline Clean"},
                "geometry": multi_poly
            }
        ]
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, separators=(',', ':')) # Compact JSON

    print(f"Saved to {output_path}")

if __name__ == "__main__":
    refine_geojson(
        'assets/data/korea_outline_2023.json', 
        'assets/data/korea_outline_refined.json',
        point_threshold=100, # Filter out small islands
        precision=5          # 5 decimal places is ~1m accuracy, very clean
    )
