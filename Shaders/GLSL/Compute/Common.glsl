/*
 * @file    Common.glsl
 * @author  David Gallardo Moreno
 */


#version 430

//wraps a coord that my be ouside of bounds returning it in a xy repeat basis
ivec2 wrap_coord(in ivec2 aCoord, in ivec2 aImageSize)
{
    vec2 lSize = vec2(aImageSize);
    ivec2 lImageCoord = aCoord;
    lImageCoord.x = (lImageCoord.x < 0) ? int(lSize.x) - lImageCoord.x :  lImageCoord.x;
    lImageCoord.y = (lImageCoord.y < 0) ? int(lSize.y) - lImageCoord.y :  lImageCoord.y;
    lImageCoord.x = lImageCoord.x % int(lSize.x);
    lImageCoord.y = lImageCoord.y % int(lSize.y);
    return lImageCoord;
}

//return integer coords from uvs
ivec2 uv2coord(in vec2 aUV, in ivec2 aImageSize)
{
    vec2 lSize = vec2(aImageSize);
    return wrap_coord(ivec2(aUV * lSize), aImageSize);
}

vec4 boxmap( sampler2D sam, in vec3 p, in vec3 n, in float k )
{
    vec3 m = pow( abs(n), vec3(k) );
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
	return (x*m.x + y*m.y + z*m.z)/(m.x+m.y+m.z);
}

vec3 spheremap( sampler2D sam, in vec3 d )
{
    vec3 n = abs(d);

#if 0
    // sort components (small to big)    
    float mi = min(min(n.x,n.y),n.z);
    float ma = max(max(n.x,n.y),n.z);
    vec3 o = vec3( mi, n.x+n.y+n.z-mi-ma, ma );
    return texture( sam, .1*o.xy/o.z ).xyz;
#else
    vec2 uv = (n.x>n.y && n.x>n.z) ? d.yz/d.x: 
              (n.y>n.x && n.y>n.z) ? d.zx/d.y:
                                     d.xy/d.z;
    return texture( sam, uv ).xyz;
    
#endif    
}

