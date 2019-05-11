add_library(Common
    Allocator.cpp
    AssetLoader.cpp
    BaseApplication.cpp
    GraphicsManager.cpp
    Image.cpp
    MemoryManager.cpp
    SceneObject.cpp
    SceneManager.cpp
    main.cpp
)

target_link_libraries(Common GeomMath ${XG_LIBRARY})
