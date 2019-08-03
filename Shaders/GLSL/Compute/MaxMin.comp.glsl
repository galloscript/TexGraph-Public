/*
 * @file    Max.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;
layout(location = 81) uniform sampler2D uInputBuffer1;
layout(location = 82) uniform sampler2D uInputBuffer2;
layout(location = 83) uniform sampler2D uInputBuffer3;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform float    uEdge;

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    vec4 lInputColor0 = texelFetch(uInputBuffer0, lBufferCoord, 0);
    vec4 lInputColor1 = texelFetch(uInputBuffer1, lBufferCoord, 0);

#ifdef KRN_MIN
    const vec4 lOutputColor = vec4(min(lInputColor0.xyz, lInputColor1.xyz), 1.0);
#else
    const vec4 lOutputColor = vec4(max(lInputColor0.xyz, lInputColor1.xyz), 1.0);
#endif
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
 