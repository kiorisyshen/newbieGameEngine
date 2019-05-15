#pragma once
#include "geommath.hpp"
#include "IRuntimeModule.hpp"
#include "SceneParser.hpp"

namespace newbieGE {
    class SceneManager : implements IRuntimeModule
    {
    public:
        virtual ~SceneManager();

        virtual int Initialize();
        virtual void Finalize();

        virtual void Tick();

        void LoadScene(const char* scene_file_name);

        const Scene& GetSceneForRendering();

    protected:
        void LoadOgexScene(const char* ogex_scene_file_name);

    protected:
        std::unique_ptr<Scene>  m_pScene;
    };

    extern SceneManager*    g_pSceneManager;
}

