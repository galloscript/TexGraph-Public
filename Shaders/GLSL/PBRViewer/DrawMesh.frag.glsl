/*
 * @file    DrawMesh.frag.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

#define M_PI 3.1415926535897932384626433832795
#define M_2PI  6.2831853071795864769252867665590

vec3 toneMapping(vec3 hdrColor, float exposure, float gamma);
float saturate (float x);
vec3 saturate (vec3 v);

struct TLight
{
    vec3 mPosition;
    vec3 mColor;
};

#define MAX_LIGHTS 3
TLight sLights[MAX_LIGHTS] = TLight[MAX_LIGHTS]
(
    TLight(vec3(3.5, -6.0,  8.0), vec3(0.2, 0.2, 0.2) * 800.0),
    TLight(vec3(-16.0, -6.0, 8.0), vec3(0.3, 0.0, 0.0) * 550),
    TLight(vec3(16.0,  16.0, 8.0), vec3(0.05, 0.3, 0.3) * 550)
);

const vec3 sLightPos = vec3(2.5, -9.0, 10.0);

in vec2 ex_TexCoord;
in vec3 ex_Normal;
in vec3 ex_Tangent;
in vec3 ex_Binormal;
in vec4 ex_EyeSpacePosition;
in vec3 ex_FragPosition;
in vec3 ex_TangentViewPosition;
in vec3 ex_TangentFragPosition;
in mat4 ex_ModelViewMatrix;

layout(location = 12) uniform mat4 uBGRotMatrix;
layout(location = 20) uniform samplerCube uEnvCubeMap;
layout(location = 21) uniform sampler2D uIntegratedBRDF;
layout(location = 22) uniform vec4 uViewport;
layout(location = 23) uniform int uAlbedoComponents;

layout(location = 120) uniform sampler2D uAlbedoMap;
layout(location = 121) uniform sampler2D uRoughnessMap;
layout(location = 122) uniform sampler2D uMetalnessMap;
layout(location = 123) uniform sampler2D uNormalMap;
layout(location = 124) uniform sampler2D uHeightMap;   
layout(location = 125) uniform sampler2D uAmbientOcclusionMap;
layout(location = 126) uniform sampler2D uEmissiveMap;
layout(location = 127) uniform sampler2D uCustomMap0;
layout(location = 128) uniform sampler2D uCustomMap1;
layout(location = 129) uniform sampler2D uCustomMap2;
layout(location = 130) uniform sampler2D uCustomMap3;
layout(location = 131) uniform sampler2D uCustomMap4;
layout(location = 132) uniform sampler2D uCustomMap5;
layout(location = 133) uniform sampler2D uCustomMap6;
layout(location = 134) uniform sampler2D uCustomMap7;
layout(location = 135) uniform sampler2D uCustomMap8;

layout(location = 0) out vec4 out_Color;
/*layout(location = 1) out vec4 out_AuxValues;
layout(location = 2) out vec4 out_Normal;
layout(location = 3) out vec4 out_Position;
layout(location = 4) out vec4 out_PBRInfo;*/

const float uEmissiveIntensity = 8;

vec3 InvertY(in vec3 aVec3)
{
    return vec3(aVec3.x, 1.0 - aVec3.y, aVec3.z);
}

vec3 TangentToWorldNormal(in vec3 aTangentSpaceNormal)
{
    mat3 lTangentToWorld = mat3(ex_Tangent.x, ex_Binormal.x, ex_Normal.x,
                                ex_Tangent.y, ex_Binormal.y, ex_Normal.y,
                                ex_Tangent.z, ex_Binormal.z, ex_Normal.z);

    return normalize( ((aTangentSpaceNormal * 2.0) - 1.0) * lTangentToWorld );
}

// taken from ue4
float ComputeCubemapMipFromRoughness( float Roughness, float MipCount )
{
	// Level starting from 1x1 mip
	float Level = 3 - 1.15 * log2( Roughness );
	return (MipCount - 1) - Level;
}

// taken from ue4
vec3 EnvBRDF( vec3 SpecularColor, float Roughness, float NoV )
{
    Roughness = max(0.002, min(0.998, Roughness));
	vec2 AB =  textureLod(uIntegratedBRDF, vec2(NoV, Roughness), 0).rg; //review this
	//vec3 GF = SpecularColor * AB.x + saturate( 50.0 * SpecularColor.g ) * AB.y;
	vec3 GF = SpecularColor * AB.x + AB.y;
	return GF;
}

// Blend between dielectric and metallic materials.
// Note: The range of semiconductors is approx. [0.2, 0.45]
vec3 BlendMaterial(vec3 Kdiff, vec3 Kspec, vec3 Kbase, float metallic)
{
    //float scRange = clamp(0.2, 0.45, metallic);
    float scRange = metallic;
    vec3  dielectric = Kdiff + Kspec;
    vec3  metal = Kspec * Kbase;
    return mix(dielectric, metal, scRange);
}


