/*
 * @file    DrawCubemap.comp.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D uOutputBuffer0;

layout(location = 12) uniform mat4 uBGRotMatrix;
layout(location = 20) uniform samplerCube uEnvCubeMap;

vec3 toneMapping(vec3 hdrColor, float exposure, float gamma)
{
    // Exposure tone mapping
    vec3 mapped = vec3(1.0) - exp(-hdrColor * exposure);
    
    // Gamma correction
    mapped = pow(mapped, vec3(1.0 / gamma));
    
    return mapped;
}


vec3 DrawCubemap(in vec2 aUV)
{
    vec2 pos =  aUV * 2.0 - 1.0;
    pos.y *= float(gl_NumWorkGroups.y) / float(gl_NumWorkGroups.x);
    vec3 bgN = mat3(uBGRotMatrix) * -normalize(vec3(pos.x, pos.y, -1.5));

    return textureLod(uEnvCubeMap, bgN, 0).rgb;
}

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 lUV = vec2(lBufferCoord.xy) / vec2(gl_NumWorkGroups.xy);
    //vec4 lInputColor0 = imageLoad(uInputBuffer0, lBufferCoord);

    vec4 lOutputColor = vec4(0.0, 0.0, 0.0, 1.0);
    lOutputColor.rgb = DrawCubemap(lUV);
    lOutputColor.rgb = toneMapping(lOutputColor.rgb, 2.2, 0.45);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
