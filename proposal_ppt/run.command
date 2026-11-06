#!/bin/bash
set -e
cd "$(dirname "$0")"
python3 -c "import pptx, matplotlib" 2>/dev/null || pip3 install -q python-pptx Pillow matplotlib
python3 make_ppt.py
open "찜모험_지자체제안서_10장.pptx"
