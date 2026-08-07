# Detroit: Become Human

Experimental RenoDX Vulkan HDR, native-resolution DLAA, ultrawide and UI-compensation mod.

## Compatibility

- Steam Build ID `12158144` only.
- Supported `DetroitBecomeHuman.exe` SHA-256: `ECF52321921387E683904E089082D76B973326FC093AF14E524056715519C1CF`.
- Requires ReShade 6.8.x Full Add-On and the native Vulkan renderer.

## Installation

Copy the custom files from the release archive beside `DetroitBecomeHuman.exe`, then launch through `DetroitDLSSLauncher.exe` when using the DLSS layer. ReShade and `nvngx_dlss.dll` are not included. The Vulkan DLSS layer is experimental; native TAA remains the fallback when a DLSS frame is rejected.

Fully restart the game after adding, replacing or removing the addon. Auto HDR and NVIDIA RTX HDR should be disabled to avoid an additional HDR conversion.

## Provenance

- Source snapshot: RenoDX fork commit `aee4761957d2e71e118d1c87892d889a657a7ded` on `feature/detroit-unified`.
- Addon SHA-256: `8DBC4C173893CAB3B39CFA4E5909EF740C37AE386AC7E87739542EA6CF95661A`.
- Vulkan layer SHA-256: `93E1292525D155E24A2FA1F67A9CC1D7AA0A731A07AFCC93AC67B38112615D23`.
- Author of this game integration: decoded-brain.
- Credits: RenoDX contributors, RenoDX PR #564 contributors, and Rose / PCGamingWiki for published ultrawide research.
