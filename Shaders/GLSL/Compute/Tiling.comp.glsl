/*
 * @file    Tiling.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(binding = 1, r16f) uniform image2D uOutputBuffer1;
layout(location = 80) uniform sampler2D uInputBuffer0;


layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform float uRepeatX;
layout(location = 1)  uniform float uRepeatY;
layout(location = 2)  uniform float uOffsetX; //not used
layout(location = 3)  uniform float uOffsetY; //not used

vec2 Hash2(vec2 p, int aSeed);

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //lBufferCoord = ivec2(lBufferCoord * vec2(uRepeatX, uRepeatY));
    ivec2 lFetchCoord = ivec2(lBufferCoord * vec2(uRepeatX, uRepeatY));
    vec2 lOffset = vec2(uOffsetX, uOffsetY) * uOutputBufferSize.xy;
    lFetchCoord = lFetchCoord + ivec2(lOffset * floor(lFetchCoord.yx / uOutputBufferSize.yx));
    vec2 lTileIndex =  vec2(lFetchCoord  / uOutputBufferSize.yx );
    lFetchCoord = lFetchCoord % uOutputBufferSize.xy;
    vec4 lOutputColor = texelFetch(uInputBuffer0, lFetchCoord, 0);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
    float lCode = Hash2(mod(lTileIndex, vec2(uRepeatX, uRepeatY)), 0).x;
    imageStore (uOutputBuffer1, lBufferCoord, vec4(vec3(lCode), 1.0));
    //imageStore (uOutputBuffer0, lBufferCoord, vec4(uOffsetX, uOffsetY, 0, 1));
}
 