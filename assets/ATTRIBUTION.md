# Current asset attribution

All currently rendered equipment below comes from existing artist-authored models.
Gameplay, scene composition, collision, IK and integration code are project work.
The earlier programmatically built tactical gear and simplified viewmodels have
been removed from runtime assets; their history remains in Git.

## City Soldier (outdated)

- Author: buh (https://sketchfab.com/buh-late)
- Original: https://sketchfab.com/3d-models/city-soldier-outdated-636b5a7c7e0c400abda269ba382f3252
- License: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Download mirror: https://raw.githubusercontent.com/perara-libs/3d-models/HEAD/city_soldier/soldier.gltf
- Files: `vendor/city-soldier/`

## M4A1 With Hands And Animations

- Author: BillyTheKid (https://sketchfab.com/FGmodels)
- Original: https://sketchfab.com/3d-models/m4a1-with-hands-and-animations-79524d1b74e24962979127cbb5c0b55b
- License: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Download mirror: https://raw.githubusercontent.com/jerzakm/three-threlte-fps/HEAD/static/models/m4.gltf
- Files: `vendor/finished-m4/`

## Dirty oil barrel - 5MB

- Author: adventurer (https://sketchfab.com/ahmagh2e)
- Original: https://sketchfab.com/3d-models/dirty-oil-barrel-5mb-b973a95ff3bb478a941ccb06a70b14bb
- License: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Download mirror: https://raw.githubusercontent.com/KurbyDoo/ZombieExpress/HEAD/assets/models/items/fuels/oil_barrel/oil_barrel.gltf
- Files: `vendor/oil-barrel/`

## Plastic Crate

- Author: Denisse Rodriguez (https://sketchfab.com/DenisseRodriguez)
- Original: https://sketchfab.com/3d-models/plastic-crate-5f7103bfb5974eab85bb1a4ab8a8595e
- License: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Download mirror: https://raw.githubusercontent.com/bladnman/basketball_tracker/HEAD/assets/plastic_crate/scene.gltf
- Files: `vendor/plastic-crate/`

## Wooden Crate

- Author: Memorie (https://sketchfab.com/Memorie)
- Original: https://sketchfab.com/3d-models/wooden-crate-2a3ac54357bb4b92bfbc119111c09fd1
- License: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Download mirror: https://raw.githubusercontent.com/mahdyfalah/tank-game/HEAD/assets/models/wooden_crate/scene.gltf
- Files: `vendor/wooden-crate/`

## pallet truck

- Author: Kwon_Hyuk (https://sketchfab.com/Kwon_Hyuk)
- Original: https://sketchfab.com/3d-models/pallet-truck-0419ee072fa4427aaadc2afbcae2894d
- License: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Download mirror: https://raw.githubusercontent.com/AouladLahceneOussama/3D-bin-packing/HEAD/models/pallet_truck/scene.gltf
- Files: `vendor/pallet-truck/`

## Industrial Electrical Box

- Author: VRTESTER (https://sketchfab.com/VRTESTER)
- Original: https://sketchfab.com/3d-models/industrial-electrical-box-de13c96dad014bf098df03030f314fee
- License: CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)
- Download mirror: https://raw.githubusercontent.com/namannpatel/AbhyasAR/HEAD/Assets/ImportedModels/ElectricalCabinet/ElectricalCabinet/scene.gltf
- Files: `vendor/power-cabinet/`

## Integration changes to CC-BY 4.0 assets

City Soldier retains the artist's original body, armor, pouches, boots, helmet,
backpack and PBR texture maps. The original bundle's optional AK74 meshes had
missing texture files in the mirror: those weapon nodes are excluded from the
rendered scene; placeholder references in their unused material are redirected to
an existing image. No character equipment geometry was fabricated or replaced.
The project adds bone aiming and locomotion controls. Metallic/roughness values
on cloth are normalized for Godot; original diffuse and normal maps are retained.

M4A1 retains the artist's sleeves, gloves, watch, gun, textures and native draw,
idle, firing and reload clips. The optional magnifier is hidden to use the
original holographic sight at 1x. Lens material alpha is adapted for Godot.
Third-person instances hide the first-person arms. Import-generated collision
objects are disabled: explicit game collision bodies supply physical interaction.
Props are scaled and positioned; plastic/wood roughness is adapted for Godot.

All these adaptations preserve attribution and remain under CC-BY 4.0:
https://creativecommons.org/licenses/by/4.0/

## Other retained resources

- Industrial prop/metal resources: Godot TPS Demo, Juan Linietsky and Fernando
  Miguel Calabró, CC-BY 3.0. https://github.com/godotengine/tps-demo . Original
  license is retained in `vendor/tps/LICENSE.md`.
- Asphalt021, Concrete012, Bricks066, Metal063: Lennart Demes / ambientCG,
  CC0. https://ambientcg.com . Current diffuse/normal/roughness maps are 2K;
  ambient occlusion maps are used where available. Original mirror metadata and
  license are retained in `vendor/ambientcg/`.
- Sky: Poly Haven kloppenheim_06_puresky, CC0.
  https://polyhaven.com/a/kloppenheim_06_puresky
- AR-15 recording: The Free Firearm Sound Library, CC0.
  https://opengameart.org/content/the-free-firearm-sound-library
- Footsteps: Fantozzi's Footsteps, CC0.
  https://opengameart.org/content/fantozzis-footsteps-grasssand-stone
  Audio sources, license and original WAV remain in `vendor/flatguns/`.

No source or asset from the previous `/workspace/godot` game is referenced.
