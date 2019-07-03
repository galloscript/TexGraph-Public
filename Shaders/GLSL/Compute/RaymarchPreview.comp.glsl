/*
 * @file    Blend.comp.glsl
 * @author  David Gallardo Moreno
 */


#version 430
precision highp float;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(binding = 0, rgba16f) uniform image2D uOutputBuffer0;
/*
layout(binding = 1, rgba16f) uniform image2D uInputBuffer0;
layout(binding = 2, rgba16f) uniform image2D uInputBuffer1;
layout(binding = 3, rgba16f) uniform image2D uMaskBuffer;
*/

layout(location = 100) uniform ivec3 uOutputBufferSize;
layout(location = 101) uniform ivec3 uInvocationOffset;

#define PI 3.142
#define MARCHING_STEPS   256
#define CAM_DEPTH 1.
#define ROTATE_CAM  false

const vec3 X_AXIS = vec3(1,0,0);
const vec3 Y_AXIS = vec3(0,1,0);
const vec3 Z_AXIS = vec3(0,0,1);

vec3 gMouseLight = vec3(0.0, 0.0, 3.);

struct Ray {
	vec3 origin;
	vec3 dir;
};

// A camera. Has a position and a direction. 
struct Camera {
    vec3 pos;
    Ray ray;
};

struct HitTest {
	bool hit;
    //bool emissive;
	float dist;
    vec3 normal;
    vec4 col;
    float ref;
    bool metallic;
    vec3 endPoint;
};

struct Material
{
    vec4 col;
    float ref;
    bool metallic;
    int texColor;
    int texRef;
    int channelRef;
};

#define MAX_MATERIALS 7
const Material gMaterials[MAX_MATERIALS] = Material[](
    Material(vec4(0.94901, 0.90588, 0.780392, 1.0), 0.0, false, -1, -1, 0),	//0 = background 
    Material(vec4(0.1, 1.0, 1.02, 0.0), 1.0, false, -1, -1, 0),  			//1 = blue pipes
    Material(vec4(1.10, 1.0, 1.0, 0.0), 1.0, false, -1, -1, 0),  			//2 = white boxes
    Material(vec4(0.83, 0.04, 0.03, 0.0), 1.5, false, -1, -1, 0),   		//3 = red pipes
    Material(vec4(0.23, 0.4, 0.3, 0.0), 0.8, false, -1, -1, 0),   			//4 = green box
    Material(vec4(0.42, 0.4, 0.4, 0.0), 1.0, false, -1, -1, 0),  			//5 = grey boxes
    Material(vec4(0.5, 0.5, 0.5, 0.0), 0.9, true, -1, -1, 0) 				//6 = unused
);
 
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}


mat3 rotation(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return inverse(mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
                                              oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  
                                              oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c));
}

float map(vec3 p, out int material)
{
    float d2, d, b = 0.0;    
    mat3 rot = mat3(1);
    float c, c2;
    d2 = d = b = 200000.;
	    
    //CORRIDOR
    d = min(d, sdSphere(p  + vec3(0.0,0.0,-0.5), 0.35));
    material = 0;

    return d;
}

vec3 calcNormal(in vec3 pos) 
{
    int mat;
    vec2 e = vec2(1.0, -1.0) * 0.001;
    return normalize(
        e.xyy * map(pos + e.xyy, mat) +
        e.yyx * map(pos + e.yyx, mat) +
        e.yxy * map(pos + e.yxy, mat) +
        e.xxx * map(pos + e.xxx, mat));
}

float calcAO( in vec3 pos, in vec3 nor )
{
    int mat;
    float occ = 0.0;
    float sca = 1.0, dd;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.09*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        dd = map( aopos, mat );
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    float res = clamp( 1.0 - 1.6*occ, 0.0, 1.0 );
    return res;    
}

vec4 GetMaterialColor(int tex, vec2 coord)
{
    /*if(tex == -1) return vec4(1., 1., 1., 1.);
    switch(tex)
    {
        case 0: return texture(iChannel0, coord);
        case 1: return texture(iChannel1, coord);
        case 2: return texture(iChannel2, coord);
        case 3: return texture(iChannel3, coord);
    };*/
    
    return vec4(1., 1., 1., 1.);
}

vec4 trace(vec3 ro, vec3 rd)//, out vec3 normal, out float ao, out float depth)
{
    int matId = 0;
    float h, t = 0.;
    for(int i = 0; i < MARCHING_STEPS; ++i)
    {
        h = map(ro + rd * t, matId);
        t += h;
        if(h < 0.001) break;
    }
	
    vec3 endPoint = ro + rd * t;
    Material mat = gMaterials[matId];
    vec4 color = mat.col * GetMaterialColor(mat.texColor, endPoint.xz);
    
    if(mat.col.a > 1.)
    {
       return vec4(mat.col.rgb * mat.col.a * 0.15, 1.0);
    }
    if (h < 0.001) 
    {
        vec3 p = ro + rd * t;
        vec3 normal = calcNormal(p);
             
        vec4 lsum = vec4(0.0f);

        vec3 light = gMouseLight;
        float dif = clamp(dot(normal, normalize(light - p)), 0., 1.);
        float spe = pow(clamp(dot(normal,normalize(ro+(light-p))), 0., 1.), 30.);
		lsum.xyz+=dif*color.rgb;
        lsum.xyz+=vec3(mat.col.rgb)*spe*mat.ref;
        lsum.w = 1.;
            
        vec4 normalMapSizzled = vec4((normal + 1.0) * 0.5, 1.);
        normalMapSizzled.r = 1.0 - normalMapSizzled.r;

        return vec4(1.) * calcAO(p, normal) * lsum;
    } 
    else 
    {
        return vec4(vec3(0.8), 1);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 iResolution = vec2(uOutputBufferSize.xy);
    vec2 q = (fragCoord.xy - .5 * iResolution.xy ) / iResolution.y;
    vec3 ro = vec3(0, 0, 2.0);
    vec3 rd = normalize(vec3(q, 0.3) - ro);
	
    //gMouseLight.x = (-iMouse.x / iResolution.x * gMouseLight.z * 2.) + gMouseLight.z;
    //gMouseLight.y = (-iMouse.y / iResolution.y * gMouseLight.z * 2.) + gMouseLight.z;
    
    vec4 thing = trace(ro, rd);
    fragColor = thing;

}

void main(void)
{
    ivec2 lBufferCoord = ivec2(gl_GlobalInvocationID.xy + uInvocationOffset.xy);
    vec2 lUV = (vec2(lBufferCoord.xy) / vec2(uOutputBufferSize.xy));
    //vec4 lInputColor0 = texelFetch(uInputBuffer0,    ivec2(lUV * vec2(imageSize(uInputBuffer0))), 0);
    //vec4 lInputColor1 = texelFetch(uInputBuffer1,    ivec2(lUV * vec2(imageSize(uInputBuffer1))), 0);
    //vec4 lInputColor2 = texelFetch(uMaskBuffer,      ivec2(lUV * vec2(imageSize(uInputBuffer2))), 0);

    vec4 lOutputColor;
    mainImage(lOutputColor, vec2(lBufferCoord));
    lOutputColor.a = 1.0f;
    //lOutputColor = clamp(lOutputColor, 0., 1.);
    //lOutputColor.rgb *= 0.2;
    //const vec4 lOutputColor = (lInputColor0 * lInputColor2) + (lInputColor1 * (1.0f - lInputColor2));
    imageStore (uOutputBuffer0, lBufferCoord, lOutputColor);
}
