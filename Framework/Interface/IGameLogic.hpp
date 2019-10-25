#pragma once
#include "IRuntimeModule.hpp"

namespace newbieGE {
class IGameLogic : implements IRuntimeModule {
   public:
    virtual int Initialize() = 0;
    virtual void Finalize()  = 0;
    virtual void Tick()      = 0;

    virtual void OnUpKeyDown(){};
    virtual void OnUpKeyUp(){};
    virtual void OnUpKey(){};

    virtual void OnDownKeyDown(){};
    virtual void OnDownKeyUp(){};
    virtual void OnDownKey(){};

    virtual void OnLeftKeyDown(){};
    virtual void OnLeftKeyUp(){};
    virtual void OnLeftKey(){};

    virtual void OnRightKeyDown(){};
    virtual void OnRightKeyUp(){};
    virtual void OnRightKey(){};

    virtual void OnButton1Down(char keycode){};
    virtual void OnButton1Up(char keycode){};

    virtual void OnAnalogStick(int id, float deltaX, float deltaY){};
};

extern IGameLogic *g_pGameLogic;
}  // namespace newbieGE