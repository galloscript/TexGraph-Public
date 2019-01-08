/*
 * @file    DrawMesh.vert.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

#define M_PI 3.1415926535897932384626433832795

layout(location = 0) in vec3 in_Position;
layout(location = 1) in vec2 in_TexCoord;
layout(location = 2) in vec3 in_Normal;
layout(location = 3) in vec3 in_Tangent;
layout(location = 4) in vec3 in_Binormal;

layout(location = 0) uniform mat4 uModelMatrix;
layout(location = 4) uniform mat4 uViewMatrix;
layout(location = 8) uniform mat4 uProjectionMatrix;

out vec2 ex_TexCoord;
out vec3 ex_Normal;
out vec3 ex_Tangent;
out vec3 ex_Binormal;
out vec4 ex_EyeSpacePosition;
out mat4 ex_ModelViewMatrix;


void main(void)
{
    ex_TexCoord = in_TexCoord;
    ex_ModelViewMatrix = uViewMatrix * uModelMatrix;
    ex_EyeSpacePosition = ex_ModelViewMatrix * vec4(in_Position.xyz, 1.0);
    mat3 lModelViewMat3 = mat3(ex_ModelViewMatrix);
    ex_Normal = normalize(lModelViewMat3 * in_Normal.xyz).xyz;
    ex_Tangent = normalize(lModelViewMat3 * in_Tangent.xyz).xyz;
    ex_Binormal = normalize(lModelViewMat3 * in_Binormal.xyz).xyz;
    gl_Position = uProjectionMatrix * ex_ModelViewMatrix * vec4(in_Position.xyz, 1.0);
}


