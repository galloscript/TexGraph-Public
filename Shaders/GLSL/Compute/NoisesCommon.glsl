/*
 * @file    NoisesCommon.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

//------------------------------------------------------------------------
vec2 Hash2(vec2 p, int aSeed)
{
    float r = (aSeed+523.0)*sin(dot(p, vec2(53.3158, 43.6143)));
    return vec2(fract(15.32354 * r), fract(17.25865 * r));
}

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
    return vec4(res, border, eschema, 1.0 - cells);
}


/*


*/

/*
float VoronoiBorder( in vec2 p, in vec2 aEdges, in vec2 aTiling, in int aSeed )
{
    float dis = VoronoiDistance( p, aTiling, aEdges, aSeed );

    return 1.0 - smoothstep( aEdges.x, aEdges.y, dis );
}*/

/*
void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    vec4 lInputColor = imageLoad(uInputBuffer0, lBufferCoord);
    float lPattern = VoronoiBorder(lUV, vec2(0.0, 0.05), vec2(1));
    vec4 lColor = vec4(vec3(lPattern), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, lColor);
}
*/