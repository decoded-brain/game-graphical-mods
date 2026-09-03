# Release notes

## v0.2.0

This release refreshes all three published addons and their source snapshots.

- **Detroit: Become Human:** replaces the obsolete launcher/Vulkan-layer package with separate HDR Core and Effects addons. The Effects addon embeds the optional NGX bootstrap and adds native DOF v2, while the executable identity gate has been removed. Unknown shader, resource and pipeline contracts still fail closed.
- **Dishonored 2:** adds the locally validated Luma Neutwo, PsychoV-17 and PsychoV-22 tone-mapping choices. The unfinished PsychoV-25/Test25 experiment is not included.
- **Frostpunk 2:** republishes the unchanged current Frostpunk-specific UE Extended build so all packages share one release version.

Detroit's Debug and Release targets built successfully and its focused test label passed 20/20 in both configurations. The Dishonored 2 Release binary linked successfully, retained its compatibility ABI export and passed its shader/numeric checks. Those checks do not by themselves prove visual HDR correctness on every system; both packages retain their Beta/Experimental status.

Read each mod's installation and compatibility notes before use. Fully close a game before replacing an addon. ReShade, NVIDIA DLSS/NGX binaries, game files, personal presets and development tools are not bundled.

SHA-256 checksums are supplied as a separate release asset.

## v0.1.0

The initial public release published source snapshots and tested local binaries for:

- Dishonored 2 RenoDX HDR (beta)
- Detroit: Become Human RenoDX HDR, Vulkan DLAA and ultrawide support (experimental)
- Frostpunk 2 RenoDX UE Extended HDR support (experimental)

ReShade, NVIDIA DLSS/NGX binaries, game files, personal presets and development tools were not bundled. SHA-256 checksums were supplied as a separate release asset.
