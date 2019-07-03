/*
 * @file    Bloom.comp.glsl
 * @author  David Gallardo Moreno
 * @reference https://www.shadertoy.com/view/lsBfRc
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba16f) uniform image2D uOutputBuffer0;
layout(location = 0) uniform sampler2D uInputTexture;

layout(location = 1) uniform ivec3 uViewportSize;

// Render Settings Block
layout (std140, binding = 10) uniform SBRenderSettings
{
    vec4 uToneMapping;  //[x] = Saturation, [y] = Brightness, [z] = {unused}, [w] = {unused}
    vec4 uBloom;        //[x] = BloomSize, [y] = ColorRange, [z] = Threshold, [w] = {unused}
    vec4 uBackground;   //[x] = BgAlpha, [y] = BgGamma [z] = BgBlur, [w] = {unused}
    ivec4 uFlags;       //[x] = BloomActive
};

vec3 makeBloom(float lod, vec2 offset, vec2 bCoord, vec2 aPixelSize)
{
    offset += aPixelSize;

    float lodFactor = exp2(lod);

    vec3 bloom = vec3(0.0);
    vec2 scale = lodFactor * aPixelSize;

    vec2 coord = (bCoord.xy-offset)*lodFactor;
    float totalWeight = 0.0;

    if (any(greaterThanEqual(abs(coord - 0.5), scale + 0.5)))
        return vec3(0.0);

    //TODO: use uViewportSize to discard pixels that doens't contain scene data

    for (int i = -5; i < 5; i++) 
    {
        for (int j = -5; j < 5; j++) 
        {
            float wg = pow(1.0-length(vec2(i,j)) * 0.125, 6.0); //* 0.125, 8.0
            vec3 lTextureColor = textureLod(uInputTexture, vec2(i,j) * scale + lodFactor * aPixelSize + coord, lod).rgb;
            lTextureColor = (any(greaterThan(lTextureColor, vec3(uBloom.z)))) ? lTextureColor * uBloom.x : vec3(0.0);
            lTextureColor = pow(lTextureColor, vec3(2.2)) * wg;
            bloom = lTextureColor + bloom;

            totalWeight += wg;
            
        }
    }

    bloom /= totalWeight;

    return bloom;
}


void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 lPixelSize = vec2(1.0, 1.0) / textureSize(uInputTexture, 0).xy;
    //vec2 lPixelSize = vec2(1.0, 1.0) / uViewportSize.xy;
    vec2 lUV = vec2(lBufferCoord.xy) * lPixelSize;
    //vec4 lInputColor = texelFetch(uInputTexture, lBufferCoord, 0);
    vec4 lInputColor0 = imageLoad(uOutputBuffer0, lBufferCoord);

    vec3 lBlur  = makeBloom(2., vec2(0.0, 0.0), lUV, lPixelSize);
	     lBlur += makeBloom(3., vec2(0.3, 0.0), lUV, lPixelSize);
	     lBlur += makeBloom(4., vec2(0.0, 0.3), lUV, lPixelSize);
	     lBlur += makeBloom(5., vec2(0.1, 0.3), lUV, lPixelSize);
	     lBlur += makeBloom(6., vec2(0.2, 0.3), lUV, lPixelSize);

    //lBlur = (any(greaterThan(lBlur, vec3(.5)))) ? lBlur : vec3(0);

    vec4 lOutputColor = vec4(clamp(pow(lBlur, vec3(1.0 / 2.2)), vec3(0), vec3(100)), 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, mix(lInputColor0, lOutputColor, 0.4)); 
    //imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);  
}
 