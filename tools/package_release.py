#!/usr/bin/env python3
"""Bundle the place, source, docs and reproducible tooling; never include Git/credentials."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
ROOT=Path(__file__).resolve().parents[1]
output=ROOT/'dist/Yardwork-Studio-Kit.zip'
with ZipFile(output,'w',ZIP_DEFLATED) as z:
 for folder in ['src','docs','tools','assets']:
  for file in sorted((ROOT/folder).rglob('*')):
   if file.is_file() and '__pycache__' not in file.parts and file.suffix!='.pyc':z.write(file,file.relative_to(ROOT))
 for relative in ['README.md','default.project.json','dist/Yardwork.rbxlx']:
  z.write(ROOT/relative,relative)
print('Packaged',output.name)
