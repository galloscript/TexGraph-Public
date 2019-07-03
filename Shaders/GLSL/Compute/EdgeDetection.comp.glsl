/*
 * @file    EdgeDetection.comp.glsl
 * @author  David Gallardo Moreno
 * @origin  https://www.shadertoy.com/view/Xdf3Rf
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;

//layout(location = 0) uniform int    uKernelSize;
//layout(location = 1) uniform float  uSigma;
layout(location = 0) uniform float  uArea;

// Use these parameters to fiddle with settings
float uStep = 1.0;

vec4 fetchInput(vec2 aUV)
{
    ivec2 lBufferCoord = ivec2(aUV * uOutputBufferSize.xy);
    lBufferCoord = lBufferCoord.xy % uOutputBufferSize.xy;
    return texelFetch(uInputBuffer0, lBufferCoord, 0);
}

float intensity(in vec4 color)
{
	return sqrt((color.x*color.x)+(color.y*color.y)+(color.z*color.z));
}

vec3 sobel(float stepx, float stepy, vec2 center){
	// get samples around pixel
    float tleft = intensity(fetchInput(center + vec2(-stepx,stepy)));
    float left = intensity(fetchInput(center + vec2(-stepx,0)));
    float bleft = intensity(fetchInput(center + vec2(-stepx,-stepy)));
    float top = intensity(fetchInput(center + vec2(0,stepy)));
    float bottom = intensity(fetchInput(center + vec2(0,-stepy)));
    float tright = intensity(fetchInput(center + vec2(stepx,stepy)));
    float right = intensity(fetchInput(center + vec2(stepx,0)));
    float bright = intensity(fetchInput(center + vec2(stepx,-stepy)));
 
	// Sobel masks (see http://en.wikipedia.org/wiki/Sobel_operator)
	//        1 0 -1     -1 -2 -1
	//    X = 2 0 -2  Y = 0  0  0
	//        1 0 -1      1  2  1
	
	// You could also use Scharr operator:
	//        3 0 -3        3 10   3
	//    X = 10 0 -10  Y = 0  0   0
	//        3 0 -3        -3 -10 -3
 
    float x = tleft + 2.0*left + bleft - tright - 2.0*right - bright;
    float y = -tleft - 2.0*top - tright + bleft + 2.0 * bottom + bright;
    float color = sqrt((x*x) + (y*y));
    return vec3(color,color,color);
 }

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //vec4 lInputColor0 = texelFetch(uInputBuffer0, lBufferCoord, 0);
    vec4 lOutputColor = vec4(sobel(uStep/256.f, uStep/256.f, lUV), 1.0);
    //const vec4 lOutputColor = vec4(vec3(lColorSum.x, lColorSum.y, lColorSum.z), lInputColor0.a);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lOutputColor, 0.0, 1.0));
}
