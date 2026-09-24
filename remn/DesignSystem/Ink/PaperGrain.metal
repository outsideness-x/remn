#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float remnHash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float remnValueNoise(float2 p) {
    float2 cell = floor(p);
    float2 f = fract(p);
    float a = remnHash(cell);
    float b = remnHash(cell + float2(1.0, 0.0));
    float c = remnHash(cell + float2(0.0, 1.0));
    float d = remnHash(cell + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/// The tooth, fibres and uneven pulp of a sheet of paper, as a small lift or dip in brightness.
[[ stitchable ]] half4 remnPaperGrain(float2 position, half4 color, float strength) {
    float tooth = remnHash(floor(position * 2.0)) - 0.5;
    float fibres = remnValueNoise(position * float2(0.055, 0.12)) - 0.5;
    float pulp = remnValueNoise(position * 0.011) - 0.5;
    float shade = tooth * 0.8 + fibres * 0.3 + pulp * 0.85;
    return half4(color.rgb + half3(shade * strength) * color.a, color.a);
}
