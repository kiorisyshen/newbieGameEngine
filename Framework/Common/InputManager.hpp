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

        protected:
            bool m_bUpKeyPressed    = false;
            bool m_bDownKeyPressed  = false;
            bool m_bLeftKeyPressed  = false;
            bool m_bRightKeyPressed = false;
    };

    extern InputManager* g_pInputManager;
}
