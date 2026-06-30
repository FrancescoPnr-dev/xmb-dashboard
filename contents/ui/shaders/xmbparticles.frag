// XMB particles — fragment shader (fullscreen ShaderEffect, additive).
//
// The demo draws 2000 additive GL_POINTS whose positions come from a per-vertex seed
// shader (particles.js). True GL_POINTS needs a custom QSGGeometry (C++); in pure QML the
// faithful-and-cheap equivalent is a hashed twinkling starfield evaluated with a fixed
// 3x3 cell neighbourhood per pixel (constant cost — NOT a per-pixel loop over the wave).
// White, additive, clustered in the centre band, slow drift + twinkle, matching the demo
// look and its count/opacity/size/flowSpeed controls.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float pFlowSpeed;
    float pOpacity;
    float pSizeBase;
    float pSizeVar;
    float pDensity;
};

vec2 hash22(vec2 p)
{
    float n = dot(p, vec2(127.1, 311.7));
    return fract(sin(vec2(n, n + 1.0)) * 43758.5453123);
}

void main()
{
    vec2 uv = qt_TexCoord0;
    float pt = time * pFlowSpeed;

    vec2 cells = vec2(46.0, 26.0) * clamp(pDensity, 0.05, 4.0);
    vec2 gp = uv * cells;
    float spark = 0.0;
    for (int oy = -1; oy <= 1; ++oy) {
        for (int ox = -1; ox <= 1; ++ox) {
            vec2 cell = floor(gp) + vec2(float(ox), float(oy));
            vec2 rnd = hash22(cell);
            vec2 pos = cell + vec2(fract(rnd.x + pt * (rnd.x - 0.5) * 0.15),
                                   rnd.y + 0.012 * sin(pt * (rnd.y + 1.5) + rnd.x * 100.0));
            float d = length((gp - pos) * vec2(1.0, cells.x / cells.y));
            float size = (pSizeBase + rnd.y * pSizeVar) * 0.012;
            float dot1 = smoothstep(size, 0.0, d);
            float tw = 0.5 + 0.5 * sin(pt * (1.0 + rnd.x * 2.0) + rnd.y * 6.2831);
            spark += dot1 * tw * tw;
        }
    }
    // centre-band weighting (demo particles live around clip-y 0)
    float band = smoothstep(0.62, 0.0, abs(uv.y - 0.5) * 2.0);
    float a = clamp(spark * pOpacity * band, 0.0, 1.0);
    fragColor = vec4(vec3(a), a) * qt_Opacity;   // premultiplied, ~additive on dark bg
}
