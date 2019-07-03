/*
 * @file    GradientNoise.comp.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

#define M_PI 3.1415926535897932384626433832795

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0) uniform float uVoronoi;
layout(location = 1) uniform float uBlur;
layout(location = 2) uniform float uPanX;
layout(location = 3) uniform float uPanY;
layout(location = 4) uniform float uScaleX;
layout(location = 5) uniform float uScaleY;

vec3 hash( vec3 p ) // replace this by something better. really. do
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

// return value noise (in x) and its derivatives (in yzw)
vec4 noised( in vec3 x )
{
    // grid
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    #if 1
    // quintic interpolant
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);
    #else
    // cubic interpolant
    vec3 u = w*w*(3.0-2.0*w);
    vec3 du = 6.0*w*(1.0-w);
    #endif    
    
    // gradients
    vec3 ga = hash( p+vec3(0.0,0.0,0.0) );
    vec3 gb = hash( p+vec3(1.0,0.0,0.0) );
    vec3 gc = hash( p+vec3(0.0,1.0,0.0) );
    vec3 gd = hash( p+vec3(1.0,1.0,0.0) );
    vec3 ge = hash( p+vec3(0.0,0.0,1.0) );
	vec3 gf = hash( p+vec3(1.0,0.0,1.0) );
    vec3 gg = hash( p+vec3(0.0,1.0,1.0) );
    vec3 gh = hash( p+vec3(1.0,1.0,1.0) );
    
    // projections
    float va = dot( ga, w-vec3(0.0,0.0,0.0) );
    float vb = dot( gb, w-vec3(1.0,0.0,0.0) );
    float vc = dot( gc, w-vec3(0.0,1.0,0.0) );
    float vd = dot( gd, w-vec3(1.0,1.0,0.0) );
    float ve = dot( ge, w-vec3(0.0,0.0,1.0) );
    float vf = dot( gf, w-vec3(1.0,0.0,1.0) );
    float vg = dot( gg, w-vec3(0.0,1.0,1.0) );
    float vh = dot( gh, w-vec3(1.0,1.0,1.0) );
	
    // interpolations
    return vec4( va + u.x*(vb-va) + u.y*(vc-va) + u.z*(ve-va) + u.x*u.y*(va-vb-vc+vd) + u.y*u.z*(va-vc-ve+vg) + u.z*u.x*(va-vb-ve+vf) + (-va+vb+vc-vd+ve-vf-vg+vh)*u.x*u.y*u.z,    // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.z*(ge-ga) + u.x*u.y*(ga-gb-gc+gd) + u.y*u.z*(ga-gc-ge+gg) + u.z*u.x*(ga-gb-ge+gf) + (-ga+gb+gc-gd+ge-gf-gg+gh)*u.x*u.y*u.z +   // derivatives
                 du * (vec3(vb,vc,ve) - va + u.yzx*vec3(va-vb-vc+vd,va-vc-ve+vg,va-vb-ve+vf) + u.zxy*vec3(va-vb-ve+vf,va-vb-vc+vd,va-vc-ve+vg) + u.yzx*u.zxy*(-va+vb+vc-vd+ve-vf-vg+vh) ));
}

vec3 torus_coords(vec2 uv)
{
    vec3 lNoiseCoord = vec3(0,0,0);
    float c=8, a=1; // torus parameters (controlling size)
    lNoiseCoord.x = (c+a*cos(2*M_PI*uv.y))*cos(2*M_PI*uv.x);
    lNoiseCoord.y = (c+a*cos(2*M_PI*uv.y))*sin(2*M_PI*uv.x);
    lNoiseCoord.z = a*sin(2*M_PI*uv.y);
    return lNoiseCoord;
}

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    
    //float lPattern = iqnoise(F2((lUV.x + uPanX + lInputColor.r) * uScaleX, (lUV.y + uPanY + lInputColor.g) * uScaleY), uVoronoi, uBlur);
    //float lPattern = iqnoise(lUV * 10.0, uVoronoi, uBlur);
/*
    vec3 lNoiseCoord = vec3(0,0,0);
    float c=4, a=1; // torus parameters (controlling size)
    lNoiseCoord.x = (c+a*cos(2*M_PI*lUV.y))*cos(2*M_PI*lUV.x);
    lNoiseCoord.y = (c+a*cos(2*M_PI*lUV.y))*sin(2*M_PI*lUV.x);
    lNoiseCoord.z = a*sin(2*M_PI*lUV.y);*/


    float lPattern = 0.5 + noised( torus_coords(lUV.yx) ).x;
    vec4 lColor = vec4(vec3(lPattern), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lColor, 0.0, 1.0));
}

