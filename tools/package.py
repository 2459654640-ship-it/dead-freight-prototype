"""Package portable source WITH asset import settings and WITHOUT generated caches."""
from pathlib import Path
import zipfile,sys
root=Path(__file__).resolve().parents[1]
output=Path(sys.argv[1]) if len(sys.argv)>1 else root.parent/'DeadFreight-import-fix.zip'
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=5) as archive:
 for path in sorted(root.rglob('*')):
  rel=path.relative_to(root)
  if path.is_file() and not any(p in ['.git','.godot','.runtime','exports','__pycache__'] for p in rel.parts):
   archive.write(path,Path(root.name)/rel)
print(output)
