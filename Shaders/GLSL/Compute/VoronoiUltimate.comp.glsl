 /*
 * @file    VoronoiUltimate.comp.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, r16f) uniform image2D uOutputBuffer0;
layout(binding = 1, r16f) uniform image2D uOutputBuffer1;
layout(binding = 2, r16f) uniform image2D uOutputBuffer2;
layout(binding = 3, r16f) uniform image2D uOutputBuffer3;
layout(location = 80) uniform sampler2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;


layout(location = 0) uniform int uSeed;
layout(location = 1) uniform float uThickness;
layout(location = 2) uniform float uHardness;
layout(location = 3) uniform float uPanX;
layout(location = 4) uniform float uPanY;
layout(location = 5) uniform float uScaleX;
layout(location = 6) uniform float uScaleY;

vec2 Hash2(vec2 p, int aSeed);
 
//------------------------------------------------------------------------
vec4 VoronoiUltimate( in vec2 x, in vec2 aTiling, in vec2 aEdges, int aSeed )
{
    x *= aTiling;
    ivec2 p = ivec2(floor( x ));
    vec2  f = fract( x );

    ivec2 mb;
    vec2 mr;

    float res = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        ivec2 b = ivec2( i, j );
        vec2  r = vec2( b ) + Hash2( mod(p + b, aTiling), aSeed ) - f;
        float d = dot(r,r);

        if( d < res )
        {
            res = d;
            mr = r;
            mb = b;
        }
    }

    float va = 0;
	float wt = 0;
    float cells = 1.0e10;
    res = 8.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        ivec2 b = mb + ivec2( i, j );
        vec2  o = Hash2( mod(p + b, aTiling), aSeed );
        vec2  r = vec2( b ) + o - f; //mod 4
        float d = dot( 0.5*(mr+r), normalize(r-mr) );
        float drr = dot(r, r);
        res = min( res, d );
        cells = min(cells, drr);
		float ww = pow  (1 - smoothstep(.0f, 1.414f, sqrt(drr)), 64);
		va      += o.y*ww;
		wt      += ww;
    }

    const float border = 1.0 - smoothstep( aEdges.x, aEdges.y, res ); //(edges: 0.0, 0.05)
    const float eschema = va / wt;
    return clamp(vec4(res, border, eschema, 1.0 - cells), 0.0, 1.0);
}
//-----------------------------------

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //vec4 lInputColor = texelFetch(uInputBuffer0, lBufferCoord, 0);
    vec4 lPattern = VoronoiUltimate(lUV + vec2(uPanX, uPanY), vec2(uScaleX, uScaleY), vec2(uHardness, uThickness), uSeed);
    //vec4 lColor = vec4(vec3(lPattern), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, vec4(vec3(lPattern.x), 1.0));
    imageStore (uOutputBuffer1, lBufferCoord, vec4(vec3(lPattern.y), 1.0));
    imageStore (uOutputBuffer2, lBufferCoord, vec4(vec3(lPattern.z), 1.0));
    imageStore (uOutputBuffer3, lBufferCoord, vec4(vec3(lPattern.w), 1.0));
}

