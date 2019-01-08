/*
 * @file    Blend.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D uOutputBuffer0;
layout(binding = 1, rgba8) uniform image2D uInputBuffer0;
layout(binding = 2, rgba8) uniform image2D uInputBuffer1;
layout(binding = 3, rgba8) uniform image2D uMaskBuffer;


void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(gl_NumWorkGroups.xy));
    vec4 lInputColor0 = imageLoad(uInputBuffer0, lBufferCoord);
    vec4 lInputColor1 = imageLoad(uInputBuffer1, lBufferCoord);
    vec4 lInputColor2 = imageLoad(uMaskBuffer, lBufferCoord);

    const vec4 lOutputColor = (lInputColor0 * lInputColor2) + (lInputColor1 * (1.0f - lInputColor2));
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
