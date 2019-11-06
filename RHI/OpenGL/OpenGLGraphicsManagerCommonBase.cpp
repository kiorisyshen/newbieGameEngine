#include <algorithm>
#include <fstream>
#include <functional>
#include <iostream>
#include <sstream>

#include "OpenGLGraphicsManagerCommonBase.hpp"

#include "AssetLoader.hpp"

#if defined(OS_ANDROID) || defined(OS_WEBASSEMBLY)
#include <GLES3/gl32.h>

#include <GLES2/gl2ext.h>

#define GLAD_GL_ARB_compute_shader 0
#else
#include "glad/glad.h"
#endif

#if defined(OS_WEBASSEMBLY)
#define SHADER_ROOT "Shaders/WebGL/"
#elif defined(OS_ANDROID)
#define SHADER_ROOT "Shaders/OpenGLES/"
#else
#define SHADER_ROOT "Shaders/OpenGL/"
#endif

using namespace std;
using namespace newbieGE;

// --------------------------------------------------------------
// Shader management
// --------------------------------------------------------------
#define VS_BASIC_SOURCE_FILE SHADER_ROOT "basic.vert.glsl"
#define PS_BASIC_SOURCE_FILE SHADER_ROOT "basic.frag.glsl"
#define VS_SHADOWMAP_SOURCE_FILE SHADER_ROOT "shadowmap.vert.glsl"
#define PS_SHADOWMAP_SOURCE_FILE SHADER_ROOT "shadowmap.frag.glsl"
#define VS_OMNI_SHADOWMAP_SOURCE_FILE SHADER_ROOT "shadowmap_omni.vert.glsl"
#define PS_OMNI_SHADOWMAP_SOURCE_FILE SHADER_ROOT "shadowmap_omni.frag.glsl"
#define GS_OMNI_SHADOWMAP_SOURCE_FILE SHADER_ROOT "shadowmap_omni.geom.glsl"
#define DEBUG_VS_SHADER_SOURCE_FILE SHADER_ROOT "debug.vert.glsl"
#define DEBUG_PS_SHADER_SOURCE_FILE SHADER_ROOT "debug.frag.glsl"
#define VS_PASSTHROUGH_SOURCE_FILE SHADER_ROOT "passthrough.vert.glsl"
#define PS_TEXTURE_SOURCE_FILE SHADER_ROOT "texture.frag.glsl"
#define PS_TEXTURE_ARRAY_SOURCE_FILE SHADER_ROOT "texturearray.frag.glsl"
#define VS_PASSTHROUGH_CUBEMAP_SOURCE_FILE SHADER_ROOT "passthrough_cube.vert.glsl"
#define PS_CUBEMAP_SOURCE_FILE SHADER_ROOT "cubemap.frag.glsl"
#define PS_CUBEMAP_ARRAY_SOURCE_FILE SHADER_ROOT "cubemaparray.frag.glsl"
#define VS_SKYBOX_SOURCE_FILE SHADER_ROOT "skybox.vert.glsl"
#define PS_SKYBOX_SOURCE_FILE SHADER_ROOT "skybox.frag.glsl"
#define VS_PBR_SOURCE_FILE SHADER_ROOT "pbr.vert.glsl"
#define PS_PBR_SOURCE_FILE SHADER_ROOT "pbr.frag.glsl"
#define CS_PBR_BRDF_SOURCE_FILE SHADER_ROOT "integrateBRDF.comp.glsl"
#define VS_TERRAIN_SOURCE_FILE SHADER_ROOT "terrain.vert.glsl"
#define PS_TERRAIN_SOURCE_FILE SHADER_ROOT "terrain.frag.glsl"
#define TESC_TERRAIN_SOURCE_FILE SHADER_ROOT "terrain.tesc.glsl"
#define TESE_TERRAIN_SOURCE_FILE SHADER_ROOT "terrain.tese.glsl"

typedef vector<pair<GLenum, string>> ShaderSourceList;

static void OutputShaderErrorMessage(unsigned int shaderId, const char *shaderFilename) {
    int logSize, i;
    char *infoLog;
    ofstream fout;

    // Get the size of the string containing the information log for the failed shader compilation message.
    glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logSize);

    // Increment the size by one to handle also the null terminator.
    logSize++;

    // Create a char buffer to hold the info log.
    infoLog = new char[logSize];
    if (!infoLog) {
        return;
    }

    // Now retrieve the info log.
    glGetShaderInfoLog(shaderId, logSize, NULL, infoLog);

    // Open a file to write the error message to.
    fout.open("shader-error.txt");

    // Write out the error message.
    for (i = 0; i < logSize; i++) {
        fout << infoLog[i];
        cerr << infoLog[i];
    }

    // Close the file.
    fout.close();
    cerr << endl;

    // Pop a message up on the screen to notify the user to check the text file for compile errors.
    cerr << "Error compiling shader.  Check shader-error.txt for message." << shaderFilename << endl;

    return;
}

static void OutputLinkerErrorMessage(unsigned int programId) {
    int logSize, i;
    char *infoLog;
    ofstream fout;

    // Get the size of the string containing the information log for the failed shader compilation message.
    glGetProgramiv(programId, GL_INFO_LOG_LENGTH, &logSize);

    // Increment the size by one to handle also the null terminator.
    logSize++;

    // Create a char buffer to hold the info log.
    infoLog = new char[logSize];
    if (!infoLog) {
        return;
    }

    // Now retrieve the info log.
    glGetProgramInfoLog(programId, logSize, NULL, infoLog);

    // Open a file to write the error message to.
    fout.open("linker-error.txt");

    // Write out the error message.
    for (i = 0; i < logSize; i++) {
        fout << infoLog[i];
        cerr << infoLog[i];
    }

    // Close the file.
    fout.close();
    cerr << endl;

    // Pop a message up on the screen to notify the user to check the text file for linker errors.
    cerr << "Error compiling linker.  Check linker-error.txt for message." << endl;
}

