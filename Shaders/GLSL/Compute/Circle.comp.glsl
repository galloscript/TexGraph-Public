/*
 * @file    Circle.comp.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

#define M_PI 3.1415926535897932384626433832795
#define M_TWO_PI 6.28318530718

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, r16f) uniform image2D uOutputBuffer0;
//layout(binding = 1, rgba16f) uniform image2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform float     uRadius;
layout(location = 1)  uniform float     uFalloff;
layout(location = 2)  uniform float     uOffsetX;
layout(location = 3)  uniform float     uOffsetY;

/**
 * Draw a circle at vec2 `pos` with radius `rad` and
 * color `color`.
 */
float Circle(vec2 uv, vec2 pos, float rad, float falloff, float aExtent) 
{
	float d = (length(pos - uv) - rad) / aExtent;
	float t = smoothstep(-falloff, 0.005, d);
	return  1.0 - t;
}

float Circle2(in vec2 _st, in float _radius, float _falloff)
{
    vec2 dist = _st-vec2(0.5);
	return 1.-smoothstep(-_falloff + _radius-(_radius*0.01),
                         _radius+(_radius*0.01),
                         dot(dist,dist)*4.0);
}


void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = vec2(lBufferCoord.xy) / uOutputBufferSize.xy;
    vec2 lSize = vec2(uOutputBufferSize.xy);
    vec2 lPosition = vec2(uOffsetX, uOffsetY) - 0.5;
    //float lValue = Circle(lUV, lPosition, uRadius * lSize.x * 0.5f, uFalloff, uOutputBufferSize.x);
    float lValue = Circle2(lUV + lPosition, uRadius, uFalloff);
    vec4 lOutputColor = vec4(vec3(lValue, lValue, lValue), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
}
