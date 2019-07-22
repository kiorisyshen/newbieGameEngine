#include "SceneManager.hpp"
#include "AssetLoader.hpp"
#include "OGEX.hpp"

using namespace newbieGE;
using namespace std;

SceneManager::~SceneManager()
{
}

int SceneManager::Initialize()
{
    int result = 0;

    m_pScene = make_shared<Scene>();
    return result;
}

void SceneManager::Finalize()
{
}

void SceneManager::Tick()
{
}

int SceneManager::LoadScene(const char* scene_file_name)
{
    // now we only has ogex scene parser, call it directly
    if (LoadOgexScene(scene_file_name)) {
        m_pScene->LoadResource();
        m_bDirtyFlag                = true;
        m_bRenderingQueued          = false;
        m_bPhysicalSimulationQueued = false;
        return 0;
    } else {
        return -1;
    }
}

void SceneManager::ResetScene()
{
    m_bDirtyFlag = true;
}

bool SceneManager::LoadOgexScene(const char* ogex_scene_file_name)
{
    string ogex_text = g_pAssetLoader->SyncOpenAndReadTextFileToString(ogex_scene_file_name);

    if (ogex_text.empty()) {
        return false;
    }

    OgexParser ogex_parser;
    m_pScene = ogex_parser.Parse(ogex_text);

    if (!m_pScene) {
        return false;
    }

    return true;
}

const Scene& SceneManager::GetSceneForRendering()
{
    // TODO: we should perform CPU scene crop at here
    return *m_pScene;
}

const Scene& SceneManager::GetSceneForPhysicalSimulation()
{
    // TODO: we should perform CPU scene crop at here
    return *m_pScene;
}

bool SceneManager::IsSceneChanged()
{
    return m_bDirtyFlag;
}

void SceneManager::NotifySceneIsRenderingQueued()
{
    m_bRenderingQueued = true;

    if (m_bPhysicalSimulationQueued) {
        m_bDirtyFlag = false;
    }
}

void SceneManager::NotifySceneIsPhysicalSimulationQueued()
{
    m_bPhysicalSimulationQueued = true;

    if (m_bRenderingQueued) {
        m_bDirtyFlag = false;
    }
}

weak_ptr<BaseSceneNode> SceneManager::GetRootNode()
{
    return m_pScene->SceneGraph;
}

weak_ptr<SceneGeometryNode> SceneManager::GetSceneGeometryNode(string name)
{
    auto it = m_pScene->LUT_Name_GeometryNode.find(name);
    if (it != m_pScene->LUT_Name_GeometryNode.end())
        return it->second;
    else
        return weak_ptr<SceneGeometryNode>();
}

weak_ptr<SceneObjectGeometry> SceneManager::GetSceneGeometryObject(string key)
{
    return m_pScene->Geometries.find(key)->second;
}
