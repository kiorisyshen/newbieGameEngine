#include "BaseApplication.hpp"
#include <iostream>

using namespace newbieGE;

bool newbieGE::BaseApplication::m_bQuit = false;

newbieGE::BaseApplication::BaseApplication(GfxConfiguration& cfg)
    :m_Config(cfg)
{
}

// Parse command line, read configuration, initialize all sub modules
int newbieGE::BaseApplication::Initialize()
{
    int result = 0;

    std::cout << m_Config;

	return result;
}


// Finalize all sub modules and clean up all runtime temporary files.
void newbieGE::BaseApplication::Finalize()
{
}


// One cycle of the main loop
void newbieGE::BaseApplication::Tick()
{
}

bool newbieGE::BaseApplication::IsQuit()
{
    return m_bQuit;
}