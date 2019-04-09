/*
 * @file    Tiling.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D uOutputBuffer0;
layout(binding = 1, rgba8) uniform image2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform float uRepeatX;
layout(location = 1)  uniform float uRepeatY;
layout(location = 2)  uniform float uOffsetX; //not used
layout(location = 3)  uniform float uOffsetY; //not used



void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //lBufferCoord = ivec2(lBufferCoord * vec2(uRepeatX, uRepeatY));
    ivec2 lFetchCoord = ivec2(lBufferCoord * vec2(uRepeatX, uRepeatY));
    vec2 lOffset = vec2(uOffsetX, uOffsetY) * uOutputBufferSize.xy;
    lFetchCoord = lFetchCoord + ivec2(lOffset * floor(lFetchCoord.yx / uOutputBufferSize.yx));
    lFetchCoord = lFetchCoord % uOutputBufferSize.xy;
    vec4 lOutputColor = imageLoad(uInputBuffer0, lFetchCoord);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
    //imageStore (uOutputBuffer0, lBufferCoord, vec4(uOffsetX, uOffsetY, 0, 1));
}
 