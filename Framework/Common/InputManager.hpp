#pragma once
#include "IRuntimeModule.hpp"

namespace newbieGE {
    class InputManager : implements IRuntimeModule
    {
        public:
            virtual int Initialize();
            virtual void Finalize();
            virtual void Tick();

            void UpArrowKeyDown();
            void UpArrowKeyUp();
            void DownArrowKeyDown();
            void DownArrowKeyUp();
            void LeftArrowKeyDown();
            void LeftArrowKeyUp();
            void RightArrowKeyDown();
            void RightArrowKeyUp();

            void ResetKeyDown();
            void ResetKeyUp();
    };

    extern InputManager* g_pInputManager;
}

