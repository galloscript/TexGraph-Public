/*
 * @file    Bloom.comp.glsl
 * @author  David Gallardo Moreno
 * @reference See BloomFilter.comp.glsl
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba16f) uniform image2D uOutputBuffer0;
layout(location = 0) uniform sampler2D uInputColor;
layout(location = 1) uniform sampler2D uBloomPyramid;
layout(location = 2) uniform ivec3 uViewportSize;

// Render Settings Block
layout (std140, binding = 10) uniform SBRenderSettings
{
    vec4 uToneMapping;  //[x] = Saturation, [y] = Brightness, [z] = {unused}, [w] = {unused}
    vec4 uBloom;        //[x] = BloomSize, [y] = ColorRange, [z] = Threshold, [w] = {unused}
    vec4 uBackground;   //[x] = BgAlpha, [y] = BgGamma [z] = BgBlur, [w] = {unused}
    ivec4 uFlags;       //[x] = BloomActive
};

uniform float uColorRange = 20.0;

vec3 toneMapping(vec3 hdrColor, float exposure, float gamma)
{
    // Exposure tone mapping
    vec3 mapped = vec3(1.0) - exp(-hdrColor * exposure);
    
    // Gamma correction
    mapped = pow(mapped, vec3(1.0 / gamma));
    
    return mapped;
}

vec3 jodieReinhardTonemap(vec3 c)
{
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c / (c + 1.0);

    return mix(c / (l + 1.0), tc, tc);
}

vec3 bloomTile(float lod, vec2 offset, vec2 uv)
{
    return textureLod(uBloomPyramid, uv * exp2(-lod) + offset, 0).rgb;
}

vec3 getBloom(vec2 uv)
{
    vec3 blur = vec3(0.0);
    vec2 lOffsetFix = vec2(0.00025, 0.0005);
    blur = pow(bloomTile(2., vec2(0.0, 0.0) + lOffsetFix, uv),vec3(2.2))       	   	+ blur;
    blur = pow(bloomTile(3., vec2(0.3, 0.0) + lOffsetFix, uv),vec3(2.2)) * 1.3        + blur;
    blur = pow(bloomTile(4., vec2(0.0, 0.3) + lOffsetFix, uv),vec3(2.2)) * 1.6        + blur;
    blur = pow(bloomTile(5., vec2(0.1, 0.3) + lOffsetFix, uv),vec3(2.2)) * 1.9 	   	+ blur;
    blur = pow(bloomTile(6., vec2(0.2, 0.3) + lOffsetFix, uv),vec3(2.2)) * 2.2 	   	+ blur;

    return blur * uBloom.y;
}
/*
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec3 color = pow(texture(uInputTexture, uv).rgb * COLOR_RANGE, vec3(2.2));
    color = pow(color, vec3(2.2));
    color += pow(getBloom(uv), vec3(2.2));
    color = pow(color, vec3(1.0 / 2.2));
    color = jodieReinhardTonemap(color);
    
	fragColor = vec4(color, 1.0);
}
*/
void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 lPixelSize = vec2(1.0, 1.0) / textureSize(uInputColor, 0).xy;
    vec2 lUV = vec2(lBufferCoord.xy) * lPixelSize;
    vec4 lInputColor = texture(uInputColor, lUV).rgba;
    vec3 color = pow(lInputColor.rgb * uToneMapping.y, vec3(uToneMapping.x));
         color = pow(color, vec3(2.2));
         if(uFlags.x == 1)
         {
            color += pow(getBloom(lUV) * uToneMapping.y, vec3(2.2));
         }
         color = pow(color, vec3(1.0 / 2.2));
         color = jodieReinhardTonemap(color);
         //color = toneMapping(color, 1.1, 0.66);
         
         //color = pow(getBloom(lUV), vec3(2.2));

         //color = bloomTile(3., vec2(0.3, 0.0), lUV);

    /*vec3 color = texture(uInputColor, lUV).rgb;
         color = pow(color, vec3(2.2));
         color += pow(getBloom(lUV), vec3(2.2));
         color = pow(color, vec3(1.0 / 2.2));
         color = jodieReinhardTonemap(color, 1.0, 1.0);*/

    vec4 lOutputColor = vec4(color, lInputColor.a);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor); 
}
 