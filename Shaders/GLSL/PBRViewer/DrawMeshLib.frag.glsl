/*
 * @file    DrawMeshLib.frag.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

#define M_PI 3.1415926535897932384626433832795
#define M_2PI  6.2831853071795864769252867665590
#define XAxis vec3(1.0, 0.0, 0.0)
#define YAxis vec3(0.0, 1.0, 0.0)
#define ZAxis vec3(0.0, 0.0, 1.0)
#define KWhite vec3(1.0, 1.0, 1.0)
        
float saturate (float x)
{
    return clamp(x, 0.0, 1.0);
}

vec3 saturate (vec3 v)
{
    return clamp(v, 0.0, 1.0);
}

vec2 normal2uv(vec3 N)
{
    float nu = 0.5 + (atan(N.z, N.x) / (2.0 * M_PI));
    float nv = 0.5 - (asin(N.y) / (1.0 * M_PI));
    vec2 tc = vec2(nu, nv);
    return tc;
}

float radicalInverse_VdC(uint bits)
{
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}
        
// Hammersley function (return random low-discrepency points)
vec2 Hammersley(uint i, uint N)
{
    return vec2(float(i) / float(N), float(radicalInverse_VdC(i)));
}

vec3 ImportanceSampleGGX( vec2 Xi, float Roughness, vec3 N )
{
    float a = Roughness * Roughness;
    float Phi = 2 * M_PI * Xi.x;
    float CosTheta = sqrt( (1 - Xi.y) / ( 1 + (a*a - 1) * Xi.y ) );
    float SinTheta = sqrt( 1 - CosTheta * CosTheta );
    vec3 H;
    H.x = SinTheta * cos( Phi );
    H.y = SinTheta * sin( Phi );
    H.z = CosTheta;
    vec3 UpVector = abs(N.z) < 0.999 ? vec3(0,0,1) : vec3(1,0,0);
    vec3 TangentX = normalize( cross( UpVector, N ) );
    vec3 TangentY = cross( N, TangentX );
    
    // Tangent to world space
    return TangentX * H.x + TangentY * H.y + N * H.z;
}


// http://graphicrants.blogspot.com.au/2013/08/specular-brdf-reference.html
float GGX(float NdotV, float a)
{
    float k = a / 2;
    return NdotV / (NdotV * (1.0f - k) + k);
}

// http://graphicrants.blogspot.com.au/2013/08/specular-brdf-reference.html
float G_Smith(float a, float nDotV, float nDotL)
{
    return GGX(nDotL, a * a) * GGX(nDotV, a * a);
}

vec3 toneMapping(vec3 hdrColor, float exposure, float gamma)
{
    // Exposure tone mapping
    vec3 mapped = vec3(1.0) - exp(-hdrColor * exposure);
    
    // Gamma correction
    mapped = pow(mapped, vec3(1.0 / gamma));
    
    return mapped;
}
