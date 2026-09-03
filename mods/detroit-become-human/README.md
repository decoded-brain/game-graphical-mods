# Detroit: Become Human

Experimental RenoDX Vulkan package split into an HDR Core addon and a separate Effects addon.

## Package contents

- `renodx-detroitbecomehuman.addon64` owns HDR output, tone mapping, peak-brightness handling, ultrawide geometry and UI compensation.
- `renodx-detroitbecomehuman-effects.addon64` owns optional native-resolution DLAA, HDR-safe DLAA sharpening, native DOF v2, motion-blur handling and render diagnostics.

Install both files for the complete package. Keeping HDR Core separate means the optional effects path can fail closed without moving HDR ownership out of the core addon.

## Compatibility

- Requires ReShade 6.8.x Full Add-On and the native Vulkan renderer.
- Developed against the Steam release. This version no longer blocks startup or optional effects by executable name, size or SHA-256, but unknown shader CRCs and incompatible resource/pipeline contracts are still left untouched.
- DLAA requires the in-game Resolution Scaling setting to be `100%`. Reduced render extents fall back to native TAA.

## Installation

1. Fully close Detroit: Become Human.
2. Install ReShade 6.8.x with Full Add-On Support for the game's Vulkan renderer.
3. Copy both `.addon64` files from the release archive beside `DetroitBecomeHuman.exe`.
4. For DLAA, place a legally obtained compatible `nvngx_dlss.dll` beside the game executable. NVIDIA runtimes are not included in this archive.
5. Launch the game normally. No custom launcher, standalone Vulkan layer, global Vulkan registration or Steam launch option is required.
6. If the addon reports that the early NGX bootstrap was configured on first launch, fully restart the game once before enabling DLAA.

If upgrading from v0.1.0, clear any Steam Launch Option that references `DetroitDLSSLauncher.exe` and remove these obsolete files if they are still beside the game executable:

```text
DetroitDLSSLauncher.exe
renodx-detroit-dlss-layer.dll
VK_LAYER_RENODX_detroit_dlss.json
```

Do not remove ReShade configuration or shader folders used by other addons. Native TAA remains active whenever the optional DLAA path rejects a frame.

Fully restart the game after adding, replacing or removing the addon. Auto HDR and NVIDIA RTX HDR should be disabled to avoid an additional HDR conversion.

## Provenance

- Source snapshot: RenoDX fork commit `a15795e77440c331a9cfe19d521c7cede45b8b5f` on `feature/detroit-unified`.
- HDR Core addon SHA-256: `A7908CFEF043F4AC7621A6C40CE377587F91227A461D5504612ACBBABC87FBA9`.
- Effects addon SHA-256: `6FC98ACD0D05555FE562D4BE7D9F2BCCE054966EF1E06B23E0664012A01BC64B`.
- Author of this game integration: decoded-brain.
- Credits: RenoDX contributors, RenoDX PR #564 contributors, and Rose / PCGamingWiki for published ultrawide research.

The source snapshot mirrors the two RenoDX game directories as `source/detroitbecomehuman/` and `source/detroitbecomehuman-effects/`. The Detroit-specific shared NGX Vulkan core added under RenoDX `src/utils/dlss/` is mirrored in `source/shared-utils/dlss/`. Build and static tests passed; the package remains Experimental because compilation and automated tests are not a substitute for complete visual/runtime validation across the game.
