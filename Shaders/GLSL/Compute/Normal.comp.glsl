/*
 * @file    Normal.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba16f) uniform image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0)  uniform float uBumpHeightScale;

ivec2   WrapCoord(ivec2 aCoord, ivec2 aSize);
int     WrapTo(int X, int W);
ivec2   WrapTo(ivec2 X, ivec2 W);
vec4    SampleWarped(layout(rgba16f) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize);

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    ivec2 lTexSize = ivec2(uOutputBufferSize.xy);
    vec4 lInputColor0 = texelFetch(uInputBuffer0, lBufferCoord, 0);

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

    double lHeightScale = uBumpHeightScale * uOutputBufferSize.x / 256.0f;
    double s11 = (1.0 - lInputColor0.r) * lHeightScale;
    double s01 = (1.0 - texelFetch(uInputBuffer0, lCoordList[1], 0).r) * lHeightScale;
    double s21 = (1.0 - texelFetch(uInputBuffer0, lCoordList[2], 0).r) * lHeightScale;
    double s10 = (1.0 - texelFetch(uInputBuffer0, lCoordList[3], 0).r) * lHeightScale;
    double s12 = (1.0 - texelFetch(uInputBuffer0, lCoordList[4], 0).r) * lHeightScale;
    
    //debug: precision clamping
    //s11 = int(s11 * 255) / 255.f;
    //s01 = int(s01 * 255) / 255.f;
    //s21 = int(s21 * 255) / 255.f;
    //s10 = int(s10 * 255) / 255.f;
    //s12 = int(s12 * 255) / 255.f;

    dvec3 va = normalize(dvec3(size.xy,s21-s01));
    dvec3 vb = normalize(dvec3(size.yx,s12-s10));
    dvec4 bump = dvec4( cross(va,vb), s11 );
    
    const vec4 lOutputColor = vec4((bump.xyz + 1.0) * 0.5, lInputColor0.a);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}

/*
void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    ivec2 lTexSize = ivec2(uOutputBufferSize.xy);
    vec4 lInputColor0 = texelFetch(uInputBuffer0, lBufferCoord);


    
	//Coordinates are laid out as follows:
			
	//	0,0 | 1,0 | 2,0
	//	----+-----+----
	//	0,1 | 1,1 | 2,1
	//	----+-----+----
	//	0,2 | 1,2 | 2,2
	
    
    const ivec2 vPixelSize = ivec2(1, 1);
    const ivec2 tc = lBufferCoord;

	// Compute the necessary offsets:
	ivec2 o00 = WrapTo(tc + ivec2( -vPixelSize.x, -vPixelSize.y ), lTexSize);
	ivec2 o10 = WrapTo(tc + ivec2(          0, -vPixelSize.y )  ,  lTexSize);
	ivec2 o20 = WrapTo(tc + ivec2(  vPixelSize.x, -vPixelSize.y ), lTexSize);
                     
	ivec2 o01 = WrapTo(tc + ivec2( -vPixelSize.x, 0             ), lTexSize);
	ivec2 o21 = WrapTo(tc + ivec2(  vPixelSize.x, 0             ), lTexSize);
                     
	ivec2 o02 = WrapTo(tc + ivec2( -vPixelSize.x,  vPixelSize.y ), lTexSize);
	ivec2 o12 = WrapTo(tc + ivec2(             0,  vPixelSize.y ), lTexSize);
	ivec2 o22 = WrapTo(tc + ivec2(  vPixelSize.x,  vPixelSize.y ), lTexSize);

	// Use of the sobel filter requires the eight samples
	// surrounding the current pixel:
    float lHeightScale = uBumpHeightScale * uOutputBufferSize.x / 256.0f;
	float h00 = 1.0 - texelFetch(uInputBuffer0, o00, 0 ).r * lHeightScale;
	float h10 = 1.0 - texelFetch(uInputBuffer0, o10, 0 ).r * lHeightScale;
	float h20 = 1.0 - texelFetch(uInputBuffer0, o20, 0 ).r * lHeightScale;
           
	float h01 = 1.0 - texelFetch(uInputBuffer0, o01, 0 ).r * lHeightScale;
	float h21 = 1.0 - texelFetch(uInputBuffer0, o21, 0 ).r * lHeightScale;
                
	float h02 = 1.0 - texelFetch(uInputBuffer0, o02, 0 ).r * lHeightScale;
	float h12 = 1.0 - texelFetch(uInputBuffer0, o12, 0 ).r * lHeightScale;
	float h22 = 1.0 - texelFetch(uInputBuffer0, o22, 0 ).r * lHeightScale;
			
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

}
*/