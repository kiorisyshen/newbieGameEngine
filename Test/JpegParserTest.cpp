#include <iostream>
#include <string>
#include "AssetLoader.hpp"
#include "JPEG.hpp"
#include "MemoryManager.hpp"

using namespace std;
using namespace newbieGE;

namespace newbieGE {
IMemoryManager *g_pMemoryManager = new MemoryManager();
AssetLoader *g_pAssetLoader      = new AssetLoader();
}  // namespace newbieGE

int main(int argc, const char **argv) {
    g_pMemoryManager->Initialize();
    g_pAssetLoader->Initialize();

#ifdef __ORBIS__
    g_pAssetLoader->AddSearchPath("/app0");
#endif

    {
        Buffer buf;
        if (argc >= 2) {
            buf = g_pAssetLoader->SyncOpenAndReadBinary(argv[1]);
        } else {
            buf = g_pAssetLoader->SyncOpenAndReadBinary("Textures/huff_simple0.jpg");
        }

        JfifParser jfif_parser;

        Image image = jfif_parser.Parse(buf);

        cout << image;
    }

    g_pAssetLoader->Finalize();
    g_pMemoryManager->Finalize();

    delete g_pAssetLoader;
    delete g_pMemoryManager;

    return 0;
}