static bool LoadShaderFromFile(const char *filename, const GLenum shaderType, GLuint &shader) {
    std::string cbufferShaderBuffer;
    std::string commonShaderBuffer;
    std::string shaderBuffer;
    int status;

    // Load the shader source file into a text buffer.
    shaderBuffer = g_pAssetLoader->SyncOpenAndReadTextFileToString(filename);
    if (shaderBuffer.empty()) {
        return false;
    }

    shaderBuffer = cbufferShaderBuffer + commonShaderBuffer + shaderBuffer;

    // Create a shader object.
    shader = glCreateShader(shaderType);

    // Copy the shader source code strings into the shader objects.
    const char *pStr = shaderBuffer.c_str();
    glShaderSource(shader, 1, &pStr, NULL);

    // Compile the shaders.
    glCompileShader(shader);

    // Check to see if the shader compiled successfully.
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status != 1) {
        // If it did not compile then write the syntax error message out to a text file for review.
        OutputShaderErrorMessage(shader, filename);
        return false;
    }

    return true;
}

static bool LoadShaderProgram(const ShaderSourceList &source, GLuint &shaderProgram) {
    int status;

    // Create a shader program object.
    shaderProgram = glCreateProgram();

    for (auto it = source.cbegin(); it != source.cend(); it++) {
        GLuint shader;
        status = LoadShaderFromFile(it->second.c_str(), it->first, shader);
        if (!status) {
            return false;
        }

        // Attach the shader to the program object.
        glAttachShader(shaderProgram, shader);
        glDeleteShader(shader);
    }

    // Link the shader program.
    glLinkProgram(shaderProgram);

    // Check the status of the link.
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &status);
    if (status != 1) {
        // If it did not link then write the syntax error message out to a text file for review.
        OutputLinkerErrorMessage(shaderProgram);
        return false;
    }

    return true;
}

// --------------------------------------------------------------
// OpenGLGraphicsManagerCommonBase implementation
// --------------------------------------------------------------
void OpenGLGraphicsManagerCommonBase::ResizeCanvas(int32_t width, int32_t height) {
    //Reset View
    glViewport(0, 0, (GLint)width, (GLint)height);
}

void OpenGLGraphicsManagerCommonBase::UseShaderProgram(const DefaultShaderIndex idx) {
    m_CurrentShader = m_ShaderList[(int32_t)idx];

    glUseProgram(m_CurrentShader);
}

int OpenGLGraphicsManagerCommonBase::Initialize() {
    int result;

    result = GraphicsManager::Initialize();

    if (result) {
        return result;
    }

#if 0
    auto opengl_info = {GL_VENDOR, GL_RENDERER, GL_VERSION, GL_EXTENSIONS};
    for (auto name : opengl_info) {
        auto info = glGetString(name);
        printf("OpenGL Info: %s", info);
    }
#endif

    // Set the depth buffer to be entirely cleared to 1.0 values.
    glClearDepthf(1.0f);

    // Enable depth testing.
    glEnable(GL_DEPTH_TEST);

    // Set the polygon winding to front facing for the right handed system.
    glFrontFace(GL_CCW);

    // Enable back face culling.
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    auto config = g_pApp->GetConfiguration();
    glViewport(0, 0, config.screenWidth, config.screenHeight);

    return result;
}

void OpenGLGraphicsManagerCommonBase::getOpenGLTextureFormat(const Image &img, uint32_t &format, uint32_t &internal_format, uint32_t &type) {
    std::cout << "Test: Image bitcount: " << img.bitcount << std::endl;
    if (img.compressed) {
        switch (img.compress_format) {
            case "DXT1"_u32:
                format          = GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
                internal_format = GL_COMPRESSED_RGB_S3TC_DXT1_EXT;
                break;
            case "DXT3"_u32:
                format          = GL_COMPRESSED_RGBA_S3TC_DXT3_EXT;
                internal_format = GL_COMPRESSED_RGBA_S3TC_DXT3_EXT;
                break;
            case "DXT5"_u32:
                format          = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
                internal_format = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT;
                break;
            default:
                assert(0);
        }

        type = GL_UNSIGNED_BYTE;
    } else {
        if (img.bitcount == 8) {
            format          = GL_RED;
            internal_format = GL_R8;
            type            = GL_UNSIGNED_BYTE;
        } else if (img.bitcount == 16) {
            format          = GL_RED;
            internal_format = GL_R16I;
            type            = GL_UNSIGNED_SHORT;
        } else if (img.bitcount == 24) {
            format          = GL_RGB;
            internal_format = GL_RGB8;
            type            = GL_UNSIGNED_BYTE;
        } else if (img.bitcount == 64) {
            format = GL_RGBA;
            if (img.is_float) {
                internal_format = GL_RGBA16F;
                type            = GL_HALF_FLOAT;
            } else {
                internal_format = GL_RGBA16I;
                type            = GL_UNSIGNED_SHORT;
            }
        } else if (img.bitcount == 128) {
            format = GL_RGBA;
            if (img.is_float) {
                internal_format = GL_RGBA32F;
                type            = GL_FLOAT;
            } else {
                internal_format = GL_RGBA;
                type            = GL_UNSIGNED_INT;
            }
        } else {
            format          = GL_RGBA;
            internal_format = GL_RGBA8;
            type            = GL_UNSIGNED_BYTE;
        }
    }
}