vec4 CubeMapExposure(samplerCube _cubeMap, vec3 _n, float _lod, float _exposure)
{
    return textureLod(_cubeMap, mat3(uBGRotMatrix) * _n, _lod);// * pow(2.0, _exposure);
}
/*
vec2 ParallaxMapping(vec2 texCoords, vec3 viewDir)
{ 
    float height =  texture(uHeightMap, texCoords).r;    
    vec2 p = viewDir.xy / viewDir.z * (height * 0.1);
    return texCoords - p;    
} 
*/

float GetHeight(vec2 texCoords)
{
    return 1.0 - texture(uHeightMap, texCoords).r;
}

//Parallax Occlusion Mapping from: https://learnopengl.com/Advanced-Lighting/Parallax-Mapping
vec2 ParallaxMapping(vec2 texCoords, vec3 viewDir)
{ 
    const float height_scale = 0.05;
    // number of depth layers
    const float minLayers = 8.0;
    const float maxLayers = 16.0;
    float numLayers = mix(maxLayers, minLayers, abs(dot(vec3(0.0, 0.0, 1.0), viewDir)));  
    // calculate the size of each layer
    float layerDepth = 1.0 / numLayers;
    // depth of current layer
    float currentLayerDepth = 0.0;
    // the amount to shift the texture coordinates per layer (from vector P)
    vec2 P = viewDir.xy * height_scale; 
    vec2 deltaTexCoords = P / numLayers; 

    // get initial values
    vec2  currentTexCoords     = texCoords;
    float currentDepthMapValue = GetHeight(currentTexCoords);
  
    while(currentLayerDepth < currentDepthMapValue)
    {
        // shift texture coordinates along direction of P
        currentTexCoords -= deltaTexCoords;
        // get depthmap value at current texture coordinates
        currentDepthMapValue = GetHeight(currentTexCoords);  
        // get depth of next layer
        currentLayerDepth += layerDepth;  
    }

    // get texture coordinates before collision (reverse operations)
    vec2 prevTexCoords = currentTexCoords + deltaTexCoords;

    // get depth after and before collision for linear interpolation
    float afterDepth  = currentDepthMapValue - currentLayerDepth;
    float beforeDepth = GetHeight(prevTexCoords) - currentLayerDepth + layerDepth;
 
    // interpolation of texture coordinates
    float weight = afterDepth / (afterDepth - beforeDepth);
    vec2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

    return finalTexCoords;  
} 
vec3 PBR_IBL()
{
    vec3 lViewDir = normalize(ex_TangentViewPosition.xyz - ex_TangentFragPosition.xyz);
    vec2 lTexCoord = ParallaxMapping(ex_TexCoord.xy, lViewDir);
    vec3 lAlbedo = (uAlbedoComponents == 1) ? texture(uAlbedoMap, lTexCoord.xy).rrr : texture(uAlbedoMap, lTexCoord.xy).rgb;
    vec3 lEmissive = texture(uEmissiveMap, lTexCoord.xy).rgb;
    float lAO = texture(uAmbientOcclusionMap, lTexCoord.xy).r;
    float lRoughness = texture(uRoughnessMap, lTexCoord.xy).r;
    float lMetallic = texture(uMetalnessMap, lTexCoord.xy).r;
    vec3 lNormal =  TangentToWorldNormal(InvertY(texture(uNormalMap, lTexCoord.xy).rgb));
    //vec3 lNormal =  ex_Normal.xyz;
    
    float lEnvExposure = 0.1;

    vec3 lPosition = ex_EyeSpacePosition.xyz;
    vec3 I = normalize(lPosition);
    //vec3 R = refract(I, -normal, 0.5);
    vec3 R = normalize(reflect(I, -lNormal));
    //float ndotv = max( dot( normal, vec3(0.0, 0.0, -150.0)),0.0);
        
        
    float lAbsoluteSpecularMip = ComputeCubemapMipFromRoughness(lRoughness, 10.0);
    vec3 lEnvMapColor = CubeMapExposure(uEnvCubeMap, -R, lAbsoluteSpecularMip, lEnvExposure).rgb;
    float NoV = saturate(dot(lNormal, -I));
        
    float lNonMetalSpec = 0.08;
    vec3 lSpecularColor = (lNonMetalSpec - lNonMetalSpec * lMetallic) + vec3(1.0) * lMetallic;
    //specularColor = max(specularColor, vec3(0.1));
    vec3 lDiffuseColor = lAlbedo.rgb - lAlbedo.rgb * lMetallic;
    vec3 lIblSpecular = lEnvMapColor * EnvBRDF(lSpecularColor, lRoughness, NoV);
    //vec3 iblSpecular = ApproximateSpecularIBL(uEnvCubeMap, uEnvBRDF, specularColor, Roughness, NoV, R);
        
        
    float lHorizonOcclusion = 1.3;
	float lHorizon = saturate( 1.0 + lHorizonOcclusion * dot(R, lNormal));
	lHorizon *= lHorizon;
        
    lIblSpecular = lIblSpecular * lHorizon;
    vec3 lIrradianceColor = CubeMapExposure(uEnvCubeMap, -R, 8.0, lEnvExposure).rgb;
    vec3 lIblDiffuse = lDiffuseColor * lIrradianceColor / M_PI;

    vec3 lFinalColor = vec3(0);
    lFinalColor += lAlbedo.rgb * ((lMetallic > 0.001) ? max(0.5, lRoughness) : 1.0);
    lFinalColor += BlendMaterial(lIblDiffuse, lIblSpecular, lAlbedo.rgb, lMetallic);

    return (lFinalColor * lAO) + (lEmissive * uEmissiveIntensity);
}

