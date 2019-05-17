#include <iostream>
#include <fstream>
#include "MetalGraphicsManager.h"
#include "AssetLoader.hpp"
#include "IApplication.hpp"
#include "SceneManager.hpp"

using namespace newbieGE;
using namespace std;


int MetalGraphicsManager::Initialize()
{
    // Initialize the world/model matrix to the identity matrix.
    BuildIdentityMatrix(m_worldMatrix);

    // Set the field of view and screen aspect ratio.
    float fieldOfView = PI / 4.0f;
    const GfxConfiguration& conf = g_pApp->GetConfiguration();

    float screenAspect = (float)conf.screenWidth / (float)conf.screenHeight;

    // Build the perspective projection matrix.
    BuildPerspectiveFovLHMatrix(m_projectionMatrix, fieldOfView, screenAspect, screenNear, screenDepth);
    
    return 0;
}

void MetalGraphicsManager::Finalize()
{
    
}

void MetalGraphicsManager::Tick()
{
    [m_pRenderer tick];
}

void MetalGraphicsManager::Clear()
{
    
}

void MetalGraphicsManager::Draw()
{
    
}

bool MetalGraphicsManager::SetShaderParameters(float* worldMatrix, float* viewMatrix, float* projectionMatrix)
{
   
}

void MetalGraphicsManager::InitializeBuffers()
{
    
}

void MetalGraphicsManager::RenderBuffers()
{
    
}

void MetalGraphicsManager::CalculateCameraPosition()
{
    
}

bool MetalGraphicsManager::InitializeShader(const char* vsFilename, const char* fsFilename)
{
    return true;
}
