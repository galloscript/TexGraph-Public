/*
 * @file    Normal.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D uOutputBuffer0;
layout(binding = 1, rgba8) uniform image2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform float uBumpHeightScale;


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


vec4 SampleWarped(layout(rgba8) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize)
{
    return imageLoad(aSrcImage,  WrapTo(aBaseCoord, aTexSize));
}

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    ivec2 lTexSize = ivec2(uOutputBufferSize.xy);
    vec4 lInputColor0 = imageLoad(uInputBuffer0, lBufferCoord);

    const vec2 size = vec2(2.0,0.0);
    const ivec2 lAdjacentCoord = ivec2(1, 1); //max(ivec2(1, 1), ivec2(uOutputBufferSize.x / 512.0f, uOutputBufferSize.y / 512.0f)); 
     
    ivec2 lCoordList[5] = ivec2[5]
    (
        ivec2(lBufferCoord.x,     lBufferCoord.y    ),
        ivec2(WrapTo(lBufferCoord.x - lAdjacentCoord.x, lTexSize.x), lBufferCoord.y    ),
        ivec2(WrapTo(lBufferCoord.x + lAdjacentCoord.x, lTexSize.x), lBufferCoord.y    ),
        ivec2(lBufferCoord.x,     WrapTo(lBufferCoord.y - lAdjacentCoord.y, lTexSize.y)),
        ivec2(lBufferCoord.x,     WrapTo(lBufferCoord.y + lAdjacentCoord.y, lTexSize.y))
    );

    float s11 = (1.0 - lInputColor0.r) * uBumpHeightScale;
    float s01 = (1.0 - imageLoad(uInputBuffer0, lCoordList[1]).r) * uBumpHeightScale;
    float s21 = (1.0 - imageLoad(uInputBuffer0, lCoordList[2]).r) * uBumpHeightScale;
    float s10 = (1.0 - imageLoad(uInputBuffer0, lCoordList[3]).r) * uBumpHeightScale;
    float s12 = (1.0 - imageLoad(uInputBuffer0, lCoordList[4]).r) * uBumpHeightScale;
    
    vec3 va = normalize(vec3(size.xy,s21-s01));
    vec3 vb = normalize(vec3(size.yx,s12-s10));
    vec4 bump = vec4( cross(va,vb), s11 );
    
    const vec4 lOutputColor = vec4((bump.xyz + 1.0) * 0.5, lInputColor0.a);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}

/*
void main(void)
{
    const ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    vec4 lInputColor0 = imageLoad(uInputBuffer0, lBufferCoord);


    
	//Coordinates are laid out as follows:
			
	//	0,0 | 1,0 | 2,0
	//	----+-----+----
	//	0,1 | 1,1 | 2,1
	//	----+-----+----
	//	0,2 | 1,2 | 2,2
	
    
    const ivec2 vPixelSize = ivec2(1, 1);
    const ivec2 tc = lBufferCoord;

	// Compute the necessary offsets:
	ivec2 o00 = tc + ivec2( -vPixelSize.x, -vPixelSize.y );
	ivec2 o10 = tc + ivec2(          0, -vPixelSize.y );
	ivec2 o20 = tc + ivec2(  vPixelSize.x, -vPixelSize.y );
                     
	ivec2 o01 = tc + ivec2( -vPixelSize.x, 0             );
	ivec2 o21 = tc + ivec2(  vPixelSize.x, 0             );
                     
	ivec2 o02 = tc + ivec2( -vPixelSize.x,  vPixelSize.y );
	ivec2 o12 = tc + ivec2(             0,  vPixelSize.y );
	ivec2 o22 = tc + ivec2(  vPixelSize.x,  vPixelSize.y );

	// Use of the sobel filter requires the eight samples
	// surrounding the current pixel:
	float h00 = 1.0 - imageLoad(uInputBuffer0, o00 ).r * uBumpHeightScale;
	float h10 = 1.0 - imageLoad(uInputBuffer0, o10 ).r * uBumpHeightScale;
	float h20 = 1.0 - imageLoad(uInputBuffer0, o20 ).r * uBumpHeightScale;
           
	float h01 = 1.0 - imageLoad(uInputBuffer0, o01 ).r * uBumpHeightScale;
	float h21 = 1.0 - imageLoad(uInputBuffer0, o21 ).r * uBumpHeightScale;
                
	float h02 = 1.0 - imageLoad(uInputBuffer0, o02 ).r * uBumpHeightScale;
	float h12 = 1.0 - imageLoad(uInputBuffer0, o12 ).r * uBumpHeightScale;
	float h22 = 1.0 - imageLoad(uInputBuffer0, o22 ).r * uBumpHeightScale;
			
	// The Sobel X kernel is:
	//
	// [ 1.0  0.0  -1.0 ]
	// [ 2.0  0.0  -2.0 ]
	// [ 1.0  0.0  -1.0 ]
			
	float Gx = h00 - h20 + 2.0f * h01 - 2.0f * h21 + h02 - h22;
						
	// The Sobel Y kernel is:
	//
	// [  1.0    2.0    1.0 ]
	// [  0.0    0.0    0.0 ]
	// [ -1.0   -2.0   -1.0 ]
			
	float Gy = h00 + 2.0f * h10 + h20 - h02 - 2.0f * h12 - h22;
			
	// Generate the missing Z component - tangent
	// space normals are +Z which makes things easier
	// The 0.5f leading coefficient can be used to control
	// how pronounced the bumps are - less than 1.0 enhances
	// and greater than 1.0 smoothes.
	float Gz = 0.5f * sqrt( 1.0f - Gx * Gx - Gy * Gy );

	// Make sure the returned normal is of unit length
	vec3 lNormal = normalize( vec3( 2.0f * Gx, 2.0f * Gy, Gz ) );

    const vec4 lOutputColor = vec4((lNormal + 1.0) * 0.5, lInputColor0.a);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);

}*/