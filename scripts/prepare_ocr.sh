#!/usr/bin/env bash
set -euo pipefail
mkdir -p assets/tessdata
curl -fL --retry 3 https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/main/fas.traineddata -o assets/tessdata/fas.traineddata