float DistributionGGX(vec3 N, vec3 H, float roughness);
float GeometrySchlickGGX(float NdotV, float roughness);
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness);
vec3 fresnelSchlick(float cosTheta, vec3 F0);

vec3 PBR_DirectLighting()
{
    vec3 lViewDir = normalize(ex_TangentViewPosition.xyz - ex_TangentFragPosition.xyz);
    vec2 lTexCoord = ParallaxMapping(ex_TexCoord.xy, lViewDir);
    vec3 lAlbedo = texture(uAlbedoMap, lTexCoord.xy).rgb;
    vec3 lEmissive = texture(uEmissiveMap, lTexCoord.xy).rgb;
    float lAO = texture(uAmbientOcclusionMap, lTexCoord.xy).r;
    float lRoughness = texture(uRoughnessMap, lTexCoord.xy).r;
    float lMetallic = texture(uMetalnessMap, lTexCoord.xy).r;
    vec3 lNormal =  TangentToWorldNormal(InvertY(texture(uNormalMap, lTexCoord.xy).rgb));

    vec3 N = normalize(lNormal);
    vec3 V = lViewDir;

    vec3 F0 = vec3(0.04); 
    F0 = mix(F0, lAlbedo, lMetallic);
	           
    // reflectance equation
    vec3 Lo = vec3(0.0);
    for(int i = 0; i < MAX_LIGHTS; ++i) 
    {
        // calculate per-light radiance
        vec3 L = normalize(sLights[i].mPosition - ex_EyeSpacePosition.xyz);
        vec3 H = normalize(V + L);
        float distance    = length(sLights[i].mPosition - ex_EyeSpacePosition.xyz);
        float attenuation = 1.0 / (distance * distance);
        vec3 radiance     = sLights[i].mColor * attenuation;        
        
        // cook-torrance brdf
        float NDF = DistributionGGX(N, H, lRoughness);        
        float G   = GeometrySmith(N, V, L, lRoughness);      
        vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);       
        
        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        kD *= 1.0 - lMetallic;	  
        
        vec3 numerator    = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
        vec3 specular     = numerator / max(denominator, 0.001);  
            
        // add to outgoing radiance Lo
        float NdotL = max(dot(N, L), 0.0);
        Lo += (kD * lAlbedo / M_PI + specular) * radiance * NdotL;
    }   
  
    vec3 ambient = vec3(0.01) * lAlbedo;
    vec3 color = ambient + Lo;
	
    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0/2.2));  
   
    return (color * lAO) + (lEmissive * uEmissiveIntensity);
}

void main(void)
{
    out_Color = vec4(0, 0, 0, 1);
    //vec3 lTextureColor = texture(uAlbedoMap, ex_TexCoord.xy).xyz;
   // float lRoughness = texture(uRoughnessMap, ex_TexCoord.xy).x;
    //lTextureColor = lTextureColor * textureLod(uEnvCubeMap, -ex_Normal.xyz, lRoughness * 8.0).xyz;
    //lTextureColor = textureLod(uIntegratedBRDF, ex_TexCoord.xy, 0).xyz;

    out_Color.rgb = PBR_IBL();
    //out_Color.rgb = PBR_DirectLighting();
   /*
    for(int lLightIndex = 0; lLightIndex < MAX_LIGHTS; lLightIndex++)
    {
        vec3 N = ex_Normal.xyz;
        vec3 L = normalize(sLights[lLightIndex].mPosition - ex_EyeSpacePosition.xyz);
        vec3 E = normalize(-ex_EyeSpacePosition.xyz); // we are in Eye Coordinates, so EyePos is (0,0,0)  
        vec3 R = normalize(-reflect(L, N));  

        //calculate Diffuse Term:  
        vec3 Idiff = sLights[lLightIndex].mColor * max(dot(N,L), 0.0) * 0.2;
        Idiff = clamp(Idiff, 0.0, 100.0);

        out_Color.rgb += Idiff;  
    }*/
    
    //out_Color.rgb += 0.15;

    //dot(ex_Normal.xyz, normalize(sLights[0].mPosition - ex_EyeSpacePosition.xyz));
    
    //out_Color.rgb = pow( out_Color.rgb, vec3(0.8545) );

    //out_Color.rgb = toneMapping(out_Color.rgb, 2.6, 0.55);

   // out_Color.rgb = gl_FragCoord.xxx / uViewport.x;
    //out_Color = vec4(vec3(ex_TexCoord.x, ex_TexCoord.y, 0.0), 1.0);
    //out_Color = vec4(texture(uAlbedoMap, ex_TexCoord.xy).xyz, 1.0);
    
}
