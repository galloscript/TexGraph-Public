/*
 * @file    Perlin1.comp.glsl
 * @author  David Gallardo Moreno
 * @brief   Perlin noise from libnoise http://libnoise.sourceforge.net/
 */

#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba8) uniform image2D uOutputBuffer0;
layout(binding = 1, rgba8) uniform image2D uInputBuffer0;

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

layout(location = 0) uniform float uFrequency;
layout(location = 1) uniform float uPersistence;
layout(location = 2) uniform float uLacunarity;
layout(location = 3) uniform int   uOctaveCount;
layout(location = 4) uniform float uPanZ;

#define SHIFT_NOISE_GEN 8
const int X_NOISE_GEN = 1619;
const int Y_NOISE_GEN = 31337;
const int Z_NOISE_GEN = 6971;
const int SEED_NOISE_GEN = 1013;

#define LinearInterp mix

/*
double LinearInterp (double n0, double n1, double a)
{
    return ((1.0 - a) * n0) + (a * n1);
}*/

double SCurve5 (double a)
{
    double a3 = a * a * a;
    double a4 = a3 * a;
    double a5 = a4 * a;
    return (6.0 * a5) - (15.0 * a4) + (10.0 * a3);
}

double MakeInt32Range (double n)
{
    if (n >= 1073741824.0) 
    {
        return (2.0 * mod (n, 1073741824.0)) - 1073741824.0;
    } 
    else if (n <= -1073741824.0) 
    {
        return (2.0 * mod (n, 1073741824.0)) + 1073741824.0;
    } 
    else 
    {
        return n;
    }
}

int IntValueNoise3D (int x, int y, int z, int seed)
{
  // All constants are primes and must remain prime in order for this noise
  // function to work correctly.
  int n = (
      X_NOISE_GEN    * x
    + Y_NOISE_GEN    * y
    + Z_NOISE_GEN    * z
    + SEED_NOISE_GEN * seed)
    & 0x7fffffff;
  n = (n >> 13) ^ n;
  return (n * (n * n * 60493 + 19990303) + 1376312589) & 0x7fffffff;
}


double ValueNoise3D (int x, int y, int z, int seed)
{
    return 1.0 - double(IntValueNoise3D (x, y, z, seed) / 1073741824.0);
}

double GradientNoise3D (double fx, double fy, double fz, int ix, int iy, int iz, int seed)
{
    // Randomly generate a gradient vector given the integer coordinates of the
    // input value.  This implementation generates a random number and uses it
    // as an index into a normalized-vector lookup table.
    int vectorIndex = (
      X_NOISE_GEN    * ix
    + Y_NOISE_GEN    * iy
    + Z_NOISE_GEN    * iz
    + SEED_NOISE_GEN * seed)
    & 0xffffffff;
    vectorIndex ^= (vectorIndex >> SHIFT_NOISE_GEN);
    vectorIndex &= 0xff;

    /*double xvGradient = g_randomVectors[(vectorIndex << 2)    ];
    double yvGradient = g_randomVectors[(vectorIndex << 2) + 1];
    double zvGradient = g_randomVectors[(vectorIndex << 2) + 2];*/

    double xvGradient = ValueNoise3D(ix, iy, iz, 0);
    double yvGradient = ValueNoise3D(ix, iy, iz, 1);
    double zvGradient = ValueNoise3D(ix, iy, iz, 2);

    // Set up us another vector equal to the distance between the two vectors
    // passed to this function.
    double xvPoint = (fx - double(ix));
    double yvPoint = (fy - double(iy));
    double zvPoint = (fz - double(iz));

    // Now compute the dot product of the gradient vector with the distance
    // vector.  The resulting value is gradient noise.  Apply a scaling value
    // so that this noise value ranges from -1.0 to 1.0.
    return ((xvGradient * xvPoint)
            + (yvGradient * yvPoint)
            + (zvGradient * zvPoint)) * 2.12;
}

double GradientCoherentNoise3D (double x, double y, double z, int seed)
{
    // Create a unit-length cube aligned along an integer boundary.  This cube
    // surrounds the input point.
    int x0 = (x > 0.0? int(x): int(x) - 1);
    int x1 = x0 + 1;
    int y0 = (y > 0.0? int(y): int(y) - 1);
    int y1 = y0 + 1;
    int z0 = (z > 0.0? int(z): int(z) - 1);
    int z1 = z0 + 1;

    // Map the difference between the coordinates of the input value and the
    // coordinates of the cube's outer-lower-left vertex onto an S-curve.
    double xs = 0, ys = 0, zs = 0;
    xs = SCurve5 (x - double(x0));
    ys = SCurve5 (y - double(y0));
    zs = SCurve5 (z - double(z0));

    // Now calculate the noise values at each vertex of the cube.  To generate
    // the coherent-noise value at the input point, interpolate these eight
    // noise values using the S-curve value as the interpolant (trilinear
    // interpolation.)
    double n0, n1, ix0, ix1, iy0, iy1;
    n0   = GradientNoise3D (x, y, z, x0, y0, z0, seed);
    n1   = GradientNoise3D (x, y, z, x1, y0, z0, seed);
    ix0  = LinearInterp (n0, n1, xs);
    n0   = GradientNoise3D (x, y, z, x0, y1, z0, seed);
    n1   = GradientNoise3D (x, y, z, x1, y1, z0, seed);
    ix1  = LinearInterp (n0, n1, xs);
    iy0  = LinearInterp (ix0, ix1, ys);
    n0   = GradientNoise3D (x, y, z, x0, y0, z1, seed);
    n1   = GradientNoise3D (x, y, z, x1, y0, z1, seed);
    ix0  = LinearInterp (n0, n1, xs);
    n0   = GradientNoise3D (x, y, z, x0, y1, z1, seed);
    n1   = GradientNoise3D (x, y, z, x1, y1, z1, seed);
    ix1  = LinearInterp (n0, n1, xs);
    iy1  = LinearInterp (ix0, ix1, ys);

    return LinearInterp (iy0, iy1, zs);
}

double Perlin(double x, double y, double z)
{
    double m_persistence = uPersistence;
    double m_frequency = uFrequency; 
    int m_seed = 2;
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

    //vec4 lColor = vec4(vec3(Perlin(lUV.x + uPanX, uPanZ, lUV.y + uPanY)), 1.0);
    vec4 lColor = vec4(vec3(SeamlessNoise(lUV.x, lUV.y, uOutputBufferSize.x)), 1.0);
    //lColor = vec4(1.0, 0.0, 0.0, 1.0);
    imageStore (uOutputBuffer0, lBufferCoord, lColor); 
}

