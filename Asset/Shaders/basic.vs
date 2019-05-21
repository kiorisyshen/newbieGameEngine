////////////////////////////////////////////////////////////////////////////////
// Filename: basic.vs
////////////////////////////////////////////////////////////////////////////////

#version 150

/////////////////////
// INPUT VARIABLES //
/////////////////////
in vec3 inputPosition;
in vec3 inputNormal;

//////////////////////
// OUTPUT VARIABLES //
//////////////////////
out vec4 normal;
out vec4 v;

///////////////////////
// UNIFORM VARIABLES //
///////////////////////
// update per draw call
uniform mat4 objectLocalMatrix;

// update per frame
uniform mat4 worldMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

////////////////////////////////////////////////////////////////////////////////
// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
void main(void)
{
    mat4 transformMatrix = worldMatrix * objectLocalMatrix;
	// Calculate the position of the vertex against the world, view, and projection matrices.
	v = transformMatrix * vec4(inputPosition, 1.0f);
	v = viewMatrix * v;
	gl_Position = projectionMatrix * v;

    normal = transformMatrix * vec4(inputNormal, 0.0f);
    normal = viewMatrix * normal;
}

