/*
 * @file    Pow.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba16f) uniform image2D uOutputBuffer0;
layout(binding = 1, rgba16f) uniform image2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform float    uPower;

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    vec4 lInputColor0 = imageLoad(uInputBuffer0, lBufferCoord);

    const vec4 lOutputColor = vec4(vec3(pow(lInputColor0.xyz, vec3(uPower))), lInputColor0.a);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
}
