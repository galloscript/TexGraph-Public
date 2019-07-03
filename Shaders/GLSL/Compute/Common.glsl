/*
 * @file    Common.glsl
 * @author  David Gallardo Moreno
 */


#version 430

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


ivec2 WrapCoord(ivec2 aCoord, ivec2 aSize)
{
    ivec2 lOutCoord = aCoord;

    lOutCoord.x = lOutCoord.x % aSize.x;
    lOutCoord.y = lOutCoord.y % aSize.y;

    lOutCoord.x = (lOutCoord.x < 0) ? aSize.x + lOutCoord.x : lOutCoord.x;
    lOutCoord.y = (lOutCoord.y < 0) ? aSize.y + lOutCoord.y : lOutCoord.y;

    return lOutCoord;
}

int WrapTo(int X, int W)
{
	X = X % W;

	if(X < 0)
	{
		X += W;
	}

    return X;
}

ivec2 WrapTo(ivec2 X, ivec2 W)
{
    X.x = WrapTo(X.x, W.x);
    X.y = WrapTo(X.y, W.y);
    return X;
}

vec4 SampleWarped(layout(rgba16f) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize)
{
    return imageLoad(aSrcImage,  WrapTo(aBaseCoord, aTexSize));
}

vec4 SampleWarped(layout(r16f) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize)
{
    return imageLoad(aSrcImage,  WrapTo(aBaseCoord, aTexSize));
}

vec4 SampleWarped(sampler2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize)
{
    return texelFetch(aSrcImage,  WrapTo(aBaseCoord, aTexSize), 0);
}
