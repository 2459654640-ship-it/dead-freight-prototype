# Asset credits

Industrial prop meshes and PBR texture sets from **Godot Third Person Shooter Demo**:
https://github.com/godotengine/tps-demo/tree/a82f15448e9b015440d3bbdf5e10801b260c4e9f

Copyright © 2018 Juan Linietsky and Fernando Miguel Calabró.
Licensed under **Creative Commons Attribution 3.0 (CC-BY 3.0)**:
https://creativecommons.org/licenses/by/3.0/
Original license: [vendor/tps/LICENSE.md](vendor/tps/LICENSE.md).
Some original Substance Painter materials were kindly provided by GameTextures.com, as stated in the source license.

Changes: selected meshes extracted from `level/geometry/models/props.glb`,
unused buffers removed, meshes centered/scaled in game, textures resized to at most
1024 pixels and applied to new geometry. All selected art and adaptations remain
available under CC-BY 3.0. No demo gameplay scripts or complete levels are included.
`vendor/tps/manifest.json` records original downloaded files and hashes.

The map layout, tactical weapon, guard meshes, game UI, gameplay scripts, and
synthesized audio are newly created for this independent prototype. No assets,
code or save data from `/workspace/godot` are referenced.

## Quaternius — CC0

Rifle and animated male character: **Quaternius**, *Animated FPS Guns (June 2018)*
and *Animated Men Characters (February 2019)*.
Official creator: https://quaternius.com/
Downloaded from the public mirror https://github.com/beep2bleep/FreeAssetsByKenneyNLandQuaternius
under its included `FreeModels by Quaternius[Patreon]/License.txt`.
License: **CC0 1.0**, https://creativecommons.org/publicdomain/zero/1.0/.
Local copy: [vendor/quaternius/LICENSE.txt](vendor/quaternius/LICENSE.txt).
Source FBX files are included under `vendor/quaternius/source/`. Adaptations: FBX converted to glTF, rifle materials
recolored and static bind mesh exported; idle/walk/run/death character animation
tracks converted, runtime weapon pose and equipment added. FBX-derived zero-alpha materials were corrected to opaque. These models replace
the initial procedural rifle and character body. Sleeves, gloves, equipment and
weapon sight geometry are original additions.

## ambientCG / Poly Haven — CC0

Photographic PBR textures **Asphalt021, Concrete012, Bricks066, Metal063** by
**Lennart Demes / ambientCG**, https://ambientcg.com/ (CC0 1.0).
HDR sky **kloppenheim_06_puresky** from **Poly Haven**,
https://polyhaven.com/a/kloppenheim_06_puresky (CC0 1.0).
Downloaded via the public asset mirror:
https://github.com/petroulacl/fps-buildings-env-kit
See `vendor/ambientcg/SOURCE-README.md` for its original credits.
Texture JPGs resized from 2K to 1K for this prototype; normal maps use OpenGL
orientation. HDR panorama retained at 2K. Source file hashes are recorded in
`vendor/ambientcg/manifest.json`.

## Flat Guns / recorded audio — CC0

The final playable carbine is **Flat Guns West / Rifle_Assault_West**, from
https://opengameart.org/content/cc0-flat-guns-west, licensed CC0.
AR-15 gunshot recording: **The Free Firearm Sound Library**,
https://opengameart.org/content/the-free-firearm-sound-library (CC0).
Stone footsteps: **Fantozzi's Footsteps**,
https://opengameart.org/content/fantozzis-footsteps-grasssand-stone (CC0).
Files downloaded from https://github.com/petroulacl/fps-asset-kit;
`vendor/flatguns/SOURCE-README.md` preserves the source credit and license summary.
Changes: carbine scaled and given an added sight; firearm audio trimmed to its
attack/tail, mono 44.1kHz Ogg conversion with tail fade. The original WAV remains
included. The earlier Quaternius rifle source is retained but is not used by the
final carbine. Footstep pitch varies slightly at runtime.
