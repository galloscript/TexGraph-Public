/*
 * @file    Blur.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset; 
layout(location = 102) uniform ivec4 uInputFormat;
layout(location = 103) uniform ivec4 uOutputFormat;


layout(binding = 0) uniform writeonly image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;
layout(location = 81) uniform sampler2D uInputBuffer1;
layout(location = 82) uniform sampler2D uInputBuffer2;
layout(location = 83) uniform sampler2D uInputBuffer3;


//layout(location = 0) uniform int    uKernelSize;
//layout(location = 1) uniform float  uSigma;
layout(location = 0) uniform float  uArea;

const float sKernelTableA[5][5] =  float[][](float[](0.003765,    0.015019,    0.023792,    0.015019,    0.003765),
                                            float[](0.015019,    0.059912,    0.094907,    0.059912,    0.015019),
                                            float[](0.023792,    0.094907,    0.150342,    0.094907,    0.023792),
                                            float[](0.015019,    0.059912,    0.094907,    0.059912,    0.015019),
                                            float[](0.003765,    0.015019,    0.023792,    0.015019,    0.003765));

const float sKernelTableB[5][5] =   float[][](float[](0.039021,	0.03975	,    0.039996,	0.03975	,    0.039021),
                                             float[](0.03975,	0.040492,	0.040742,	0.040492,	0.03975),
                                             float[](0.039996,	0.040742,	0.040995,	0.040742,	0.039996),
                                             float[](0.03975,	0.040492,	0.040742,	0.040492,	0.03975),
                                             float[](0.039021,	0.03975	,    0.039996,	0.03975	,    0.039021));


const float sKernelTable[9][9] =  float[][](float[](0.00401,	0.005895,	0.00776,	0.009157,	0.009675,	0.009157,	0.007763,	0.005895,	 0.00401),
                                            float[](0.005895,	0.008667,	0.01141,	0.013461,	0.014223,	0.013461,	0.011412,	0.008667,	0.005895),
                                            float[](0.007763,	0.011412,	0.01502,	0.017726,	0.018729,	0.017726,	0.015028,	0.011412,	0.007763),
                                            float[](0.009157,	0.013461,	0.01772,	0.020909,	0.022092,	0.020909,	0.017726,	0.013461,	0.009157),
                                            float[](0.009675,	0.014223,	0.01872,	0.022092,	0.023342,	0.022092,	0.018729,	0.014223,	0.009675),
                                            float[](0.009157,	0.013461,	0.01772,	0.020909,	0.022092,	0.020909,	0.017726,	0.013461,	0.009157),
                                            float[](0.007763,	0.011412,	0.01502,	0.017726,	0.018729,	0.017726,	0.015028,	0.011412,	0.007763),
                                            float[](0.005895,	0.008667,	0.01141,	0.013461,	0.014223,	0.013461,	0.011412,	0.008667,	0.005895),
                                            float[](0.00401,	0.005895,	0.00776,	0.009157,	0.009675,	0.009157,	0.007763,	0.005895,	 0.00401));



const float sKernelTableD[9][9] =  float[][](float[](0.010989,	0.011474,	0.011833,	0.012054,	0.012129,	0.012054,	0.011833,	0.011474,	0.010989),
                                            float[](0.011474,	0.01198	,   0.012355,	0.012586,	0.012664,	0.012586,	0.012355,	0.01198	,    0.011474),
                                            float[](0.011833,	0.012355,	0.012742,	0.01298,    0.01306,    0.01298,    0.012742,	0.012355,	0.011833),
                                            float[](0.012054,	0.012586,	0.01298	,    0.013222,	0.013304,	0.013222,	0.01298	,    0.012586,	0.012054),
                                            float[](0.012129,	0.012664,	0.01306	,    0.013304,	0.013386,	0.013304,	0.01306	,    0.012664,	0.012129),
                                            float[](0.012054,	0.012586,	0.01298	,    0.013222,	0.013304,	0.013222,	0.01298	,    0.012586,	0.012054),
                                            float[](0.011833,	0.012355,	0.012742,	0.01298	,    0.01306,    0.01298,    0.012742,	0.012355,	0.011833),
                                            float[](0.011474,	0.01198	,   0.012355,	0.012586,	0.012664,	0.012586,	0.012355,	0.01198	,    0.011474),
                                            float[](0.010989,	0.011474,	0.011833,	0.012054,	0.012129,	0.012054,	0.011833,	0.011474,	0.010989));

vec4    SampleWarped(layout(rgba16f) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize);
vec4    SampleWarped(layout(r16f) image2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize);
vec4    SampleWarped(sampler2D aSrcImage, ivec2 aBaseCoord, ivec2 aTexSize);

vec4 Blur(ivec2 aBufferCoord)
{
    const ivec2 lBufferCoord = aBufferCoord;
    const int lKernelSize = 9;
    const int lHalfSize = lKernelSize / 2;
    const int lKernelStart = -lHalfSize;
    const int lKernelEnd = ((float(lKernelSize) * 0.5f) > float(lHalfSize)) ? lHalfSize + 1 : lHalfSize;

    vec4 lColorSum = vec4(0.f, 0.f, 0.f, 0.f);

    ivec2 lInputCoord = ivec2(0, 0);

    const ivec2 lAdjacentCoord = ivec2(1, 1); //max(ivec2(1, 1), ivec2(uOutputBufferSize.x / 512.f, uOutputBufferSize.y / 512.f));

    for (int itx = lKernelStart; itx < lKernelEnd; itx++) 
    { 
        for (int ity = lKernelStart; ity < lKernelEnd; ity++) 
        { 
            /*lInputCoord.x = (lBufferCoord.x + int(itx * uArea)) % int(gl_GlobalInvocationID.x);
            lInputCoord.y = (lBufferCoord.y + int(ity * uArea)) % int(gl_GlobalInvocationID.y);
            lInputCoord.x = (lInputCoord.x < 0) ? int(uOutputBufferSize.x) - lInputCoord.x :  lInputCoord.x;
            lInputCoord.y = (lInputCoord.x < 0) ? int(uOutputBufferSize.y) - lInputCoord.y :  lInputCoord.y;*/
            vec2 lArea = uArea * max(vec2(1, 1), vec2(uOutputBufferSize.xy) / 256.f);
            lInputCoord.x = lBufferCoord.x + int(itx * lAdjacentCoord.x * lArea.x);
            lInputCoord.y = lBufferCoord.y + int(ity * lAdjacentCoord.y * lArea.y);
            lInputCoord.x = (lInputCoord.x < 0) ? int(uOutputBufferSize.x) + lInputCoord.x :  lInputCoord.x;
            lInputCoord.y = (lInputCoord.y < 0) ? int(uOutputBufferSize.y) + lInputCoord.y :  lInputCoord.y;
            lInputCoord.x = lInputCoord.x % int(uOutputBufferSize.x);
            lInputCoord.y = lInputCoord.y % int(uOutputBufferSize.y);

            vec4 lInputColor = texelFetch(uInputBuffer0, lInputCoord, 0);
            lColorSum += lInputColor * sKernelTable[itx + lHalfSize][ity + lHalfSize];
        } 
    }

    lColorSum.a = 1.0;

    return lColorSum;
}

