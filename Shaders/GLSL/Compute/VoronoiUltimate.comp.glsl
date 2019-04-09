 /*
 * @file    VoronoiUltimate.comp.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D uOutputBuffer0;
layout(binding = 1, rgba8) uniform image2D uOutputBuffer1;
layout(binding = 2, rgba8) uniform image2D uOutputBuffer2;
layout(binding = 3, rgba8) uniform image2D uOutputBuffer3;
layout(binding = 4, rgba8) uniform image2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;


layout(location = 0) uniform int uSeed;
layout(location = 1) uniform float uThickness;
layout(location = 2) uniform float uHardness;
layout(location = 3) uniform float uPanX;
layout(location = 4) uniform float uPanY;
layout(location = 5) uniform float uScaleX;
layout(location = 6) uniform float uScaleY;

//------------------------------------------------------------------------
vec4 VoronoiUltimate( in vec2 x, in vec2 aTiling, in vec2 aEdges, int aSeed );
//------------------------------------------------------------------------

 
void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //vec4 lInputColor = imageLoad(uInputBuffer0, lBufferCoord);
    vec4 lPattern = VoronoiUltimate(lUV + vec2(uPanX, uPanY), vec2(uScaleX, uScaleY), vec2(uHardness, uThickness), uSeed);
    //vec4 lColor = vec4(vec3(lPattern), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, vec4(vec3(lPattern.x), 1.0));
    imageStore (uOutputBuffer1, lBufferCoord, vec4(vec3(lPattern.y), 1.0));
    imageStore (uOutputBuffer2, lBufferCoord, vec4(vec3(lPattern.z), 1.0));
    imageStore (uOutputBuffer3, lBufferCoord, vec4(vec3(lPattern.w), 1.0));
}

