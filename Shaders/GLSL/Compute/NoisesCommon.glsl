/*
 * @file    NoisesCommon.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

// The name of the block is used for finding the index location only
layout (std140, binding = 20) uniform SBRandomVectorsBlock 
{
    double gRandomVectors [1024]; // This is the important name (in the shader).
};

#define SHIFT_NOISE_GEN 8
const int X_NOISE_GEN = 1619;
const int Y_NOISE_GEN = 31337;
const int Z_NOISE_GEN = 6971;
const int SEED_NOISE_GEN = 1050;

#define LinearInterp mix


//------------------------------------------------------------------------
vec2 Hash2(vec2 p, int aSeed)
{
    float r = (aSeed+523.0)*sin(dot(p, vec2(53.3158, 43.6143)));
    return vec2(fract(15.32354 * r), fract(17.25865 * r));
}

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

    double xvGradient = gRandomVectors[(vectorIndex << 2)    ];
    double yvGradient = gRandomVectors[(vectorIndex << 2) + 1];
    double zvGradient = gRandomVectors[(vectorIndex << 2) + 2];

    /*vec4 lRandomVector = gRandomVectors[(vectorIndex << 2)];
    double xvGradient = lRandomVector.x;
    double yvGradient = lRandomVector.y;
    double zvGradient = lRandomVector.z;*/

    //double xvGradient = ValueNoise3D(ix, iy, iz, 0);
    //double yvGradient = ValueNoise3D(ix, iy, iz, 1);
    //double zvGradient = ValueNoise3D(ix, iy, iz, 2);

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
