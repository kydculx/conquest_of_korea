import requests
import zipfile
import os

url = "http://www.gisdeveloper.co.kr/download/admin_shp/ctprvn_20230729.zip"
dest_dir = "assets/data/raw"
zip_path = os.path.join(dest_dir, "ctprvn_202307.zip")

if not os.path.exists(dest_dir):
    os.makedirs(dest_dir)

print(f"Downloading {url}...")
response = requests.get(url, timeout=30)
if response.status_code == 200:
    with open(zip_path, "wb") as f:
        f.write(response.content)
    print("Download complete.")
    
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(os.path.join(dest_dir, "ctprvn_202307"))
    print("Extraction complete.")
else:
    print(f"Failed to download: {response.status_code}")
