# Dishonored 2

Beta RenoDX HDR addon for Dishonored 2. This build adds Luma Neutwo, PsychoV-17 and PsychoV-22 to the existing Vanilla, None, ACES and RenoDRT tone-mapping choices.

## Installation

1. Install the current ReShade Full Add-On build into the Dishonored 2 game directory.
2. Copy `renodx-dishonored2.addon64` from the release archive into the same directory as the game executable.
3. Do not combine this package with the unfinished Luma test bundle.

The optional Dishonored 2 Graphical Upgrade compatibility addon is not distributed here; see the attribution and licensing explanation in the repository-level third-party notices.

The unvalidated PsychoV-25/Test25 experiment is deliberately excluded from this package. Tone-map modes included here are the last Release build that completed shader compilation, ABI checks and numerical validation.

## Provenance

- Source snapshot: RenoDX commit `9cfea6043cca1cb9b141e3df37c024362248bd66` on `feat/dishonored2-renodx`.
- Release binary SHA-256: `965E4A676C3DF16F56CFCF0A07ADEF3ED5DC7BB7B683B7A4DF147F2D72A3B742`.
- Author of this game integration: decoded-brain.
- Framework: Carlos Lopez Jr. and RenoDX contributors, MIT License.
- Luma Neutwo portions: Filippo Tarpini / Luma Framework, under the notice reproduced in `THIRD_PARTY_NOTICES.md` and in the source file.

The Release binary linked both affected Shader Model 5 shaders and retains `DISHONORED2_GRAPHICAL_UPGRADE_COMPATIBILITY_ABI`. Full visual/HDR acceptance remains pending, so the addon stays Beta.