vec4 blur13(ivec2 uv, ivec2 resolution, vec2 direction) 
{
    vec4 color = vec4(0.0);
    ivec2 off1 = ivec2(vec2(1.411764705882353) * direction);
    ivec2 off2 = ivec2(vec2(3.2941176470588234) * direction);
    ivec2 off3 = ivec2(vec2(5.176470588235294) * direction);
    color += SampleWarped(uInputBuffer0, uv, resolution) * 0.1964825501511404;
    color += SampleWarped(uInputBuffer0, uv + off1, resolution) * 0.2969069646728344;
    color += SampleWarped(uInputBuffer0, uv - off1, resolution) * 0.2969069646728344;
    color += SampleWarped(uInputBuffer0, uv + off2, resolution) * 0.09447039785044732;
    color += SampleWarped(uInputBuffer0, uv - off2, resolution) * 0.09447039785044732;
    color += SampleWarped(uInputBuffer0, uv + off3, resolution) * 0.010381362401148057;
    color += SampleWarped(uInputBuffer0, uv - off3, resolution) * 0.010381362401148057;
    return color;
}


void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    //vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //vec4 lInputColor0 = texelFetch(uInputBuffer0, lBufferCoord, 0);
    //vec4 lOutputColor = blur13(lBufferCoord, uOutputBufferSize.xy, vec2(1.0 - uArea, uArea) * 1.1);
    vec4 lOutputColor = vec4(Blur(lBufferCoord).xyz, 1.0);
    //const vec4 lOutputColor = vec4(vec3(lColorSum.x, lColorSum.y, lColorSum.z), lInputColor0.a);
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
