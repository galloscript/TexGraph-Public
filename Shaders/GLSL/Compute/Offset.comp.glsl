/*
 * @file    Offset.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba16f) uniform image2D uOutputBuffer0;
layout(binding = 1, rgba16f) uniform image2D uInputBuffer0;
layout(binding = 2, rgba16f) uniform image2D uInputBuffer1;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0) uniform float uOffsetX;
layout(location = 1) uniform float uOffsetY;

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    vec4 lInputColor1 = imageLoad(uInputBuffer1, lBufferCoord);
    vec2 lOffset = vec2(uOffsetX, uOffsetY);
    ivec2 lOffsetCoord = lBufferCoord + ivec2(((lInputColor1.rg - .5) + lOffset) * vec2(uOutputBufferSize.xy));
    lOffsetCoord = lOffsetCoord % ivec2(uOutputBufferSize.xy);
    vec4 lOutputColor = imageLoad(uInputBuffer0, lOffsetCoord);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
