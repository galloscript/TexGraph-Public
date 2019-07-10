/*
 * @file    Blend.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;
layout(location = 102) uniform ivec4 uInputFormat;
layout(location = 103) uniform ivec4 uOutputFormat;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;
layout(location = 81) uniform sampler2D uInputBuffer1;
layout(location = 82) uniform sampler2D uInputBuffer2; //mask

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    vec4 lInputColor0 = texelFetch(uInputBuffer0, lBufferCoord, 0);
    vec4 lInputColor1 = texelFetch(uInputBuffer1, lBufferCoord, 0);
    float lInputColor2 = texelFetch(uInputBuffer2, lBufferCoord, 0).r;

    lInputColor0.rgb = (uInputFormat.x == 1) ? lInputColor0.rrr : lInputColor0.rgb; 
    lInputColor1.rgb = (uInputFormat.y == 1) ? lInputColor1.rrr : lInputColor1.rgb; 

    vec4 lOutputColor = (lInputColor0 * lInputColor2) + (lInputColor1 * (1.0f - lInputColor2));
    lOutputColor.a = 1;
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
