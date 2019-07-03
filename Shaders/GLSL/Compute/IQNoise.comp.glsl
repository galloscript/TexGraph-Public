/*
 * @file    IQNoise.comp.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;


layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0) uniform float uVoronoi;
layout(location = 1) uniform float uBlur;
layout(location = 2) uniform float uPanX;
layout(location = 3) uniform float uPanY;
layout(location = 4) uniform float uScaleX;
layout(location = 5) uniform float uScaleY;

float hashf(float n) { int q = int(n); return float((0x3504f333 * q * q + q) * (0xf1bbcdcb * q * q + q)) * (2.f /  8589934592.f) + .5f; }

#define F1 float
#define F2 vec2
#define F3 vec3

//  Gets a 3-dimensional random number using given argument as seed for the calculation.
//  @in     x       Seed to use.
//  @return Resulting value.
F1 noise(F3  x)
{
    F3 p    = floor(x);
    F3 f    = fract(x);
    f         = f * f * (3.f - 2.0f * f);

    F1 n   = p.x + p.y * 57 + 113 * p.z;
    F1 res = mix(mix(mix(hashf(n      ), hashf(n +   1), f.x),
                        mix(hashf(n +  57), hashf(n +  58), f.x), f.y),
                    mix(mix(hashf(n + 113), hashf(n + 114), f.x),
                        mix(hashf(n + 170), hashf(n + 171), f.x), f.y), f.z);
    return res;
}

//  Gets a 2-dimensional random number using given argument as seed for the calculation.
//  @in     x       Seed to use.
//  @return Resulting value.
F3 noise3d(F2 x) { return F3(noise(F3(x.x,x.y,x.y) * 100.f), noise(F3(x.y,x.x,x.x) * 200.f), noise(F3(x.y,x.x,x.y) * 300.f)); }

F3 hash3(F2 p) { return fract(sin(F3(dot(p, F2(127.1, 311.7)), dot(p, F2(269.5, 183.3)), dot(p, F2(419.2, 371.9)))) * 43758.5453f); }
/*
vec2 Hash2(vec2 p, int aSeed)
{
    float r = (aSeed+523.0)*sin(dot(p, vec2(53.3158, 43.6143)));
    return vec2(fract(15.32354 * r), fract(17.25865 * r));
}
*/

F1 iqnoise(F2 x, F1 u, F1 v)
{
	F1 va = 0;
	F1 wt = 0;
    for(F1 j = -2; j <= 2; ++j)
        for(F1 i = -2; i <= 2; ++i)
        {
		    F3 o   = hash3(mod(floor(x) + F2(i, j), vec2(uScaleX, uScaleY))) * F3(u, u, 1);
            //F2 o     = Hash2(mod(floor(x) + F2(i, j), vec2(uScaleX, uScaleY)), 0) * F2(u, u); // voronoise
		    F2 r   = F2 (i, j) - fract  (x) + F2(o);
		    F1 ww = pow  (1 - smoothstep(.0f, 1.414f, sqrt(dot(r, r))), 1 + 63 * pow(1 - v, 4));
		    va      += o.z*ww;
		    wt      += ww;
        }
    return va / wt;
}

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    vec4 lInputColor = texelFetch(uInputBuffer0, lBufferCoord, 0);
    float lPattern = iqnoise(F2((lUV.x + (uPanX * (0.5 / uScaleX)) + lInputColor.r) * uScaleX, 
                                (lUV.y + (uPanY * (0.5 / uScaleY)) + lInputColor.g) * uScaleY), uVoronoi, uBlur);
    //float lPattern = iqnoise(lUV * 10.0, uVoronoi, uBlur);
    vec4 lOutputColor = vec4(vec3(lPattern), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
}

