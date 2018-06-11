#include "BaseApplication.hpp"

// For different platform. This is Empty platform
namespace newbieGE {
    BaseApplication g_App;
    IApplication* g_pApp = &g_App;
}