# Godot 4.7.2 import repair

User environment: Windows 11, Godot 4.7.2, 16 GB RAM, RTX 4070 Laptop.
The Windows crash has not been reproduced directly: the execution machine is Linux.
Do not describe this as a confirmed out-of-memory crash or a proven GPU defect.

Observed packaging defect: the previous ZIP omitted every source .import file.
The original models also generated unintended collision bodies from their names.
Large source textures were initially lossless and imported concurrently.

Changes: retain all asset import settings; disable naming-based physics generation,
LOD/shadow mesh creation and lightmap preparation for these visual assets; serialize
imports; use 2K import limits and S3TC-compatible VRAM compression. Lower the initial
shadow-map and MSAA defaults. Original source images are unchanged.

Validation (official Linux Godot 4.7.2, verified against published SHA512):
- Original package: GUI first import exit 0, 49.04 seconds, peak RSS 2130.3 MiB.
- Fixed package: GUI first import exit 0, 41.47 seconds, peak RSS 1299.6 MiB.
- Final ZIP with settled settings: GUI first import exit 0, 39.0 seconds, peak RSS 1230.1 MiB.
- Repaired project: 52 functional checks, zero failures.
- Pre-imported Windows-target PCK: 52 checks, zero failures, run without source assets
  or an imported project cache; actual OpenGL launch verified menu/deploy/render.

These results verify Linux import/pack operation; they do not establish the cause
of the user's Windows crash. Windows launchers save version, console, engine logs
and exit status. The PCK is built with 4.7.2 and avoids first-time asset import.

Packaging regression guard: tools/package.py includes .import settings and excludes
only generated caches and exports. Keep this rule in subsequent source archives.
