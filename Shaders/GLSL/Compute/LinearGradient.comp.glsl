/*
 * @file    GreyGradientMix.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0; //Start value
layout(location = 81) uniform sampler2D uInputBuffer1; //End Value
layout(location = 82) uniform sampler2D uInputBuffer2; //Angle
  
layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform int uSeed;
//layout(location = 1)  uniform float uPan;


void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    float lStartValue = texelFetch(uInputBuffer0, lBufferCoord, 0).r;
    float lEndValue = texelFetch(uInputBuffer1, lBufferCoord, 0).r;
    float lAngle = texelFetch(uInputBuffer2, lBufferCoord, 0).r;
    float lCoord = mix(lUV.x, lUV.y, lAngle);
    vec4 lOutputColor = vec4(vec3(mix(lEndValue, lStartValue, lCoord)), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
}