bool OpenGLGraphicsManagerCommonBase::InitializeShaders() {
    std::cout << "[OpenGL] " << glGetString(GL_VERSION) << std::endl;
    std::cout << "[Vendor] " << glGetString(GL_VENDOR) << std::endl;
    std::cout << "[Renderer] " << glGetString(GL_RENDERER) << std::endl;
    std::cout << "[GLSL] " << glGetString(GL_SHADING_LANGUAGE_VERSION) << std::endl;
    // std::cout << "[Extensions] " << glGetString(GL_EXTENSIONS) << std::endl;

    GLuint shaderProgram;
    bool result = true;

    // Basic Shader
    ShaderSourceList list = {
        {GL_VERTEX_SHADER, VS_BASIC_SOURCE_FILE},
        {GL_FRAGMENT_SHADER, PS_BASIC_SOURCE_FILE}};

    result = LoadShaderProgram(list, shaderProgram);
    if (!result) {
        return result;
    }

    m_ShaderList[(int32_t)DefaultShaderIndex::BasicShader] = shaderProgram;

    // Terrain shader
    list = {
        {GL_VERTEX_SHADER, VS_TERRAIN_SOURCE_FILE},
        {GL_FRAGMENT_SHADER, PS_TERRAIN_SOURCE_FILE}};

    result = LoadShaderProgram(list, shaderProgram);
    if (!result) {
        return result;
    }

    m_ShaderList[(int32_t)DefaultShaderIndex::TerrainShader] = shaderProgram;

    return result;
}

