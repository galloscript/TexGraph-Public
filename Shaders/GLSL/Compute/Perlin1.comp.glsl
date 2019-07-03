/*
 * @file    Perlin1.comp.glsl
 * @author  David Gallardo Moreno
 * @brief   Perlin noise from libnoise http://libnoise.sourceforge.net/
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, r16f) uniform image2D uOutputBuffer0;
layout(location = 80) uniform sampler2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0) uniform float uFrequency;
layout(location = 1) uniform float uPersistence;
layout(location = 2) uniform float uLacunarity;
layout(location = 3) uniform int   uOctaveCount;
layout(location = 4) uniform float uPanZ;
layout(location = 5) uniform int   uSeed; 

#define LinearInterp mix

//----------------------
double  SCurve5                 (double a);
double  MakeInt32Range          (double n);
int     IntValueNoise3D         (int x, int y, int z, int seed);
double  ValueNoise3D            (int x, int y, int z, int seed);
double  GradientNoise3D         (double fx, double fy, double fz, int ix, int iy, int iz, int seed);
double  GradientCoherentNoise3D (double x, double y, double z, int seed);
//--------------------

double Perlin(double x, double y, double z)
{
    double m_persistence = uPersistence;
    double m_frequency = uFrequency; 
    int m_seed = uSeed;
    double m_lacunarity = uLacunarity;
    int m_octaveCount = uOctaveCount;  

    double value = 0.0;
    double signal = 0.0;
    double curPersistence = 1.0;
    double nx, ny, nz;
    int seed;

    x *= m_frequency;
    y *= m_frequency;
    z *= m_frequency;

    for (int curOctave = 0; curOctave < m_octaveCount; curOctave++) 
    {

        // Make sure that these floating-point values have the same range as a 32-
        // bit integer so that we can pass them to the coherent-noise functions.
        nx = MakeInt32Range (x);
        ny = MakeInt32Range (y);
        nz = MakeInt32Range (z);

        // Get the coherent-noise value from the input value and add it to the
        // final result.
        seed = (m_seed + curOctave) & 0xffffffff;
        signal = GradientCoherentNoise3D (nx, ny, nz, seed);
        value += signal * curPersistence;

        // Prepare the next octave.
        x *= m_lacunarity;
        y *= m_lacunarity;
        z *= m_lacunarity;
        curPersistence *= m_persistence;
    }

    return value;
}

double SeamlessNoise(double xCur, double zCur, double aLength)
{
#define NoiseFunc Perlin
    double m_lowerXBound = 0;
    double m_lowerZBound = 0;
    double xExtent = 1;
    double zExtent = 1;
    //xCur *= aLength;
    //zCur *= aLength;
    double swValue, seValue, nwValue, neValue;
    swValue = NoiseFunc (xCur          , uPanZ, zCur          );
    seValue = NoiseFunc (xCur + xExtent, uPanZ, zCur          );
    nwValue = NoiseFunc (xCur          , uPanZ, zCur + zExtent);
    neValue = NoiseFunc (xCur + xExtent, uPanZ, zCur + zExtent);
    double xBlend = 1.0 - ((xCur - m_lowerXBound) / 1);
    double zBlend = 1.0 - ((zCur - m_lowerZBound) / 1);
    double z0 = LinearInterp (swValue, seValue, xBlend);
    double z1 = LinearInterp (nwValue, neValue, xBlend);
    return LinearInterp (z0, z1, zBlend); 
}

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));

    //vec4 lColor = vec4(vec3(Perlin(lUV.x, uPanZ, lUV.y)), 1.0);
    vec4 lColor = vec4(vec3(SeamlessNoise(lUV.x, lUV.y, uOutputBufferSize.x)), 1.0);
    //lColor = vec4(1.0, 0.0, 0.0, 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, clamp(lColor, 0.0f, 1.0f)); 
}

