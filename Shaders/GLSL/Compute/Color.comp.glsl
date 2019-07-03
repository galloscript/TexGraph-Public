/*
 * @file    Color.comp.glsl
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

layout(location = 0)  uniform vec4    uColor;
layout(location = 1)  uniform int     uIgnoreInput;

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    if(uIgnoreInput == 0)
    {
        vec4 lInputColor0 = texelFetch(uInputBuffer0, lBufferCoord, 0);
        vec4 lInputColor1 = texelFetch(uInputBuffer1, lBufferCoord, 0);
        vec4 lInputColor2 = texelFetch(uInputBuffer2, lBufferCoord, 0);

        const vec4 lOutputColor = uColor * vec4(vec3(lInputColor0.r, lInputColor1.r, lInputColor2.r), 1.0);
        imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
    }
    else
    {
        imageStore (uOutputBuffer0, lBufferCoord, clamp(uColor, 0.0, 1.0));
    }
}