void OpenGLGraphicsManagerCommonBase::InitializeBuffers(const Scene &scene) {
    for (auto &frame : m_Frames) {
        frame.batchContext.clear();
    }

    uint32_t batch_index = 0;

    // Geometries
    for (const auto &_it : scene.GeometryNodes) {
        const auto &pGeometryNode = _it.second.lock();
        if (!pGeometryNode->Visible() || !pGeometryNode) {
            continue;
        }

        const auto &pGeometry = scene.GetGeometry(pGeometryNode->GetSceneObjectRef());
        assert(pGeometry);
        const auto &pMesh = pGeometry->GetMesh().lock();
        if (!pMesh) continue;

        // Set the number of vertex properties.
        const auto vertexPropertiesCount = pMesh->GetVertexPropertiesCount();

        // Allocate an OpenGL vertex array object.
        uint32_t vao;
        glGenVertexArrays(1, &vao);

        // Bind the vertex array object to store all the buffers and vertex attributes we create here.
        glBindVertexArray(vao);

        uint32_t buffer_id;

        for (uint32_t i = 0; i < vertexPropertiesCount; i++) {
            const SceneObjectVertexArray &v_property_array = pMesh->GetVertexPropertyArray(i);
            const auto v_property_array_data_size          = v_property_array.GetDataSize();
            const auto v_property_array_data               = v_property_array.GetData();

            // Generate an ID for the vertex buffer.
            glGenBuffers(1, &buffer_id);

            // Bind the vertex buffer and load the vertex (position and color) data into the vertex buffer.
            glBindBuffer(GL_ARRAY_BUFFER, buffer_id);
            glBufferData(GL_ARRAY_BUFFER, v_property_array_data_size, v_property_array_data, GL_STATIC_DRAW);

            glEnableVertexAttribArray(i);

            switch (v_property_array.GetDataType()) {
                case VertexDataType::kVertexDataTypeFloat1:
                    glVertexAttribPointer(i, 1, GL_FLOAT, false, 0, 0);
                    break;
                case VertexDataType::kVertexDataTypeFloat2:
                    glVertexAttribPointer(i, 2, GL_FLOAT, false, 0, 0);
                    break;
                case VertexDataType::kVertexDataTypeFloat3:
                    glVertexAttribPointer(i, 3, GL_FLOAT, false, 0, 0);
                    break;
                case VertexDataType::kVertexDataTypeFloat4:
                    glVertexAttribPointer(i, 4, GL_FLOAT, false, 0, 0);
                    break;
#if !defined(OS_ANDROID) && !defined(OS_WEBASSEMBLY)
                case VertexDataType::kVertexDataTypeDouble1:
                    glVertexAttribPointer(i, 1, GL_DOUBLE, false, 0, 0);
                    break;
                case VertexDataType::kVertexDataTypeDouble2:
                    glVertexAttribPointer(i, 2, GL_DOUBLE, false, 0, 0);
                    break;
                case VertexDataType::kVertexDataTypeDouble3:
                    glVertexAttribPointer(i, 3, GL_DOUBLE, false, 0, 0);
                    break;
                case VertexDataType::kVertexDataTypeDouble4:
                    glVertexAttribPointer(i, 4, GL_DOUBLE, false, 0, 0);
                    break;
#endif
                default:
                    assert(0);
            }

            m_Buffers.push_back(buffer_id);
        }

        const auto indexGroupCount = pMesh->GetIndexGroupCount();

        uint32_t mode;
        switch (pMesh->GetPrimitiveType()) {
            case PrimitiveType::kPrimitiveTypePointList:
                mode = GL_POINTS;
                break;
            case PrimitiveType::kPrimitiveTypeLineList:
                mode = GL_LINES;
                break;
            case PrimitiveType::kPrimitiveTypeLineStrip:
                mode = GL_LINE_STRIP;
                break;
            case PrimitiveType::kPrimitiveTypeTriList:
                mode = GL_TRIANGLES;
                break;
            case PrimitiveType::kPrimitiveTypeTriStrip:
                mode = GL_TRIANGLE_STRIP;
                break;
            case PrimitiveType::kPrimitiveTypeTriFan:
                mode = GL_TRIANGLE_FAN;
                break;
            default:
                // ignore
                continue;
        }

        for (uint32_t i = 0; i < indexGroupCount; i++) {
            // Generate an ID for the index buffer.
            glGenBuffers(1, &buffer_id);

            const SceneObjectIndexArray &index_array = pMesh->GetIndexArray(i);
            const auto index_array_size              = index_array.GetDataSize();
            const auto index_array_data              = index_array.GetData();

            // Bind the index buffer and load the index data into it.
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer_id);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_array_size, index_array_data, GL_STATIC_DRAW);

            // Set the number of indices in the index array.
            int32_t indexCount = static_cast<int32_t>(index_array.GetIndexCount());
            uint32_t type;
            switch (index_array.GetIndexType()) {
                case IndexDataType::kIndexDataTypeInt8:
                    type = GL_UNSIGNED_BYTE;
                    break;
                case IndexDataType::kIndexDataTypeInt16:
                    type = GL_UNSIGNED_SHORT;
                    break;
                case IndexDataType::kIndexDataTypeInt32:
                    type = GL_UNSIGNED_INT;
                    break;
                default:
                    // not supported by OpenGL
                    cerr << "Error: Unsupported Index Type " << index_array << endl;
                    cerr << "Mesh: " << *pMesh << endl;
                    cerr << "Geometry: " << *pGeometry << endl;
                    continue;
            }

            m_Buffers.push_back(buffer_id);

            auto dbc = make_shared<OpenGLDrawBatchContext>();

            const auto material_index = index_array.GetMaterialIndex();
            const auto &material_key  = pGeometryNode->GetMaterialRef(material_index);
            const auto material       = scene.GetMaterial(material_key);
            if (material) {
                function<uint32_t(const string, const shared_ptr<Image> &)> upload_texture = [this](const string texture_key, const shared_ptr<Image> &texture) {
                    uint32_t texture_id;
                    auto it = m_Textures.find(texture_key);
                    if (it == m_Textures.end()) {
                        glGenTextures(1, &texture_id);
                        glBindTexture(GL_TEXTURE_2D, texture_id);
                        uint32_t format, internal_format, type;
                        getOpenGLTextureFormat(*texture, format, internal_format, type);
                        if (texture->compressed) {
                            glCompressedTexImage2D(GL_TEXTURE_2D, 0, internal_format, texture->Width, texture->Height,
                                                   0, static_cast<int32_t>(texture->data_size), texture->data);
                        } else {
                            glTexImage2D(GL_TEXTURE_2D, 0, internal_format, texture->Width, texture->Height,
                                         0, format, type, texture->data);
                        }

                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                        glGenerateMipmap(GL_TEXTURE_2D);

                        glBindTexture(GL_TEXTURE_2D, 0);

                        m_Textures[texture_key] = texture_id;
                    } else {
                        texture_id = it->second;
                    }

                    return texture_id;
                };

                // base color / albedo
                const auto &color = material->GetBaseColor();
                if (color.ValueMap) {
                    const auto &texture_key  = color.ValueMap->GetName();
                    const auto &texture      = color.ValueMap->GetTextureImage();
                    uint32_t texture_id      = upload_texture(texture_key, texture);
                    dbc->material.diffuseMap = static_cast<int32_t>(texture_id);
                }

                // normal
                const auto &normal = material->GetNormal();
                if (normal.ValueMap) {
                    const auto &texture_key = normal.ValueMap->GetName();
                    const auto &texture     = normal.ValueMap->GetTextureImage();
                    uint32_t texture_id     = upload_texture(texture_key, texture);
                    dbc->material.normalMap = static_cast<int32_t>(texture_id);
                }

                // metallic
                const auto &metallic = material->GetMetallic();
                if (metallic.ValueMap) {
                    const auto &texture_key   = metallic.ValueMap->GetName();
                    const auto &texture       = metallic.ValueMap->GetTextureImage();
                    uint32_t texture_id       = upload_texture(texture_key, texture);
                    dbc->material.metallicMap = static_cast<int32_t>(texture_id);
                }

                // roughness
                const auto &roughness = material->GetRoughness();
                if (roughness.ValueMap) {
                    const auto &texture_key    = roughness.ValueMap->GetName();
                    const auto &texture        = roughness.ValueMap->GetTextureImage();
                    uint32_t texture_id        = upload_texture(texture_key, texture);
                    dbc->material.roughnessMap = static_cast<int32_t>(texture_id);
                }

                // ao
                const auto &ao = material->GetAO();
                if (ao.ValueMap) {
                    const auto &texture_key = ao.ValueMap->GetName();
                    const auto &texture     = ao.ValueMap->GetTextureImage();
                    uint32_t texture_id     = upload_texture(texture_key, texture);
                    dbc->material.aoMap     = static_cast<int32_t>(texture_id);
                }

                // // height map
                // const auto &heightmap = material->GetHeight();
                // if (heightmap.ValueMap) {
                //     const auto &texture_key = heightmap.ValueMap->GetName();
                //     const auto &texture     = heightmap.ValueMap->GetTextureImage();
                //     uint32_t texture_id     = upload_texture(texture_key, texture);
                //     dbc->material.heightMap = static_cast<int32_t>(texture_id);
                // }
            }

            glBindVertexArray(0);  // reset vertex array to 0

            dbc->batchIndex = batch_index++;
            dbc->vao        = vao;
            dbc->mode       = mode;
            dbc->type       = type;
            dbc->count      = indexCount;
            dbc->node       = pGeometryNode;

            for (int32_t n = 0; n < GfxConfiguration::kMaxInFlightFrameCount; n++) {
                m_Frames[n].batchContext.push_back(dbc);
            }
        }
    }
}

void OpenGLGraphicsManagerCommonBase::InitializeSkyBox(const Scene &scene) {
    // TODO: unimplemented
}

