/*
 * @file    Mix.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

#ifdef KRN_MIX_GS
layout(location = 0)  uniform float      uBegin;
layout(location = 1)  uniform float      uEnd;
#else
layout(location = 0)  uniform vec4      uBeginColor;
layout(location = 1)  uniform vec4      uEndColor;
#endif

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
#ifdef KRN_MIX_GS
    float lInputColor = texelFetch(uInputBuffer0, lBufferCoord, 0).x;
    vec4 lOutputColor = vec4(mix(uBegin, uEnd, lInputColor));
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
#else 
    vec4 lInputColor = texelFetch(uInputBuffer0, lBufferCoord, 0).xxxa;
    vec4 lOutputColor = mix(uBeginColor, uEndColor, lInputColor);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
#endif
}
