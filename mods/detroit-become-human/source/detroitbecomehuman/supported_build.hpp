/*
 * SPDX-License-Identifier: MIT
 */

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>

namespace renodx::games::detroitbecomehuman::supported_build {

inline constexpr std::uint64_t kSteamBuildId = 12'158'144u;

inline constexpr std::uint32_t kTemporalAaShaderCrc = 0xB5506A45u;
inline constexpr std::uint32_t kObservedTemporalAaModuleSize = 37'236u;

inline constexpr std::uint32_t kMotionBlurShaderCrc = 0xC03380A0u;
inline constexpr std::uint32_t kObservedMotionBlurModuleSize = 9'112u;

inline constexpr std::uint32_t kDofSplitShaderCrc = 0xE9907978u;
inline constexpr std::uint32_t kDofGatherShaderCrc = 0x747E19D2u;
inline constexpr std::uint32_t kDofFillShaderCrc = 0x508514FBu;
inline constexpr std::uint32_t kDofCompositeShaderCrc = 0xAC7A8193u;
inline constexpr std::array<std::uint32_t, 4u> kDofShaderCrcs = {
    kDofSplitShaderCrc,
    kDofGatherShaderCrc,
    kDofFillShaderCrc,
    kDofCompositeShaderCrc,
};
inline constexpr std::array<std::uint32_t, 4u> kObservedDofModuleSizes = {
    9'236u,
    11'180u,
    7'908u,
    8'004u,
};

// Explicit runtime evidence gate. This is enabled only for the observed shader
// and resource contract after the live b52/resource capture and render-ordering
// audit were completed. Any shader revision must introduce a new evidence
// revision and starts with this gate disabled.
inline constexpr std::uint32_t kTemporalInputEvidenceRevision = 1u;
inline constexpr bool kTemporalInputsEmpiricallyVerified = true;

// The complete seven-dispatch chain and these four replacement targets were
// observed together. A new shader revision must start fail-closed with a new
// evidence revision.
inline constexpr std::uint32_t kDofInputEvidenceRevision = 1u;
inline constexpr bool kDofInputsEmpiricallyVerified = true;

}  // namespace renodx::games::detroitbecomehuman::supported_build
