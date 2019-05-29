#include <cstdio>
#include <chrono>
#include <thread>
#include "BaseApplication.hpp"

using namespace newbieGE;

int main(int argc, char** argv) {
	int ret;

	if ((ret = g_pMemoryManager->Initialize()) != 0) {
		printf("Memory Manager Initialize failed, will exit now.");
		return ret;
	}

    g_pApp->SetCommandLineParameters(argc, argv);

	if ((ret = g_pApp->Initialize()) != 0) {
		printf("App Initialize failed, will exit now.");
		return ret;
	}

	if ((ret = g_pAssetLoader->Initialize()) != 0) {
		printf("Asset Loader Initialize failed, will exit now.");
		return ret;
	}

	if ((ret = g_pSceneManager->Initialize()) != 0) {
		printf("Scene Manager Initialize failed, will exit now.");
		return ret;
	}

//     std::string scene_file_name = "Scene/test.ogex";
    std::string scene_file_name = "Scene/aili.ogex";
    if (argc > 1) {
        scene_file_name = argv[1];
    }

    if ((ret = g_pSceneManager->LoadScene(scene_file_name.c_str())) != 0) {
        printf("Unable to load scene: %s\n", scene_file_name.c_str());
        return ret;
    }
	
	if ((ret = g_pGraphicsManager->Initialize()) != 0) {
		printf("Graphics Manager Initialize failed, will exit now.");
		return ret;
	}

	while (!g_pApp->IsQuit()) {
		g_pApp->Tick();
        g_pMemoryManager->Tick();
        g_pAssetLoader->Tick();
        g_pSceneManager->Tick();
        g_pGraphicsManager->Tick();
        std::this_thread::sleep_for(std::chrono::microseconds(10000)); // 100 FPS
	}

    g_pGraphicsManager->Finalize();
    g_pSceneManager->Finalize();
    g_pAssetLoader->Finalize();
    g_pMemoryManager->Finalize();
	g_pApp->Finalize();

	return 0;
}

