/*
 * @file    Offset.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;
layout(location = 81) uniform sampler2D uInputBuffer1;
layout(location = 82) uniform sampler2D uInputBuffer2;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0) uniform float uOffsetX;
layout(location = 1) uniform float uOffsetY;

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    float lInputColor1 = texelFetch(uInputBuffer1, lBufferCoord, 0).r;
    float lInputColor2 = texelFetch(uInputBuffer2, lBufferCoord, 0).r; 
    vec2 lImgOffset = vec2(lInputColor1, lInputColor2);
    vec2 lOffset = vec2(uOffsetX, uOffsetY);
    ivec2 lOffsetCoord = lBufferCoord + ivec2(((lImgOffset - .5) + lOffset) * vec2(uOutputBufferSize.xy));
    lOffsetCoord = lOffsetCoord % ivec2(uOutputBufferSize.xy);
    vec4 lOutputColor = texelFetch(uInputBuffer0, lOffsetCoord, 0);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
