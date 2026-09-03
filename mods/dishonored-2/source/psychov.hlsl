#ifndef SRC_GAMES_DISHONORED2_PSYCHOV_HLSL_
#define SRC_GAMES_DISHONORED2_PSYCHOV_HLSL_

namespace dishonored2 {
namespace psychov {

bool IsActive() {
  return RENODX_TONE_MAP_TYPE == DISHONORED2_TONE_MAP_TYPE_PSYCHOV17
         || RENODX_TONE_MAP_TYPE == DISHONORED2_TONE_MAP_TYPE_PSYCHOV22;
}

float EvaluateVanillaCurve(
    float input,
    float transition,
    float4 low_coefficients,
    float4 high_coefficients) {
  const float4 coefficients = input < transition
                                  ? low_coefficients
                                  : high_coefficients;
  return dishonored2::luma_neutwo::EvaluateVanillaCurve(input, coefficients);
}

float InvertVanillaCurve(
    float output,
    float4 coefficients,
    float fallback) {
  const float denominator = coefficients.x - output * coefficients.y;
  return abs(denominator) < 1e-6f
             ? fallback
             : (output * coefficients.w - coefficients.z) / denominator;
}

float ApplyGammaBrightness(float color, float2 gamma_brightness) {
  color = saturate(color * gamma_brightness.y);
  return color == 0.f
             ? 0.f
             : exp2(log2(color) * gamma_brightness.x);
}

float ApplyDisplayEOTF(float color) {
  if (RENODX_GAMMA_CORRECTION == renodx::draw::GAMMA_CORRECTION_GAMMA_2_2) {
    return renodx::color::correct::GammaSafe(color, false, 2.2f);
  }
  if (RENODX_GAMMA_CORRECTION == renodx::draw::GAMMA_CORRECTION_GAMMA_2_4) {
    return renodx::color::correct::GammaSafe(color, false, 2.4f);
  }
  return color;
}

float ApplyDisplayEOTFDerivative(float color) {
  float gamma;
  if (RENODX_GAMMA_CORRECTION == renodx::draw::GAMMA_CORRECTION_GAMMA_2_2) {
    gamma = 2.2f;
  } else if (RENODX_GAMMA_CORRECTION == renodx::draw::GAMMA_CORRECTION_GAMMA_2_4) {
    gamma = 2.4f;
  } else {
    return 1.f;
  }

  if (color <= 0.f) return 0.f;
  const bool linear_segment = color <= 0.0031308f;
  const float encoded = linear_segment
                            ? color * 12.92f
                            : mad(1.055f, pow(color, 1.f / 2.4f), -0.055f);
  const float encoded_derivative = linear_segment
                                       ? 12.92f
                                       : (1.055f / 2.4f)
                                             * pow(color, 1.f / 2.4f - 1.f);
  return gamma * pow(encoded, gamma - 1.f) * encoded_derivative;
}

float PrepareForIntermediate(float color) {
  if (RENODX_GAMMA_CORRECTION == renodx::draw::GAMMA_CORRECTION_GAMMA_2_2) {
    return renodx::color::correct::GammaSafe(color, true, 2.2f);
  }
  if (RENODX_GAMMA_CORRECTION == renodx::draw::GAMMA_CORRECTION_GAMMA_2_4) {
    return renodx::color::correct::GammaSafe(color, true, 2.4f);
  }
  return color;
}

float3 PrepareForIntermediate(float3 color) {
  return float3(
      PrepareForIntermediate(color.r),
      PrepareForIntermediate(color.g),
      PrepareForIntermediate(color.b));
}

// Returns Dishonored 2's neutral output and derivative in V100 units, where
// 0.18 is 18 nits.
float2 EvaluateVanillaNeutralV100(
    float input,
    float transition,
    float4 low_coefficients,
    float4 high_coefficients,
    float2 gamma_brightness,
    bool remove_black_floor) {
  input = max(input, 0.f);
  const float4 coefficients = input < transition
                                  ? low_coefficients
                                  : high_coefficients;
  const float curve_output = EvaluateVanillaCurve(
      input,
      transition,
      low_coefficients,
      high_coefficients);
  const float scaled_output = curve_output * gamma_brightness.y;
  const float gamma_input = saturate(scaled_output);
  float output = ApplyGammaBrightness(curve_output, gamma_brightness);
  float derivative = scaled_output <= 0.f || scaled_output >= 1.f
                         ? 0.f
                         : dishonored2::luma_neutwo::EvaluateVanillaCurveDerivative(
                               input,
                               coefficients)
                               * gamma_brightness.y
                               * gamma_brightness.x
                               * pow(gamma_input, gamma_brightness.x - 1.f);

  if (remove_black_floor) {
    const float black_point = ApplyGammaBrightness(
        EvaluateVanillaCurve(
            0.f,
            transition,
            low_coefficients,
            high_coefficients),
        gamma_brightness);
    output = saturate(
        max(0.f, output - black_point)
        / max(1e-4f, 1.f - black_point));
    derivative = output <= 0.f || output >= 1.f
                     ? 0.f
                     : derivative / max(1e-4f, 1.f - black_point);
  }

  derivative *= ApplyDisplayEOTFDerivative(output);
  output = ApplyDisplayEOTF(output);
  const float scale = max(RENODX_DIFFUSE_WHITE_NITS, 0.f) / 100.f;
  return float2(max(output, 0.f), max(derivative, 0.f)) * scale;
}

float ResolveGradedNeutralAnchor() {
  static const float NEUTRAL = 0.18f;
  float graded = NEUTRAL * max(RENODX_TONE_MAP_EXPOSURE, 0.f);

  if (RENODX_TONE_MAP_HIGHLIGHTS != 1.f) {
    graded = renodx::color::grade::Highlights(
        graded,
        RENODX_TONE_MAP_HIGHLIGHTS,
        NEUTRAL);
  }
  if (RENODX_TONE_MAP_SHADOWS != 1.f) {
    graded = renodx::color::grade::Shadows(
        graded,
        RENODX_TONE_MAP_SHADOWS,
        NEUTRAL);
  }
  if (RENODX_TONE_MAP_CONTRAST != 1.f) {
    graded = renodx::color::grade::ContrastSafe(
        graded,
        RENODX_TONE_MAP_CONTRAST,
        NEUTRAL);
  }

  if (graded != graded) return NEUTRAL;
  return max(graded, 1e-6f);
}

// Reconstructs the CP2077 PsychoV contract against Dishonored 2's own neutral
// curve: solve its 18-nit input anchor and borrow its local log-log slope. The
// creative 3D LUT is intentionally excluded from this neutral reference; its
// live grade is preserved separately by ComputeUntonemappedGraded().
float3 ResolveVanillaReference(
    float transition,
    float4 low_coefficients,
    float4 high_coefficients,
    float2 gamma_brightness,
    bool remove_black_floor) {
  static const float NEUTRAL = 0.18f;
  const float unmatched_anchor = ResolveGradedNeutralAnchor();
  float anchor_input = unmatched_anchor;
  float anchor_output = unmatched_anchor;
  float reference_input = NEUTRAL;
  float2 reference = EvaluateVanillaNeutralV100(
      reference_input,
      transition,
      low_coefficients,
      high_coefficients,
      gamma_brightness,
      remove_black_floor);

  if (DISHONORED2_PSYCHOV_EXPOSURE_MATCH >= 0.5f
      || DISHONORED2_PSYCHOV_VANILLA_SLOPE > 0.f) {
    float curve_target = PrepareForIntermediate(saturate(
        NEUTRAL * 100.f / max(RENODX_DIFFUSE_WHITE_NITS, 1e-6f)));
    if (remove_black_floor) {
      const float black_point = ApplyGammaBrightness(
          EvaluateVanillaCurve(
              0.f,
              transition,
              low_coefficients,
              high_coefficients),
          gamma_brightness);
      curve_target = mad(
          curve_target,
          max(1e-4f, 1.f - black_point),
          black_point);
    }
    curve_target = pow(
                       saturate(curve_target),
                       rcp(max(gamma_brightness.x, 1e-4f)))
                   / max(gamma_brightness.y, 1e-4f);

    const float low_limit = max(transition - 1e-5f, 0.f);
    const float high_limit = max(transition, 0.f);
    const float low_input = clamp(
        InvertVanillaCurve(curve_target, low_coefficients, low_limit),
        0.f,
        low_limit);
    const float high_input = clamp(
        InvertVanillaCurve(curve_target, high_coefficients, high_limit),
        high_limit,
        max(high_limit, 1e4f));
    const float2 low_reference = EvaluateVanillaNeutralV100(
        low_input,
        transition,
        low_coefficients,
        high_coefficients,
        gamma_brightness,
        remove_black_floor);
    const float2 high_reference = EvaluateVanillaNeutralV100(
        high_input,
        transition,
        low_coefficients,
        high_coefficients,
        gamma_brightness,
        remove_black_floor);
    const bool use_low_reference = transition > 0.f
                                   && abs(low_reference.x - NEUTRAL)
                                          <= abs(high_reference.x - NEUTRAL);
    reference_input = use_low_reference ? low_input : high_input;
    reference = use_low_reference ? low_reference : high_reference;

    if (DISHONORED2_PSYCHOV_EXPOSURE_MATCH >= 0.5f) {
      anchor_input = reference_input;
      anchor_output = reference.x * 100.f
                      / max(RENODX_DIFFUSE_WHITE_NITS, 1e-6f);
    }
  }

  float vanilla_log_slope = 1.f;
  if (DISHONORED2_PSYCHOV_VANILLA_SLOPE > 0.f) {
    const float candidate = reference.x == 0.f
                                ? 1.f
                                : max(
                                      reference_input * reference.y
                                          / reference.x,
                                      0.f);
    if (candidate == candidate && candidate < 1e4f) {
      vanilla_log_slope = candidate;
    }
  }

  return float3(anchor_input, anchor_output, vanilla_log_slope);
}

float3 SanitizeOutput(float3 color, float peak) {
  const float safe_peak = max(peak, 0.f);
  float3 output = min(
      max(renodx::math::ZeroNaN(color), 0.f),
      65504.f);
  const float output_peak = renodx::math::Max(output);
  if (output_peak > safe_peak) {
    output *= safe_peak / max(output_peak, 1e-6f);
  }
  return output;
}

float3 ToneMap(
    float3 untonemapped,
    float3 graded_sdr,
    float3 neutral_sdr,
    float transition,
    float4 low_coefficients,
    float4 high_coefficients,
    float2 gamma_brightness,
    bool remove_black_floor) {
  const float3 psychov_input = max(
      renodx::draw::ComputeUntonemappedGraded(
          untonemapped,
          graded_sdr,
          neutral_sdr),
      0.f);
  const float peak = max(
      RENODX_PEAK_WHITE_NITS
          / max(RENODX_DIFFUSE_WHITE_NITS, 1.f),
      1.f);
  const float3 vanilla_reference = ResolveVanillaReference(
      transition,
      low_coefficients,
      high_coefficients,
      gamma_brightness,
      remove_black_floor);
  const float cone_response = max(
      DISHONORED2_PSYCHOV_CONE_RESPONSE,
      0.f)
      * lerp(
          1.f,
          vanilla_reference.z,
          saturate(DISHONORED2_PSYCHOV_VANILLA_SLOPE));

  float3 output;
  if (RENODX_TONE_MAP_TYPE == DISHONORED2_TONE_MAP_TYPE_PSYCHOV17) {
    output = renodx::tonemap::psychov::psychotm_test17(
        psychov_input,
        peak,
        RENODX_TONE_MAP_EXPOSURE,
        RENODX_TONE_MAP_HIGHLIGHTS,
        RENODX_TONE_MAP_SHADOWS,
        RENODX_TONE_MAP_CONTRAST,
        RENODX_TONE_MAP_SATURATION,
        1.f,
        100.f,
        1.f,
        1.f,
        0,
        cone_response,
        float(vanilla_reference.x).xxx,
        float(vanilla_reference.y).xxx,
        1.f,
        0,
        1.f);
  } else {
    output = renodx::tonemap::psychov::psychotm_test22(
        psychov_input,
        peak,
        RENODX_TONE_MAP_EXPOSURE,
        RENODX_TONE_MAP_HIGHLIGHTS,
        RENODX_TONE_MAP_SHADOWS,
        RENODX_TONE_MAP_CONTRAST,
        RENODX_TONE_MAP_SATURATION,
        1.f,
        100.f,
        1.f,
        1.f,
        0,
        cone_response,
        float(vanilla_reference.x).xxx,
        float(vanilla_reference.y).xxx,
        1.f,
        0,
        1.f,
        1.f);
  }

  // PsychoV already returns display-linear light. Undo the game's selectable
  // EOTF emulation here; RenderIntermediatePass applies it again downstream.
  return PrepareForIntermediate(SanitizeOutput(output, peak));
}

}  // namespace psychov
}  // namespace dishonored2

#endif  // SRC_GAMES_DISHONORED2_PSYCHOV_HLSL_