void evenQuadTessellation(const std::array<Vector4f, 4> &controlPts, const uint32_t row, const uint32_t col, std::vector<Vector4f> &outPts) {
    Vector4f colStep = (controlPts[1] - controlPts[0]) / float(col);
    Vector4f rowStep = (controlPts[2] - controlPts[1]) / float(row);

    outPts.push_back(controlPts[0]);

    for (uint32_t k = 1; k <= col; ++k) {
        outPts.push_back(controlPts[0] + colStep * k);
    }

    for (uint32_t k = 1; k <= row; ++k) {
        outPts.push_back(controlPts[1] + rowStep * k);
    }

    for (uint32_t k = 1; k <= col; ++k) {
        outPts.push_back(controlPts[2] - colStep * k);
    }

    for (uint32_t k = 1; k <= row; ++k) {
        outPts.push_back(controlPts[3] - rowStep * k);
    }

    // Draw small triangles
    for (uint32_t i = 1; i <= row; ++i) {
        Vector4f rowStart = controlPts[0] + (i - 1) * rowStep;
        for (uint32_t j = 1; j <= col; ++j) {
            outPts.push_back(rowStart + rowStep + colStep * j);
            if (j != col) {
                outPts.push_back(rowStart + colStep * j);
            }
        }

        if (i != row) {
            for (uint32_t k = col - 1; k > 0; k = k - 1) {
                outPts.push_back(rowStart + rowStep + colStep * k);
            }
            outPts.push_back(rowStart + rowStep);
        }
    }
}

// Using GL_LINE_STRIP way to draw
std::vector<Vector4f> OpenGLGraphicsManagerCommonBase::cpuTerrainQuadTessellation(const std::array<Vector4f, 4> &controlPts, const Matrix4X4f &patchTransM) {
    std::vector<Vector4f> outPts;

    Vector4f centerPt = {0.0, 0.0, 0.0, 0.0};
    for (int i = 0; i < controlPts.size(); ++i) {
        centerPt = centerPt + controlPts[i];
    }
    centerPt = centerPt / 4.0;

    Transform(centerPt, patchTransM);
    Transform(centerPt, m_Frames[m_nFrameIndex].frameContext.worldMatrix);

    float distanceTerrain = Length(centerPt - m_Frames[m_nFrameIndex].frameContext.m_camPos);

    int32_t distLevel = int32_t(250.0 / distanceTerrain);
    if (distLevel > 6) {
        distLevel = 6;
    }

    uint32_t distRate = 1 << distLevel;

    evenQuadTessellation(controlPts, distRate, distRate, outPts);

    return outPts;
}

static const float TERRAIN_PATCH_SIZE  = 32.0;
static const int32_t TERRAIN_PATCH_ROW = 10;  // must be even number
static const int32_t TERRAIN_PATCH_COL = 10;  // must be even number

