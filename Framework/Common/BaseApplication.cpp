#include "BaseApplication.hpp"

// Parse command line, read configuration, initialize all sub modules
int newbieGE::BaseApplication::Initialize()
{
    m_bQuit = false;
    return 0;
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