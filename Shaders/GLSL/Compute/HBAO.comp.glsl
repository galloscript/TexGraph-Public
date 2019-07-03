 /*
 * @file    HBAO.comp.glsl
 * @author  David Gallardo Moreno
 * @reference https://github.com/scanberg/hbao/blob/master/resources/shaders/hbao_frag.glsl
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout (std140, binding = 20) uniform SBRandomVectorsBlock 
{
    double gRandomVectors [1024]; // This is the important name (in the shader).
};

layout(location = 0) uniform float uRadius;

const float PI = 3.14159265;

const vec2 FocalLen = vec2(0.0025);
//uniform vec2 UVToViewA;
//uniform vec2 UVToViewB;

//uniform vec2 LinMAD;// = vec2(0.1-10.0, 0.1+10.0) / (2.0*0.1*10.0);

const vec2 AORes = vec2(uOutputBufferSize.xy);
const vec2 InvAORes = 1.0 / AORes;
const vec2 NoiseScale = AORes / 4.0;

const float AOStrength = 0.9;
const float R = uRadius;
const float R2 = R*R;
const float NegInvR2 = - 1.0 / (R2);
const float TanBias = tan(30.0 * PI / 180.0);
const float MaxRadiusPixels = 50.0;

const int NumDirections = 6;
const int NumSamples = 4;

ivec2   WrapCoord(ivec2 aCoord, ivec2 aSize);
int     WrapTo(int X, int W);
ivec2   WrapTo(ivec2 X, ivec2 W);
vec4    SampleWarped(layout(rgba16f) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize);
vec4    SampleWarped(layout(r16f) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize);
vec4    SampleWarped(sampler2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize);

//------------------------------------------------------------------------
vec2 Hash2(vec2 p, int aSeed);
double ValueNoise3D (int x, int y, int z, int seed);
//------------------------------------------------------------------------

vec3 UVToViewSpace(vec2 uv, float z)
{
	//uv = UVToViewA * uv + UVToViewB;
	//return vec3(uv * z, z);
    return vec3((0.5 * uv - 0.5) * z, z);
}

vec3 GetViewPos(vec2 uv)
{
	//float z = ViewSpaceZFromDepth(texture(texture0, uv).r);
	float z = SampleWarped(uInputBuffer0, ivec2(uv * uOutputBufferSize.xy), uOutputBufferSize.xy).r;
	return UVToViewSpace(uv, z);
}

float TanToSin(float x)
{
	return x * inversesqrt(x*x + 1.0);
}

float InvLength(vec2 V)
{
	return inversesqrt(dot(V,V));
}

float Tangent(vec3 V)
{
	return V.z * InvLength(V.xy);
}

float BiasedTangent(vec3 V)
{
	return V.z * InvLength(V.xy) + TanBias;
}

float Tangent(vec3 P, vec3 S)
{
    return -(P.z - S.z) * InvLength(S.xy - P.xy);
}

float Length2(vec3 V)
{
	return dot(V,V);
}

vec3 MinDiff(vec3 P, vec3 Pr, vec3 Pl)
{
    vec3 V1 = Pr - P;
    vec3 V2 = P - Pl;
    return (Length2(V1) < Length2(V2)) ? V1 : V2;
}

vec2 SnapUVOffset(vec2 uv)
{
    return round(uv * AORes) * InvAORes;
}

float Falloff(float d2)
{
	return d2 * NegInvR2 + 1.0f;
}

float HorizonOcclusion(	vec2 TexCoord,
                        vec2 deltaUV,
						vec3 P,
						vec3 dPdu,
						vec3 dPdv,
						float randstep,
						float numSamples)
{
	float ao = 0;

	// Offset the first coord with some noise
	vec2 uv = TexCoord + SnapUVOffset(randstep*deltaUV);
	deltaUV = SnapUVOffset( deltaUV );

	// Calculate the tangent vector
	vec3 T = deltaUV.x * dPdu + deltaUV.y * dPdv;

	// Get the angle of the tangent vector from the viewspace axis
	float tanH = BiasedTangent(T);
	float sinH = TanToSin(tanH);

	float tanS;
	float d2;
	vec3 S;

	// Sample to find the maximum angle
	for(float s = 1; s <= numSamples; ++s)
	{
		uv += deltaUV;
		S = GetViewPos(uv);
		tanS = Tangent(P, S);
		d2 = Length2(S - P);

		// Is the sample within the radius and the angle greater?
		if(d2 < R2 && tanS > tanH)
		{
			float sinS = TanToSin(tanS);
			// Apply falloff based on the distance
			ao += Falloff(d2) * (sinS - sinH);

			tanH = tanS;
			sinH = sinS;
		}
	}
	
	return ao;
}

vec2 RotateDirections(vec2 Dir, vec2 CosSin)
{
    return vec2(Dir.x*CosSin.x - Dir.y*CosSin.y,
                  Dir.x*CosSin.y + Dir.y*CosSin.x);
}

void ComputeSteps(inout vec2 stepSizeUv, inout float numSteps, float rayRadiusPix, float rand)
{
    // Avoid oversampling if numSteps is greater than the kernel radius in pixels
    numSteps = min(NumSamples, rayRadiusPix);

    // Divide by Ns+1 so that the farthest samples are not fully attenuated
    float stepSizePix = rayRadiusPix / (numSteps + 1);

    // Clamp numSteps if it is greater than the max kernel footprint
    float maxNumSteps = MaxRadiusPixels / stepSizePix;
    if (maxNumSteps < numSteps)
    {
        // Use dithering to avoid AO discontinuities
        numSteps = floor(maxNumSteps + rand);
        numSteps = max(numSteps, 1);
        stepSizePix = MaxRadiusPixels / numSteps;
    }

    // Step size in uv space
    stepSizeUv = stepSizePix * InvAORes;
}

float GenerateHBAO(vec2 TexCoord)
{
	float numDirections = NumDirections;

	vec3 P, Pr, Pl, Pt, Pb;
	P 	= GetViewPos(TexCoord);

	// Sample neighboring pixels
    vec2 lDeltaMultiplier = vec2(uOutputBufferSize.xy) / 256.0f;
    vec2 lAdjadcentCoord = InvAORes * lDeltaMultiplier;
    Pr 	= GetViewPos(TexCoord + vec2( lAdjadcentCoord.x, 0));
    Pl 	= GetViewPos(TexCoord + vec2(-lAdjadcentCoord.x, 0));
    Pt 	= GetViewPos(TexCoord + vec2( 0, lAdjadcentCoord.y));
    Pb 	= GetViewPos(TexCoord + vec2( 0,-lAdjadcentCoord.y));

    // Calculate tangent basis vectors using the minimu difference
    vec3 dPdu = MinDiff(P, Pr, Pl);
    vec3 dPdv = MinDiff(P, Pt, Pb) * (AORes.y * InvAORes.x);

    // Get the random samples from the noise texture
	//vec3 random = texture(texture1, TexCoord.xy * NoiseScale).rgb;
    vec2 lRandUV = Hash2(TexCoord, 0);
    uint lRndIndex = uint(((lRandUV.x * 15.) + (lRandUV.y * 15.)) * 4.);
    vec3 random = abs(vec3(gRandomVectors[lRndIndex], gRandomVectors[lRndIndex + 1], gRandomVectors[lRndIndex + 2]));

	// Calculate the projected size of the hemisphere
    vec2 rayRadiusUV = 0.5 * R * FocalLen / P.z;
    float rayRadiusPix = rayRadiusUV.x * AORes.x;

    float ao = 1.0;

    // Make sure the radius of the evaluated hemisphere is more than a pixel
    if(rayRadiusPix > 1.0)
    {
    	ao = 0.0;
    	float numSteps;
    	vec2 stepSizeUV;

    	// Compute the number of steps
    	ComputeSteps(stepSizeUV, numSteps, rayRadiusPix, random.z);

		float alpha = 2.0 * PI / numDirections;

		// Calculate the horizon occlusion of each direction
		for(float d = 0; d < numDirections; ++d)
		{
			float theta = alpha * d;

			// Apply noise to the direction
			vec2 dir = RotateDirections(vec2(cos(theta), sin(theta)), random.xy);
			vec2 deltaUV = dir * stepSizeUV;

			// Sample the pixels along the direction
			ao += HorizonOcclusion(	TexCoord,
                                    deltaUV,
									P,
									dPdu,
									dPdv,
									random.z,
									numSteps);
		}

		// Average the results and produce the final AO
		ao = 1.0 - ao / numDirections * AOStrength;
        //ao = P.y;
	}
    //ao = abs(random.z);
	return ao;
}


 
void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //vec4 lInputColor = texelFetch(uInputBuffer0, lBufferCoord, 0);
    float lOutputValue = clamp(GenerateHBAO(lUV), 0., 1.);
    imageStore (uOutputBuffer0, lBufferCoord, vec4(vec3(lOutputValue), 1.0));
}