void OpenGLGraphicsManagerCommonBase::InitializeTerrain(const Scene &scene) {
    m_TerrainPPC.resize(TERRAIN_PATCH_ROW * TERRAIN_PATCH_COL);

    // Generate vertex array buffer
    CalculateCameraMatrix();
    Matrix4X4f toCameraMatrix;
    int32_t tmpCount = 0;
    for (int32_t i = -TERRAIN_PATCH_ROW / 2; i < TERRAIN_PATCH_ROW / 2; i++) {
        for (int32_t j = -TERRAIN_PATCH_COL / 2; j < TERRAIN_PATCH_COL / 2; j++) {
            // Fill PerTerrainPatchConstants
            MatrixTranslation(m_TerrainPPC[tmpCount].patchLocalMatrix, TERRAIN_PATCH_SIZE * i, TERRAIN_PATCH_SIZE * j, 0.0f);

            // Create vao
            uint32_t vao;
            glGenVertexArrays(1, &vao);
            glBindVertexArray(vao);

            uint32_t buffer_id;
            glGenBuffers(1, &buffer_id);

            Vector4f a                         = {0.0, TERRAIN_PATCH_SIZE, 0.0, 1.0};
            Vector4f b                         = {0.0, 0.0, 0.0, 1.0};
            Vector4f c                         = {TERRAIN_PATCH_SIZE, 0.0, 0.0, 1.0};
            Vector4f d                         = {TERRAIN_PATCH_SIZE, TERRAIN_PATCH_SIZE, 0.0, 1.0};
            std::array<Vector4f, 4> controlPts = {a, b, c, d};

            toCameraMatrix                 = m_TerrainPPC[tmpCount].patchLocalMatrix;
            std::vector<Vector4f> vertices = cpuTerrainQuadTessellation(controlPts, toCameraMatrix);
            glBindBuffer(GL_ARRAY_BUFFER, buffer_id);
            glBufferData(GL_ARRAY_BUFFER, sizeof(Vector4f) * vertices.size(), &vertices[0], GL_STATIC_DRAW);
            glEnableVertexAttribArray(0);
            glVertexAttribPointer(0, 4, GL_FLOAT, false, 0, 0);

            m_TerrainBuffers.push_back(buffer_id);

            glBindVertexArray(0);  // reset vertex array to 0

            m_TerrainPPC[tmpCount].vao   = vao;
            m_TerrainPPC[tmpCount].mode  = GL_LINE_STRIP;
            m_TerrainPPC[tmpCount].count = vertices.size();

            ++tmpCount;
        }
    }

    // Generate per-Terrain Patch Constant
    if (!m_uboDrawTerrainPatchConstant[m_nFrameIndex]) {
        glGenBuffers(1, &m_uboDrawTerrainPatchConstant[m_nFrameIndex]);
    }

    uint8_t *pBuff_trans = new uint8_t[kSizePerTerrainConstant * TERRAIN_PATCH_ROW * TERRAIN_PATCH_COL];
    glBindBuffer(GL_UNIFORM_BUFFER, m_uboDrawTerrainPatchConstant[m_nFrameIndex]);
    tmpCount = 0;
    for (int32_t i = -TERRAIN_PATCH_ROW / 2; i < TERRAIN_PATCH_ROW / 2; i++) {
        for (int32_t j = -TERRAIN_PATCH_COL / 2; j < TERRAIN_PATCH_COL / 2; j++) {
            const PerTerrainPatchConstants &constants = static_cast<PerTerrainPatchConstants &>(m_TerrainPPC[tmpCount]);
            memcpy(pBuff_trans + tmpCount * kSizePerTerrainConstant, &constants, kSizePerTerrainConstant);
            ++tmpCount;
        }
    }
    glBufferData(GL_UNIFORM_BUFFER, kSizePerTerrainConstant * TERRAIN_PATCH_ROW * TERRAIN_PATCH_COL, pBuff_trans, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    delete[] pBuff_trans;

    if (scene.Terrain) {
        // Current we use only the first height map
        auto &texture      = scene.Terrain->GetTexture(0);
        const auto &pImage = texture.GetTextureImage();

        // Create terrain height image
        glGenTextures(1, &m_TerrainHeightMap);
        glBindTexture(GL_TEXTURE_2D, m_TerrainHeightMap);
        uint32_t format, internal_format, type;
        getOpenGLTextureFormat(*pImage, format, internal_format, type);
        if (pImage->compressed) {
            glCompressedTexImage2D(GL_TEXTURE_2D, 0, internal_format, pImage->Width, pImage->Height,
                                   0, static_cast<int32_t>(pImage->data_size), pImage->data);
        } else {
            glTexImage2D(GL_TEXTURE_2D, 0, internal_format, pImage->Width, pImage->Height,
                         0, format, type, pImage->data);
        }

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glGenerateMipmap(GL_TEXTURE_2D);

        glBindTexture(GL_TEXTURE_2D, 0);

        for (uint32_t i = 0; i < GfxConfiguration::kMaxInFlightFrameCount; i++) {
            m_Frames[i].frameContext.terrainHeightMap = m_TerrainHeightMap;
        }
    }
}

void OpenGLGraphicsManagerCommonBase::BeginScene(const Scene &scene) {
    GraphicsManager::BeginScene(scene);

    InitializeBuffers(scene);
    InitializeTerrain(scene);
    InitializeSkyBox(scene);

    cout << "[OpenGLGraphicsManagerCommonBase] BeginScene Done!" << endl;
}

void OpenGLGraphicsManagerCommonBase::EndScene() {
    for (int i = 0; i < GfxConfiguration::kMaxInFlightFrameCount; i++) {
        auto &batchContext = m_Frames[i].batchContext;

        for (auto &dbc : batchContext) {
            glDeleteVertexArrays(1, &dynamic_pointer_cast<OpenGLDrawBatchContext>(dbc)->vao);
        }

        batchContext.clear();

        if (m_uboDrawFrameConstant[i]) {
            glDeleteBuffers(1, &m_uboDrawFrameConstant[i]);
        }

        if (m_uboDrawBatchConstant[i]) {
            glDeleteBuffers(1, &m_uboDrawBatchConstant[i]);
        }

        if (m_uboLightInfo[i]) {
            glDeleteBuffers(1, &m_uboLightInfo[i]);
        }

        if (m_uboDrawTerrainPatchConstant[i]) {
            glDeleteBuffers(1, &m_uboDrawTerrainPatchConstant[i]);
        }

        // if (m_uboShadowMatricesConstant[i]) {
        //     glDeleteBuffers(1, &m_uboShadowMatricesConstant[i]);
        // }

        // if (m_uboDebugConstant[i]) {
        //     glDeleteBuffers(1, &m_uboDebugConstant[i]);
        // }
    }

    // if (m_TerrainDrawBatchContext.vao) {
    //     glDeleteVertexArrays(1, &m_TerrainDrawBatchContext.vao);
    // }

    // if (m_SkyBoxDrawBatchContext.vao) {
    //     glDeleteVertexArrays(1, &m_SkyBoxDrawBatchContext.vao);
    // }

    for (auto &buf : m_Buffers) {
        glDeleteBuffers(1, &buf);
    }

    for (auto &it : m_Textures) {
        glDeleteTextures(1, &it.second);
    }

    for (auto &buf : m_TerrainBuffers) {
        glDeleteBuffers(1, &buf);
    }

    glDeleteTextures(1, &m_TerrainHeightMap);

    m_Buffers.clear();
    m_Textures.clear();

    GraphicsManager::EndScene();
}

void OpenGLGraphicsManagerCommonBase::BeginFrame() {
    // reset gl error
    glGetError();

    // Set the color to clear the screen to.
    glClearColor(0.2f, 0.3f, 0.4f, 1.0f);
    // Clear the screen and depth buffer.
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void OpenGLGraphicsManagerCommonBase::EndFrame() {
    glFlush();
}

void OpenGLGraphicsManagerCommonBase::SetPerFrameConstants(const DrawFrameContext &context) {
    if (!m_uboDrawFrameConstant[m_nFrameIndex]) {
        glGenBuffers(1, &m_uboDrawFrameConstant[m_nFrameIndex]);
    }

    glBindBuffer(GL_UNIFORM_BUFFER, m_uboDrawFrameConstant[m_nFrameIndex]);

    PerFrameConstants constants = static_cast<PerFrameConstants>(context);

    glBufferData(GL_UNIFORM_BUFFER, kSizePerFrameConstantBuffer, &constants, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_UNIFORM_BUFFER, 0);
}

void OpenGLGraphicsManagerCommonBase::SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    uint8_t *pBuff = new uint8_t[kSizePerBatchConstantBuffer * batches.size()];

    if (!m_uboDrawBatchConstant[m_nFrameIndex]) {
        glGenBuffers(1, &m_uboDrawBatchConstant[m_nFrameIndex]);
    }

    glBindBuffer(GL_UNIFORM_BUFFER, m_uboDrawBatchConstant[m_nFrameIndex]);

    for (auto &pBatch : batches) {
        const PerBatchConstants &constants = static_cast<PerBatchConstants &>(*pBatch);
        memcpy(pBuff + pBatch->batchIndex * kSizePerBatchConstantBuffer, &constants, kSizePerBatchConstantBuffer);
    }

    glBufferData(GL_UNIFORM_BUFFER, kSizePerBatchConstantBuffer * batches.size(), pBuff, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_UNIFORM_BUFFER, 0);

    delete[] pBuff;
}

struct webGLLightInfo {
    Matrix4X4f lightVP;       // 64 bytes
    Vector4f lightPosition;   // 16 bytes
    Vector4f lightColor;      // 16 bytes
    Vector4f lightDirection;  // 16 bytes
};

void OpenGLGraphicsManagerCommonBase::SetLightInfo(const LightInfo &lightInfo) {
    if (!m_uboLightInfo[m_nFrameIndex]) {
        glGenBuffers(1, &m_uboLightInfo[m_nFrameIndex]);
    }

    glBindBuffer(GL_UNIFORM_BUFFER, m_uboLightInfo[m_nFrameIndex]);

    glBufferData(GL_UNIFORM_BUFFER, sizeof(webGLLightInfo), &lightInfo.lights[0], GL_DYNAMIC_DRAW);

    glBindBuffer(GL_UNIFORM_BUFFER, 0);
}

int32_t OpenGLGraphicsManagerCommonBase::GetTexture(const char *id) {
    int32_t result = 0;

    auto it = m_Textures.find(id);
    if (it != m_Textures.end()) {
        result = it->second;
    }

    return result;
}

void OpenGLGraphicsManagerCommonBase::DrawBatch(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    // Prepare & Bind per frame constant buffer
    uint32_t blockIndex = glGetUniformBlockIndex(m_CurrentShader, "PerFrameConstants");

    if (blockIndex != GL_INVALID_INDEX) {
        glUniformBlockBinding(m_CurrentShader, blockIndex, 10);

        glBindBufferBase(GL_UNIFORM_BUFFER, 10, m_uboDrawFrameConstant[m_nFrameIndex]);
    }

    // Prepare & Bind light info
    blockIndex = glGetUniformBlockIndex(m_CurrentShader, "LightInfo");

    if (blockIndex != GL_INVALID_INDEX) {
        glUniformBlockBinding(m_CurrentShader, blockIndex, 12);
        glBindBufferBase(GL_UNIFORM_BUFFER, 12, m_uboLightInfo[m_nFrameIndex]);
    }

    // Prepare per batch constant buffer binding point
    blockIndex = glGetUniformBlockIndex(m_CurrentShader, "PerBatchConstants");

    if (blockIndex != GL_INVALID_INDEX) {
        glUniformBlockBinding(m_CurrentShader, blockIndex, 11);
    }

    // Bind LUT table
    auto brdf_lut = GetTexture("BRDF_LUT");
    setShaderParameter("SPIRV_Cross_CombinedbrdfLUTsamp0", 6);
    glActiveTexture(GL_TEXTURE6);
    if (brdf_lut > 0) {
        glBindTexture(GL_TEXTURE_2D, brdf_lut);
    } else {
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    glEnable(GL_CULL_FACE);

    for (auto &pDbc : batches) {
        const OpenGLDrawBatchContext &dbc = dynamic_cast<const OpenGLDrawBatchContext &>(*pDbc);

        // Bind per batch constant buffer
        glBindBufferRange(GL_UNIFORM_BUFFER, 11, m_uboDrawBatchConstant[m_nFrameIndex],
                          dbc.batchIndex * kSizePerBatchConstantBuffer, kSizePerBatchConstantBuffer);

        // Bind textures
        setShaderParameter("SPIRV_Cross_CombineddiffuseMapsamp0", 0);
        glActiveTexture(GL_TEXTURE0);
        if (dbc.material.diffuseMap > 0) {
            glBindTexture(GL_TEXTURE_2D, dbc.material.diffuseMap);
        } else {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        setShaderParameter("SPIRV_Cross_CombinednormalMapsamp0", 1);
        glActiveTexture(GL_TEXTURE1);
        if (dbc.material.normalMap > 0) {
            glBindTexture(GL_TEXTURE_2D, dbc.material.normalMap);
        } else {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        setShaderParameter("SPIRV_Cross_CombinedmetallicMapsamp0", 2);
        glActiveTexture(GL_TEXTURE2);
        if (dbc.material.metallicMap > 0) {
            glBindTexture(GL_TEXTURE_2D, dbc.material.metallicMap);
        } else {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        setShaderParameter("SPIRV_Cross_CombinedroughnessMapsamp0", 3);
        glActiveTexture(GL_TEXTURE3);
        if (dbc.material.roughnessMap > 0) {
            glBindTexture(GL_TEXTURE_2D, dbc.material.roughnessMap);
        } else {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        setShaderParameter("SPIRV_Cross_CombinedaoMapsamp0", 4);
        glActiveTexture(GL_TEXTURE4);
        if (dbc.material.aoMap > 0) {
            glBindTexture(GL_TEXTURE_2D, dbc.material.aoMap);
        } else {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        setShaderParameter("SPIRV_Cross_CombinedheightMapsamp0", 5);
        glActiveTexture(GL_TEXTURE5);
        if (dbc.material.heightMap > 0) {
            glBindTexture(GL_TEXTURE_2D, dbc.material.heightMap);
        } else {
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        glBindVertexArray(dbc.vao);

        glDrawElements(dbc.mode, dbc.count, dbc.type, 0x00);
    }

    glBindVertexArray(0);
}

void OpenGLGraphicsManagerCommonBase::DrawBatchPBR(const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    // TODO: unimplemented
}

void OpenGLGraphicsManagerCommonBase::DrawBatchDepthFromLight(const Light &light, const ShadowMapType type, const std::vector<std::shared_ptr<DrawBatchConstant>> &batches) {
    // TODO: unimplemented
}

int32_t OpenGLGraphicsManagerCommonBase::GenerateShadowMapArray(const ShadowMapType type, const uint32_t width, const uint32_t height, const uint32_t count) {
    // TODO: unimplemented
    return -1;
}

void OpenGLGraphicsManagerCommonBase::DestroyShadowMaps() {
    // TODO: unimplemented
}

void OpenGLGraphicsManagerCommonBase::SetShadowMaps(const Frame &frame) {
    // TODO: unimplemented
}

// skybox
void OpenGLGraphicsManagerCommonBase::SetSkyBox(const DrawFrameContext &context) {
    // TODO: unimplemented
}
void OpenGLGraphicsManagerCommonBase::DrawSkyBox() {
    // TODO: unimplemented
}

// terrain
void OpenGLGraphicsManagerCommonBase::SetTerrain(const DrawFrameContext &context) {
    // TODO: unimplemented
}
void OpenGLGraphicsManagerCommonBase::DrawTerrain() {
    // Prepare & Bind per frame constant buffer
    uint32_t blockIndex = glGetUniformBlockIndex(m_CurrentShader, "PerFrameConstants");

    if (blockIndex != GL_INVALID_INDEX) {
        glUniformBlockBinding(m_CurrentShader, blockIndex, 10);

        glBindBufferBase(GL_UNIFORM_BUFFER, 10, m_uboDrawFrameConstant[m_nFrameIndex]);
    }

    // Prepare per batch constant buffer binding point
    blockIndex = glGetUniformBlockIndex(m_CurrentShader, "TerrainPerPatchConstants");

    if (blockIndex != GL_INVALID_INDEX) {
        glUniformBlockBinding(m_CurrentShader, blockIndex, 13);
    }

    glEnable(GL_CULL_FACE);

    setShaderParameter("TerrainHeightMapsamp0", 7);
    glActiveTexture(GL_TEXTURE7);
    if (m_TerrainHeightMap > 0) {
        glBindTexture(GL_TEXTURE_2D, m_TerrainHeightMap);
    } else {
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    int32_t tmpCount = 0;
    for (int32_t i = -TERRAIN_PATCH_ROW / 2; i < TERRAIN_PATCH_ROW / 2; i++) {
        for (int32_t j = -TERRAIN_PATCH_COL / 2; j < TERRAIN_PATCH_COL / 2; j++) {
            // Bind per batch constant buffer
            glBindBufferRange(GL_UNIFORM_BUFFER, 13, m_uboDrawTerrainPatchConstant[m_nFrameIndex],
                              tmpCount * kSizePerTerrainConstant, kSizePerTerrainConstant);

            glBindVertexArray(m_TerrainPPC[tmpCount].vao);
            glDrawArrays(m_TerrainPPC[tmpCount].mode, 0, m_TerrainPPC[tmpCount].count);

            ++tmpCount;
        }
    }

    glBindVertexArray(0);
}

// pbr compute shader
void OpenGLGraphicsManagerCommonBase::Dispatch(const uint32_t width, const uint32_t height, const uint32_t depth) {
    // TODO: unimplemented
}
int32_t OpenGLGraphicsManagerCommonBase::GenerateAndBindTextureForWrite(const char *id, const uint32_t slot_index, const uint32_t width, const uint32_t height) {
    // TODO: unimplemented
    return -1;
}

#ifdef DEBUG
void OpenGLGraphicsManagerCommonBase::DEBUG_ClearDebugBuffers() {
    // TODO: unimplemented
}
void OpenGLGraphicsManagerCommonBase::DEBUG_SetBuffer() {
    // TODO: unimplemented
}
void OpenGLGraphicsManagerCommonBase::DEBUG_DrawDebug() {
    // TODO: unimplemented
}
void OpenGLGraphicsManagerCommonBase::DEBUG_DrawOverlay(const int32_t shadowmap,
                                                        const int32_t layerIndex,
                                                        float vp_left, float vp_top,
                                                        float vp_width, float vp_height) {
    // TODO: unimplemented
}
#endif

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const Matrix4X4f &param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniformMatrix4fv(location, 1, false, param);

    return true;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const Matrix4X4f *param, const int32_t count) {
    bool result = true;
    char uniformName[256];

    for (int32_t i = 0; i < count; i++) {
        sprintf(uniformName, "%s[%d]", paramName, i);
        result &= setShaderParameter(uniformName, *(param + i));
    }

    return result;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const Vector2f &param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniform2fv(location, 1, param);

    return true;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const Vector3f &param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniform3fv(location, 1, param);

    return true;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const Vector4f &param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniform4fv(location, 1, param);

    return true;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const float param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniform1f(location, param);

    return true;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const int32_t param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniform1i(location, param);

    return true;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const uint32_t param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniform1ui(location, param);

    return true;
}

bool OpenGLGraphicsManagerCommonBase::setShaderParameter(const char *paramName, const bool param) {
    unsigned int location;

    location = glGetUniformLocation(m_CurrentShader, paramName);
    if (location == -1) {
        return false;
    }
    glUniform1f(location, param);

    return true;
}