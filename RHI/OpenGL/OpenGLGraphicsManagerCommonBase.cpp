#include <algorithm>
#include <functional>
#include <iostream>
#include <sstream>

#include "OpenGLGraphicsManagerCommonBase.hpp"

#if defined(OS_ANDROID) || defined(OS_WEBASSEMBLY)
#include <GLES3/gl32.h>
#define GLAD_GL_ARB_compute_shader 0
#else
#include "glad/glad.h"
#endif

using namespace std;
using namespace newbieGE;

void OpenGLGraphicsManagerCommonBase::ResizeCanvas(int32_t width, int32_t height) {
    //Reset View
    glViewport(0, 0, (GLint)width, (GLint)height);
}

void OpenGLGraphicsManagerCommonBase::UseShaderProgram(const DefaultShaderIndex idx) {
    m_CurrentShader = m_ShaderList[(int32_t)idx];

    glUseProgram(m_CurrentShader);
}

bool OpenGLGraphicsManagerCommonBase::InitializeShaders() {
    // TODO: unimplemented
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

void OpenGLGraphicsManagerCommonBase::InitializeTerrain(const Scene &scene) {
    // TODO: unimplemented
}

void OpenGLGraphicsManagerCommonBase::BeginScene(const Scene &scene) {
    GraphicsManager::BeginScene(scene);

    InitializeBuffers(scene);
    InitializeTerrain(scene);
    InitializeSkyBox(scene);

    cout << "[OpenGLGraphicsManagerCommonBase] BeginScene Done!" << endl;
}

void EndScene() {
    // TODO: unimplemented
}

void BeginFrame() {
    // reset gl error
    glGetError();

    // Set the color to clear the screen to.
    glClearColor(0.2f, 0.3f, 0.4f, 1.0f);
    // Clear the screen and depth buffer.
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void EndFrame() {
    // Empty
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

void OpenGLGraphicsManagerCommonBase::SetLightInfo(const LightInfo &lightInfo) {
    if (!m_uboLightInfo[m_nFrameIndex]) {
        glGenBuffers(1, &m_uboLightInfo[m_nFrameIndex]);
    }

    glBindBuffer(GL_UNIFORM_BUFFER, m_uboLightInfo[m_nFrameIndex]);

    glBufferData(GL_UNIFORM_BUFFER, kSizeLightInfo, &lightInfo, GL_DYNAMIC_DRAW);

    glBindBuffer(GL_UNIFORM_BUFFER, 0);
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