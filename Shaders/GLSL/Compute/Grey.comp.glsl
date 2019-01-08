/*
 * @file    Grey.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D uOutputBuffer0;


layout(location = 0)  uniform float    uGray;

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(gl_NumWorkGroups.xy));

    const vec4 lOutputColor = vec4(vec3(uGray), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
