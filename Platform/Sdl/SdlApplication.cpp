#include "SdlApplication.hpp"
#include <iostream>
#include <utility>
#include "GraphicsManager.hpp"
#include "InputManager.hpp"

/*
 * Recurse through the list of arguments to clean up, cleaning up
 * the first one in the list each iteration.
 */
template <typename T, typename... Args>
void cleanup(T *t, Args &&... args) {
    //Cleanup the first item in the list
    cleanup(t);
    //Recurse to clean up the remaining arguments
    cleanup(std::forward<Args>(args)...);
}
/*
 * These specializations serve to free the passed argument and also provide the
 * base cases for the recursive call above, eg. when args is only a single item
 * one of the specializations below will be called by
 * cleanup(std::forward<Args>(args)...), ending the recursion
 * We also make it safe to pass nullptrs to handle situations where we
 * don't want to bother finding out which values failed to load (and thus are null)
 * but rather just want to clean everything up and let cleanup sort it out
 */
template <>
inline void cleanup<SDL_Window>(SDL_Window *win) {
    if (!win) {
        return;
    }
    SDL_DestroyWindow(win);
}
template <>
inline void cleanup<SDL_Renderer>(SDL_Renderer *ren) {
    if (!ren) {
        return;
    }
    SDL_DestroyRenderer(ren);
}
template <>
inline void cleanup<SDL_Texture>(SDL_Texture *tex) {
    if (!tex) {
        return;
    }
    SDL_DestroyTexture(tex);
}
template <>
inline void cleanup<SDL_Surface>(SDL_Surface *surf) {
    if (!surf) {
        return;
    }
    SDL_FreeSurface(surf);
}

using namespace std;
using namespace newbieGE;

/**
* Log an SDL error with some error message to the output stream of our choice
* @param os The output stream to write the message to
* @param msg The error message to write, format will be msg error: SDL_GetError()
*/
void SdlApplication::logSDLError(std::ostream &os, const std::string &msg) {
    os << msg << " error: " << SDL_GetError() << std::endl;
}

void SdlApplication::onResize(int width, int height) {
    if (height == 0) {
        height = 1;
    }

    g_pGraphicsManager->ResizeCanvas(width, height);
}

int SdlApplication::Initialize() {
    BaseApplication::Initialize();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        logSDLError(std::cout, "SDL_Init");
        return 1;
    }

    return 0;
}

void SdlApplication::Finalize() {
    cleanup(m_pWindow);
    SDL_Quit();
}

void SdlApplication::Tick() {
    SDL_Event e;

    while (SDL_PollEvent(&e)) {
        switch (e.type) {
            case SDL_QUIT:
                RequestQuit();
                break;
            case SDL_KEYDOWN:
                break;
            case SDL_KEYUP: {
                g_pInputManager->AsciiKeyDown(static_cast<char>(e.key.keysym.sym));
            } break;
            case SDL_MOUSEBUTTONDOWN: {
                if (e.button.button == SDL_BUTTON_LEFT) {
                    g_pInputManager->LeftMouseButtonDown();
                    m_bInDrag = true;
                }
            } break;
            case SDL_MOUSEBUTTONUP: {
                if (e.button.button == SDL_BUTTON_LEFT) {
                    g_pInputManager->LeftMouseButtonUp();
                    m_bInDrag = false;
                }
            } break;
            case SDL_MOUSEMOTION: {
                if (m_bInDrag) {
                    g_pInputManager->LeftMouseDrag(e.motion.xrel, e.motion.yrel);
                }
            } break;
            case SDL_WINDOWEVENT:
                if (e.window.event == SDL_WINDOWEVENT_RESIZED) {
                    int tmpX, tmpY;
                    SDL_GetWindowSize(m_pWindow, &tmpX, &tmpY);
                    onResize(tmpX, tmpY);
                }
        }
    }

    SDL_GL_SwapWindow(m_pWindow);
}

void SdlApplication::CreateMainWindow() {
#if defined(OS_WEBASSEMBLY)
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
#else
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
#endif
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, m_Config.redBits);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, m_Config.blueBits);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, m_Config.greenBits);
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, m_Config.alphaBits);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, m_Config.depthBits);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, m_Config.stencilBits);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, m_Config.msaaSamples);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    m_pWindow = SDL_CreateWindow(m_Config.appName, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, m_Config.screenWidth, m_Config.screenHeight, SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);
    if (m_pWindow == nullptr) {
        logSDLError(std::cout, "SDL_CreateWindow");
        SDL_Quit();
    }

    m_hContext = SDL_GL_CreateContext(m_pWindow);
    if (!m_hContext) {
        logSDLError(std::cout, "SDL_GL_CreateContext");
        SDL_Quit();
    }

    int major_ver, minor_ver;
    SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, &major_ver);
    SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, &minor_ver);
    printf("Initialized GL context: %d.%d\n", major_ver, minor_ver);

    SDL_GL_SetSwapInterval(1);
}
