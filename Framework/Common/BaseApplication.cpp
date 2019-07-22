#include "BaseApplication.hpp"
#include <iostream>

using namespace newbieGE;
using namespace std;

bool BaseApplication::m_bQuit = false;

BaseApplication::BaseApplication(GfxConfiguration& cfg) : m_Config(cfg) {}

// Parse command line, read configuration, initialize all sub modules
int BaseApplication::Initialize()
{
    int ret = 0;

    cout << m_Config;

    cerr << "Initialize Memory Manager: ";
    if ((ret = g_pMemoryManager->Initialize()) != 0) {
        cerr << "Failed. err = " << ret;
        return ret;
    }
    cerr << "Success" << endl;

    cerr << "Initialize Asset Loader: ";
    if ((ret = g_pAssetLoader->Initialize()) != 0) {
        cerr << "Failed. err = " << ret;
        return ret;
    }
    cerr << "Success" << endl;

    cerr << "Initialize Scene Manager: ";
    if ((ret = g_pSceneManager->Initialize()) != 0) {
        cerr << "Failed. err = " << ret;
        return ret;
    }
    cerr << "Success" << endl;

    cerr << "Initialize Graphics Manager: ";
    if ((ret = g_pGraphicsManager->Initialize()) != 0) {
        cerr << "Failed. err = " << ret;
        return ret;
    }
    cerr << "Success" << endl;

    cerr << "Initialize Input Manager: ";
    if ((ret = g_pInputManager->Initialize()) != 0) {
        cerr << "Failed. err = " << ret;
        return ret;
    }
    cerr << "Success" << endl;

    cerr << "Initialize Physics Manager: ";
    if ((ret = g_pPhysicsManager->Initialize()) != 0) {
        cerr << "Failed. err = " << ret;
        return ret;
    }
    cerr << "Success" << endl;

    cerr << "Initialize Game Logic: ";
    if ((ret = g_pGameLogic->Initialize()) != 0) {
        cerr << "Failed. err =" << ret;
        return ret;
    }
    cerr << "Success" << endl;

#ifdef DEBUG
    if ((ret = g_pDebugManager->Initialize()) != 0) {
        cerr << "Failed. err =" << ret;
        return ret;
    }
#endif

    return ret;
}

// Finalize all sub modules and clean up all runtime temporary files.
void BaseApplication::Finalize()
{
    g_pGameLogic->Finalize();
    g_pInputManager->Finalize();
    g_pGraphicsManager->Finalize();
    g_pPhysicsManager->Finalize();
    g_pSceneManager->Finalize();
    g_pAssetLoader->Finalize();
    g_pMemoryManager->Finalize();
}

// One cycle of the main loop
void BaseApplication::Tick()
{
    g_pMemoryManager->Tick();
    g_pAssetLoader->Tick();
    g_pSceneManager->Tick();
    g_pInputManager->Tick();
    g_pPhysicsManager->Tick();
    g_pGraphicsManager->Tick();
#ifdef DEBUG
    g_pDebugManager->Tick();
#endif
    g_pGameLogic->Tick();
}

void BaseApplication::SetCommandLineParameters(int argc, char** argv)
{
    m_nArgC = argc;
    m_ppArgV = argv;
}

int BaseApplication::GetCommandLineArgumentsCount() const { return m_nArgC; }

const char* BaseApplication::GetCommandLineArgument(int index) const
{
    assert(index < m_nArgC);
    return m_ppArgV[index];
}

bool BaseApplication::IsQuit() const { return m_bQuit; }
