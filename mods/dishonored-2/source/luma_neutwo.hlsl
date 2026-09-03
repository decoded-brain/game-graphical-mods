#ifndef SRC_GAMES_DISHONORED2_LUMA_NEUTWO_HLSL_
#define SRC_GAMES_DISHONORED2_LUMA_NEUTWO_HLSL_

/*
 * The extended-vanilla curve, Neutwo LUT bridge, and final Neutwo/BT.2020
 * tone map are adapted from the Luma Framework Dishonored 2 project.
 *
 * Copyright (c) 2024+ Filippo Tarpini
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * Addenda:
 * Any reuse of this code shall include the names of the authors or of the project.
 * Commercial usage is possible but only after asking permission to the authors.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

namespace dishonored2 {
namespace luma_neutwo {

float EvaluateVanillaCurve(float input, float4 coefficients) {
  return mad(coefficients.x, input, coefficients.z)
         / mad(coefficients.y, input, coefficients.w);
}

float EvaluateVanillaCurveDerivative(float input, float4 coefficients) {
  const float denominator = mad(coefficients.y, input, coefficients.w);
  return (coefficients.x * coefficients.w
          - coefficients.y * coefficients.z)
         / (denominator * denominator);
}

float ExtendVanillaCurveChannel(
    float input,
    float transition,
    float4 low_coefficients,
    float4 high_coefficients) {
  if (input < transition) {
    return EvaluateVanillaCurve(input, low_coefficients);
  }

  const float pivot = EvaluateVanillaCurve(transition, high_coefficients);
  const float slope = EvaluateVanillaCurveDerivative(transition, high_coefficients);
  return mad(input - transition, slope, pivot);
}

float3 ExtendVanillaCurve(
    float3 input,
    float transition,
    float4 low_coefficients,
    float4 high_coefficients) {
  return float3(
      ExtendVanillaCurveChannel(input.r, transition, low_coefficients, high_coefficients),
      ExtendVanillaCurveChannel(input.g, transition, low_coefficients, high_coefficients),
      ExtendVanillaCurveChannel(input.b, transition, low_coefficients, high_coefficients));
}

float3 SampleLUT(
    Texture3D<float4> lut,
    SamplerState lut_sampler,
    float3 input,
    uint size) {
  const float lut_scale = renodx::tonemap::neutwo::ComputeMaxChannelScale(input, 1.f);
  const float size_float = (float)size;
  const float3 lut_coordinates =
      (saturate(input * lut_scale) * (size_float - 1.f) + 0.5f) / size_float;
  const float3 graded = lut.SampleLevel(lut_sampler, lut_coordinates, 0.f).rgb;
  return renodx::math::DivideSafe(graded, lut_scale.xxx, 0.f.xxx);
}

float3 ApplyBT2020ToneMap(float3 color, float2 gamma_brightness) {
  float peak = max(
      RENODX_PEAK_WHITE_NITS / max(RENODX_DIFFUSE_WHITE_NITS, 1e-4f),
      1e-4f);
  if (RENODX_GAMMA_CORRECTION != 0.f) {
    peak = renodx::color::correct::Gamma(
        peak,
        RENODX_GAMMA_CORRECTION > 0.f,
        abs(RENODX_GAMMA_CORRECTION) == 1.f ? 2.2f : 2.4f);
  }
  // The game gamma/brightness stage also runs after Neutwo. Compensate its
  // neutral-axis peak while preserving exact Luma behavior at the 1/1 defaults.
  peak = pow(peak, rcp(max(gamma_brightness.x, 1e-4f)))
         / max(gamma_brightness.y, 1e-4f);
  float3 bt2020 = renodx::color::bt2020::from::BT709(color);
  bt2020 = renodx::tonemap::neutwo::PerChannel(bt2020, peak.xxx);
  return renodx::color::bt709::from::BT2020(bt2020);
}

float3 ApplyGammaBrightness(float3 color, float2 gamma_brightness) {
  return renodx::math::SignPow(
      color * gamma_brightness.y,
      gamma_brightness.xxx);
}

float3 RemoveBlackFloor(float3 color, float3 black_point) {
  return max(0.f, color - black_point)
         / max(1e-4f, 1.f - black_point);
}

float3 ToneMap(
    float3 untonemapped,
    float transition,
    float4 low_coefficients,
    float4 high_coefficients,
    float2 gamma_brightness,
    bool remove_black_floor) {
  float3 color = ExtendVanillaCurve(
      untonemapped,
      transition,
      low_coefficients,
      high_coefficients);
  if (remove_black_floor) {
    const float3 black_point = ExtendVanillaCurve(
        0.f,
        transition,
        low_coefficients,
        high_coefficients);
    color = RemoveBlackFloor(color, black_point);
  }
  color = ApplyBT2020ToneMap(color, gamma_brightness);
  return ApplyGammaBrightness(color, gamma_brightness);
}

float3 ToneMapWithLUT(
    Texture3D<float4> lut,
    SamplerState lut_sampler,
    float3 untonemapped,
    float transition,
    float4 low_coefficients,
    float4 high_coefficients,
    float2 gamma_brightness,
    bool remove_black_floor) {
  const float3 neutral = ExtendVanillaCurve(
      untonemapped,
      transition,
      low_coefficients,
      high_coefficients);
  const float grade_strength = saturate(RENODX_COLOR_GRADE_STRENGTH);
  float3 color = lerp(
      neutral,
      SampleLUT(lut, lut_sampler, neutral, 32u),
      grade_strength);
  if (remove_black_floor) {
    const float3 neutral_black = ExtendVanillaCurve(
        0.f,
        transition,
        low_coefficients,
        high_coefficients);
    const float3 graded_black = lerp(
        neutral_black,
        SampleLUT(lut, lut_sampler, neutral_black, 32u),
        grade_strength);
    color = RemoveBlackFloor(color, graded_black);
  }
  color = ApplyBT2020ToneMap(color, gamma_brightness);
  return ApplyGammaBrightness(color, gamma_brightness);
}

}  // namespace luma_neutwo
}  // namespace dishonored2

#endif  // SRC_GAMES_DISHONORED2_LUMA_NEUTWO_HLSL_
