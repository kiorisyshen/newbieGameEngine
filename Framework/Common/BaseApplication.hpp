#pragma once
#include "IApplication.hpp"
#include "GraphicsManager.hpp"
#include "MemoryManager.hpp"
#include "AssetLoader.hpp"
#include "SceneManager.hpp"
#include "InputManager.hpp"
#include "IPhysicsManager.hpp"
#include "IGameLogic.hpp"
#include "DebugManager.hpp"

namespace newbieGE
{
class BaseApplication : implements IApplication
{
public:
    BaseApplication(GfxConfiguration &cfg);
    int Initialize();
    void Finalize();
    // One cycle of the main loop
    void Tick();

    void SetCommandLineParameters(int argc, char **argv);
    int GetCommandLineArgumentsCount() const;
    const char *GetCommandLineArgument(int index) const;

    bool IsQuit() const;

    inline const GfxConfiguration &GetConfiguration() const { return m_Config; };

    void OnDraw(){};

protected:
    // Flag if need quit the main loop of the application
    static bool m_bQuit;
    GfxConfiguration m_Config;
    int m_nArgC;
    char **m_ppArgV;

private:
    // hide the default construct to enforce a configuration
    BaseApplication(){};
};
} // namespace newbieGE
