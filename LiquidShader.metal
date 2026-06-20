// Mediatron Liquid Shader — real-time interactive gradient mesh
// Uses Core Image via visualEffect for Metal-backed liquid rendering
// 
// The gradient warps based on a time parameter for ambient motion.
// In production, this would be a real .metal shader with pointer coordinate inputs.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[stitchable]] half4 liquidGradient(
    float2 position,
    half4 color,
    float time,
    float2 size
) {
    // Normalized coordinates
    float2 uv = position / size;
    
    // Warp coordinates with sine waves for liquid feel
    float2 warped = uv;
    warped.x += sin(uv.y * 8.0 + time) * 0.03;
    warped.y += cos(uv.x * 6.0 + time * 1.3) * 0.03;
    
    // Multi-stop liquid gradient
    float3 c1 = float3(0.98, 0.98, 1.0);   // near white
    float3 c2 = float3(0.90, 0.94, 1.0);   // soft blue
    float3 c3 = float3(0.95, 0.92, 1.0);   // soft lavender
    
    float t1 = sin(warped.x * 3.0 + time * 0.5) * 0.5 + 0.5;
    float t2 = cos(warped.y * 2.5 + time * 0.7) * 0.5 + 0.5;
    
    float3 gradient = mix(mix(c1, c2, t1), c3, t2);
    
    // Subtle vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.3;
    gradient *= vignette;
    
    return half4(half3(gradient), 1.0);
}
