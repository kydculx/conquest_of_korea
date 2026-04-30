import json

def get_bounds(filepath):
    with open(filepath, 'r') as f:
        data = json.load(f)
    
    min_lat, min_lng = 90, 180
    max_lat, max_lng = -90, -180
    
    geometries = []
    if data['type'] == 'FeatureCollection':
        for feature in data.get('features', []):
            if feature.get('geometry'):
                geometries.append(feature['geometry'])
    elif data['type'] == 'GeometryCollection':
        geometries.extend(data.get('geometries', []))
    else:
        geometries.append(data)
        
    for geom in geometries:
        coords = geom['coordinates']
        if geom['type'] == 'Polygon':
            polys = [coords]
        elif geom['type'] == 'MultiPolygon':
            polys = coords
        else:
            continue
            
        for poly in polys:
            for ring in poly:
                for coord in ring:
                    lng, lat = coord[0], coord[1]
                    min_lat = min(min_lat, lat)
                    max_lat = max(max_lat, lat)
                    min_lng = min(min_lng, lng)
                    max_lng = max(max_lng, lng)
                    
    print(f"{filepath} Bounds:")
    print(f"South (Min Lat): {min_lat}")
    print(f"North (Max Lat): {max_lat}")
    print(f"West (Min Lng): {min_lng}")
    print(f"East (Max Lng): {max_lng}")
    print("-" * 30)

try:
    get_bounds('assets/data/korea_outline_2023.json')
except: pass
try:
    get_bounds('assets/data/korea_sido_2023.json')
except: pass

