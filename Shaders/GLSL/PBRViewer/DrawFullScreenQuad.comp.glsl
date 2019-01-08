/*
 * @file    DrawFullScreenQuad.vert.glsl
 * @author  David Gallardo Moreno
 */

#version 430
precision highp float;

const vec4 sVertices[6] = vec4[6](vec4(1.0, -1.0, 0.5, 1.0),
                                  vec4(-1.0, -1.0, 0.5, 1.0),
                                  vec4(1.0, 1.0, 0.5, 1.0),
                                  vec4(1.0, 1.0, 0.5, 1.0),
                                  vec4(-1.0, 1.0, 0.5, 1.0),
                                  vec4(-1.0, -1.0, 0.5, 1.0));


out vec2 ex_TexCoord;

void main(void)
{
    ex_TexCoord.xy = (sVertices[gl_VertexID].xy + 1.0) * 0.5;
    gl_Position = sVertices[gl_VertexID];
    
}